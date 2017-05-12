package Bot::Cobalt::Plugin::RDB::AsyncSearch;
$Bot::Cobalt::Plugin::RDB::AsyncSearch::VERSION = '0.021003';
use Carp;
use strictures 2;

use Config;

use POE qw/
  Wheel::Run
  Filter::Reference
/;

sub new { bless [], shift }

sub spawn {
  my $self = shift;
  $self = $self->new unless ref $self;
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;
  
  unless ($args{errorevent} && $args{resultevent}) {
    croak "Need an ErrorEvent and ResultEvent in spawn()"
  }

  my $maxworkers = $args{maxworkers} || 5;

  my $sess = POE::Session->create(
    heap => {
      ErrorEvent  => delete $args{errorevent},
      ResultEvent => delete $args{resultevent},
      MaxWorkers  => $maxworkers,
      
      Requests => {},
      Pending  => [],
      
      Wheels => {
        PID => {},
      },
    },

    object_states => [
      $self => [
        '_start',
        '_stop',
        
        'shutdown',

        'search_rdb',
        
        'push_pending',
        
        'reap_all',
        
        'worker_input',
        'worker_stderr',
        'worker_sigchld',
      ],
    ],
  
  );

  return $sess->ID()
}

sub _start {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

  $kernel->refcount_increment( 
    $_[SESSION]->ID(), 'Waiting for requests'
  );
}

sub _stop {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  $kernel->call( $_[SESSION], 'reap_all' );
}

sub shutdown {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL];

  $kernel->call( $_[SESSION], 'reap_all' );

  $kernel->refcount_decrement( 
    $_[SESSION]->ID(), 'Waiting for requests'
  );
}

sub search_rdb {
  ## search_rdb( $dbpath, $regex, $hints_hash )
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($dbpath, $regex, $hints) = @_[ARG0, ARG1, ARG2];

  my $sender = $_[SENDER];
  
  unless ($dbpath && $regex) {
    carp "search_rdb posted but no path or regex specified";
    return
  }
  
  my @p = ( 'a' .. 'z', 1 .. 9 );
  my $unique = join '', map { $p[rand@p] } 1 .. 6;
  $unique .= $p[rand@p] while exists $heap->{Requests}->{$unique};
  
  my $item = {
    Path   => $dbpath,
    Tag    => $unique,
    Regex  => $regex,
    Hints  => $hints,
    SenderID => $sender->ID(),
  };
  
  $heap->{Requests}->{$unique} = $item;
  
  push(@{ $heap->{Pending} }, $item );
  
  $kernel->yield('push_pending');
}

sub push_pending {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  
  return unless @{ $heap->{Pending} };

  my $running = keys %{ $heap->{Wheels}->{PID} };
  if ($running >= $heap->{MaxWorkers} ) {
    $kernel->alarm('push_pending', time + 1);
    return
  }
  
  ## try to spawn a new wheel
  
  my $perlpath = $Config{perlpath};
  if ($^O ne 'VMS') {
    $perlpath .= $Config{_exe}
      unless $perlpath =~ m/$Config{_exe}$/i;
  }

  ## FIXME workers could be genericized to be used with Info3 also . . .
  ## would speed up a dsearch
  
  my $forkable;
  if ($^O eq 'MSWin32') {
    ## May drop Win32 support here entirely . . .
    require Bot::Cobalt::Plugin::RDB::AsyncSearch::Worker;
    $forkable = \&Bot::Cobalt::Plugin::RDB::AsyncSearch::Worker::worker;
  } else {
    $forkable = [
      $perlpath, (map { "-I$_" } @INC),
      '-MBot::Cobalt::Plugin::RDB::AsyncSearch::Worker', '-e',
      'Bot::Cobalt::Plugin::RDB::AsyncSearch::Worker->worker()'
    ];
  }

  my $wheel = POE::Wheel::Run->new(
    Program => $forkable,
    StdioFilter => POE::Filter::Reference->new(),
    ErrorEvent  => 'worker_err',
    StderrEvent => 'worker_stderr',
    StdoutEvent => 'worker_input',
  );

  my $wid = $wheel->ID;
  my $pid = $wheel->PID;
  
  $kernel->sig_child($pid, 'worker_sigchld');
  
  $heap->{Wheels}->{PID}->{$pid} = $wheel;

  my $next_item = shift @{ $heap->{Pending} };
  
  my $tag = $next_item->{Tag};
  $heap->{RequestsByWID}->{$wid} = $tag;
    
  $wheel->put(
    [ $next_item->{Path}, $next_item->{Tag}, $next_item->{Regex} ]
  );
}

sub reap_all {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

  for my $pid (keys %{ $heap->{Wheels}->{PID} }) {
    my $wheel = delete $heap->{Wheels}->{PID}->{$pid};
    if (ref $wheel) {
      $wheel->kill('TERM');
    }
  }
  
  $heap->{Wheels} = { PID => {}, WID => {} };
  $heap->{RequestsByWID} = {};
}

sub worker_input {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($input, $wid) = @_[ARG0, ARG1];
  
  my ($dbpath, $tag, @results) = @$input;
  
  my $request = delete $heap->{Requests}->{$tag};
  
  unless ($request) {
    carp "severe oddness: results from a request tag we don't know";
    return
  }
  
  my $sender_id = $request->{SenderID};
  my $hints     = $request->{Hints};

  ## Returns: resultset as arrayref, original hints hash
  ## (passed in via search)
  my $event = $heap->{ResultEvent};
  $kernel->post( $sender_id, $event, \@results, $hints );
}

sub worker_sigchld {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my $pid = $_[ARG1];
  
  my $wheel = delete $heap->{Wheels}->{PID}->{$pid};

  my $wid = $wheel->ID;

  delete $heap->{RequestsByWID}->{$wid};

  $kernel->yield( 'push_pending' );
}

sub worker_stderr {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my ($input, $wid) = @_[ARG0, ARG1];
  
  my $request_id = $heap->{RequestsByWID}->{$wid};

  my $request    = delete $heap->{Requests}->{$request_id};

  if ($request) {
    my $sender_id = $request->{SenderID};
    my $hints     = $request->{Hints};

    my $event = $heap->{ErrorEvent};

    $kernel->post( $sender_id, $event, $input, $hints );
  } else {
    carp "stderr from non-avail request: $input"
  }

  ## These should sigchld and go away.
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::RDB::AsyncSearch - Asynchronous RDB deep search

=head1 SYNOPSIS

  ## Inside a POE::Session
  my $async_sessID = Bot::Cobalt::Plugin::RDB::AsyncSearch->spawn(
    MaxWorkers => 5,
    ResultEvent => 'got_rdb_result',
    ErrorEvent  => 'got_rdb_error',
  );

  $poe_kernel->post( $async_sessID,
    'search_rdb',
    $rdb_path,
    $regex,
    $hints_hash
  );

=head1 DESCRIPTION

This is a simple POE session for managing fork()/exec()'d
Bot::Cobalt::Plugin::RDB::AsyncSearch::Worker instances via 
L<POE::Wheel::Run>.

It does not interact with the L<Bot::Cobalt> core directly in any way; 
it can be used from any POE session to deep-search RDBs.

Searches should be posted to the B<search_rdb> event (see L</SYNOPSIS>).

Results are returned to the specified B<ResultEvent>; the first argument 
is an array reference of results, the second argument is the $hints_hash 
originally passed in via B<search_rdb>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
