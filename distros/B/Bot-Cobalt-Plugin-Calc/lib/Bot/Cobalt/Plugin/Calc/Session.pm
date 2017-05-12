package Bot::Cobalt::Plugin::Calc::Session;
$Bot::Cobalt::Plugin::Calc::Session::VERSION = '0.004005';
use v5.10;

use Config;

use Carp;
use strictures 2;

use Time::HiRes ();

use POE 'Wheel::Run', 'Filter::Reference';

sub TIMEOUT      () { 0 }
sub SESSID       () { 1 }
sub WHEELS       () { 2 }
sub REQUESTS     () { 3 }
sub TAG_BY_WID   () { 4 }
sub PENDING      () { 5 }
sub MAX_WORKERS  () { 6 }
sub RESULT_EVENT () { 7 }
sub ERROR_EVENT  () { 8 }

sub new {
  my ($class, %params) = @_;

  # note the Worker proc also has a RLIMIT_CPU in place (where supported):
  my $timeout = $params{timeout}     || 2;
  my $maxwrk  = $params{max_workers} || 4;

  my $result_event = $params{result_event} || 'calc_result';
  my $error_event  = $params{error_event}  || 'calc_error';
  
  bless [
    $timeout,       # TIMEOUT
    undef,          # SESSID
    +{},            # WHEELS
    +{},            # REQUESTS
    +{},            # TAG_BY_WID
    [],             # PENDING
    $maxwrk,        # MAX_WORKERS
    $result_event,  # RESULT_EVENT
    $error_event,   # ERROR_EVENT
  ], $class
}

sub session_id { shift->[SESSID] }

sub _wheels     { shift->[WHEELS] }
sub _tag_by_wid { shift->[TAG_BY_WID] }
sub _requests   { shift->[REQUESTS] }

sub start {
  my $self = shift;

  my $sess = POE::Session->create(
    object_states => [
      $self => +{
        _start    => 'px_start',
        shutdown  => 'px_shutdown',
        cleanup   => 'px_cleanup',

        calc      => 'px_calc',
        push      => 'px_push',
        
        worker_timeout  => 'px_worker_timeout',
        worker_input    => 'px_worker_input',
        worker_stderr   => 'px_worker_stderr',
        worker_sigchld  => 'px_worker_sigchld',
        worker_closed   => 'px_worker_closed',
      },
    ],
  );

  $self->[SESSID] = $sess->ID;

  $self
}


sub px_start {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->refcount_increment( $_[SESSION]->ID, 'Waiting for requests' );
}

sub px_shutdown {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->call( $_[SESSION], 'cleanup' );
  $kernel->refcount_decrement( $_[SESSION]->ID, 'Waiting for requests' );
}

sub px_cleanup {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  for my $pid (keys %{ $self->[WHEELS] }) {
    if (my $wheel = delete $self->[WHEELS]->{$pid}) {
      $wheel->kill('TERM')
    }
  }
  $self->[TAG_BY_WID] = +{};
  $self->[PENDING]    = [];
}

sub px_calc {
  # calc => $expr, $hints
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my ($expr, $hints)  = @_[ARG0, ARG1];
  my $sender_id = $_[SENDER]->ID;

  unless (defined $expr) {
    warn "'calc' event expected an EXPR and optional hints scalar";
    $kernel->post( $sender_id => $self->[ERROR_EVENT] =>
      "EXPR not defined",
      $hints // +{}
    );
  }

  state $p = [ 'a' .. 'z', 1 .. 9 ];
  my $tag = join '', map {; $p->[rand @$p] } 1 .. 3;
  $tag .= $p->[rand @$p] while exists $self->[REQUESTS]->{$tag};

  my $pending = +{
    expr      => $expr,
    tag       => $tag,
    hints     => ($hints // +{}),
    sender_id => $sender_id,
  };

  $self->[REQUESTS]->{$tag} = $pending;
  push @{ $self->[PENDING] }, $pending;
  $kernel->yield('push');
}

sub px_push {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  return unless @{ $self->[PENDING] };

  if (keys %{ $self->[WHEELS] } >= $self->[MAX_WORKERS]) {
    $kernel->delay( push => 0.5 );
    return
  }

  my $wheel = $self->_create_wheel;

  my $next  = shift @{ $self->[PENDING] };
  my $tag = $next->{tag};
  $self->[TAG_BY_WID]->{ $wheel->ID } = $tag;

  $kernel->delay( worker_timeout => $self->[TIMEOUT], $wheel );
  $wheel->put( [ $next->{tag}, $next->{expr} ] );
}

sub _create_wheel {
  my ($self) = @_;
  
  my $ppath = $Config{perlpath};
  if ($^O ne 'VMS') {
    $ppath .= $Config{_exe} unless $ppath =~ m/$Config{_exe}$/i;
  }
  
  my $forkable;
  if ($^O eq 'MSWin32') {
    require Bot::Cobalt::Plugin::Calc::Worker;
    $forkable = \&Bot::Cobalt::Plugin::Calc::Worker::worker
  } else {
    $forkable = [
      $ppath,
      (map {; '-I'.$_ } @INC),
      '-MBot::Cobalt::Plugin::Calc::Worker',
      '-e',
      'Bot::Cobalt::Plugin::Calc::Worker->worker'
    ]
  }

  my $wheel = POE::Wheel::Run->new(
    Program     => $forkable,
    StdioFilter => POE::Filter::Reference->new,
    StderrEvent => 'worker_stderr',
    StdoutEvent => 'worker_input',
    CloseEvent  => 'worker_closed',
  );

  my $pid = $wheel->PID;
  $poe_kernel->sig_child($pid, 'worker_sigchld');
  $self->[WHEELS]->{$pid} = $wheel;

  $wheel
}

sub px_worker_timeout {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my $wheel = $_[ARG0];
  $wheel->kill('INT');
}

sub px_worker_input {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  
  my ($input, $wid) = @_[ARG0, ARG1];
  my ($tag, $result) = @$input;
  
  my $req = delete $self->[REQUESTS]->{$tag};
  unless ($req) {
    warn "BUG? worker input but no request found for tag '$tag'";
    return
  }
  
  $kernel->post( $req->{sender_id} => $self->[RESULT_EVENT] =>
    $result, $req->{hints} 
  )
}

sub px_worker_stderr {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my ($input, $wid) = @_[ARG0, ARG1];
  my $tag = $self->[TAG_BY_WID]->{$wid};
  unless (defined $tag) {
    warn 
      "BUG? px_worker_stderr but no tag for wheel ID '$wid': '$input'";
  }
  my $req = delete $self->[REQUESTS]->{$tag};
  if (defined $req) {
    my $sender_id = $req->{sender_id};
    my $hints     = $req->{hints};
    $kernel->post( $req->{sender_id} => $self->[ERROR_EVENT] =>
      "worker '$wid': $input", $hints
    )
  } else {
    warn "stderr from worker but request unavailable: '$input'"
  }
}

sub px_worker_closed {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my $wid = $_[ARG0];
  delete $self->[TAG_BY_WID]->{$wid};
}

sub px_worker_sigchld {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my $pid = $_[ARG1];
  my $wheel = delete $self->[WHEELS]->{$pid} || return;
  delete $self->[TAG_BY_WID]->{ $wheel->ID };
  $kernel->yield('push')
}


1;
