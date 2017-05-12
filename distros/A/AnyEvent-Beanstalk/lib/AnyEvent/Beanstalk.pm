package AnyEvent::Beanstalk;
$AnyEvent::Beanstalk::VERSION = '1.170590';
use strict;
use warnings;

use constant DEBUG => $ENV{AE_BEANSTALK_DEBUG};
use Scalar::Util qw(blessed);

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::Beanstalk::Job;
use AnyEvent::Beanstalk::Stats;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
  qw< decoder delay encoder on_error on_connect priority server socket ttr >    ##
);

my $YAML_CLASS = do {
  local ($SIG{__DIE__}, $SIG{__WARN__});
      eval { require YAML::XS }   ? 'YAML::XS'
    : eval { require YAML::Syck } ? 'YAML::Syck'
    : eval { require YAML }       ? 'YAML'
    :                               die $@;
};
my $YAML_LOAD = $YAML_CLASS->can('Load');
my $YAML_DUMP = $YAML_CLASS->can('Dump');


sub new {
  my $proto = shift;
  my %arg   = @_;

  bless(
    { delay      => $arg{delay}      || 0,
      ttr        => $arg{ttr}        || 120,
      priority   => $arg{priority}   || 10_000,
      encoder    => $arg{encoder}    || $YAML_DUMP,
      decoder    => $arg{decoder}    || $YAML_LOAD,
      server     => $arg{server}     || undef,
      debug      => $arg{debug}      || 0,
      on_error   => $arg{on_error}   || undef,
      on_connect => $arg{on_connect} || undef,
    },
    ref($proto) || $proto
  );
}


sub run_cmd {
  my $self = shift;

  $self->{_cmd_cb} or return $self->connect(@_);
  $self->{_cmd_cb}->(@_);
}


sub quit { shift->disconnect }
sub reserve_pending { shift->{_reserve_pending} || 0 }


sub disconnect {
  my $self = shift;
  my $condvar = delete $self->{_condvar};
  delete @{$self}{grep {/^_[a-z]/} keys %$self};
  if ($condvar) {
    $_->send for values %$condvar;
  }
  return;
}


sub _error {
  my $self = shift;
  $self->disconnect;
  ($self->on_error || sub { die @_ })->(@_);
}


sub reconnect {
  my $self = shift;

  my $using = $self->{__using} || 'default';
  $self->use(
    $using,
    sub {
      $self->_error("Can't use '$using'") unless @_ and $_[0] eq 'USING';
    }
  );

  my $watching = $self->{__watching} || {default => 1};
  $self->watch_only(
    keys %$watching,
    sub {
      $self->_error("Error watching tubes") unless @_ and $_[0] eq 'WATCHING';
    }
  );
}

my %EXPECT = qw(
  put                  INSERTED
  use                  USING
  reserve              RESERVED
  reserve-with-timeout RESERVED
  delete               DELETED
  release              RELEASED
  bury                 BURIED
  touch                TOUCHED
  watch                WATCHING
  ignore               WATCHING
  peek                 FOUND
  peek-ready           FOUND
  peek-delayed         FOUND
  peek-buried          FOUND
  kick                 KICKED
  kick-job             KICKED
  stats-job            OK
  stats-tube           OK
  stats                OK
  list-tubes           OK
  list-tube-used       USING
  list-tubes-watched   OK
  pause-tube           PAUSED
);

sub connect {
  my $self = shift;

  my $cv;
  if (@_) {
    $cv = AE::cv;
    $self->{_condvar}{$cv} = $cv;
    push @{$self->{_connect_queue}}, [@_, $cv];
  }

  return $cv if $self->{_sock};

  my ($host, $port) = parse_hostport($self->server || '127.0.0.1', 11300);
  $self->{_sock} = tcp_connect $host, $port, sub {
    $self->server("$host\:$port");
    my $fh = shift
      or return $self->_error("Can't connect to beanstalk server: $!");

    $self->{__using} = 'default';
    $self->{__watching} = {default => 1};
    my $on_connect = $self->on_connect;
    $on_connect->() if $on_connect;
    $self->{_socket} = $fh;

    my $hd = AnyEvent::Handle->new(
      fh       => $fh,
      on_error => sub { $_[0]->destroy; $self->_error($_[2]) },
      on_eof   => sub { $_[0]->destroy; $self->_error("EOF") },
    );

    $self->{_cmd_cb} = sub {
      my $command = lc shift;

      my ($cv, $cb);
      {
        no warnings;
        $cv = pop if @_ && blessed($_[-1]) eq 'AnyEvent::CondVar';
        $cb = pop if @_ && ref $_[-1]      eq 'CODE';
      }

      my $value = $command eq 'put' ? pop(@_) . "\015\012" : '';
      my @argv  = @_;
      my $send  = join(" ", $command, @argv) . "\015\012" . $value;

      warn "Sending [$send]\n" if DEBUG;

      $cv ||= AE::cv;
      $self->{_condvar}{$cv} = $cv;
      $cv->cb(
        sub {
          my $cv  = shift;
          my @res = $cv->recv;
          $cb->(@res);
        }
      ) if $cb;

      $self->{_reserve_pending}++ if $command =~ /^reserve/;

      $hd->push_write($send);
      $hd->push_read(
        line => sub {
          my ($hd, $result) = @_;
          warn "got line <$result> for command [$send]\n" if DEBUG;
          my @resp = split(/\s+/, $result);
          my $resp = uc shift @resp;

          $self->{_reserve_pending}-- if $command =~ /^reserve/;

          unless ($resp eq $EXPECT{$command}) {
                delete $self->{_condvar}{$cv};
                $cv->send(undef, $result);
                return;
          }

          if ($resp =~ /^ (?: RESERVED | FOUND ) $/x) {
            my ($id, $bytes) = @resp;
            $hd->unshift_read(
              chunk => $bytes + 2,
              sub {
                my ($hd, $chunk) = @_;
                my $job = AnyEvent::Beanstalk::Job->new(
                  id     => $id,
                  client => $self,
                  data   => substr($chunk, 0, -2),
                );
                delete $self->{_condvar}{$cv};
                $cv->send($job, $result);
              }
            );
          }
          elsif ($resp =~ /^ (?: INSERTED | BURIED ) $/x) {
            my $id  = shift @resp;
            my $job = AnyEvent::Beanstalk::Job->new(
              id     => $id,
              client => $self,
              data   => substr($value, 0, -2),
              buried => $resp eq 'BURIED' ? 1 : 0,
            );
            delete $self->{_condvar}{$cv};
            $cv->send($job, $result);
          }
          elsif ($resp eq 'OK') {
            my $bytes = shift @resp;
            $hd->unshift_read(
              chunk => $bytes + 2,
              sub {
                my ($hd, $chunk) = @_;
                warn "got '$chunk'\n" if DEBUG;
                my $yaml = $YAML_LOAD->($chunk);
                delete $self->{_condvar}{$cv};
                $yaml = AnyEvent::Beanstalk::Stats->new($yaml) if $command =~ /^stats/;
                $cv->send($yaml,$result);
              }
            );
          }
          elsif($resp =~ /^ (?: RELEASED | TOUCHED ) $/x) {
            my ($id, $pri, $delay) = @argv;
            delete $self->{_condvar}{$cv};
            my $job = AnyEvent::Beanstalk::Job->new(
              id     => $id,
              client => $self,
              ( $command eq 'release'
                ? (
                  priority => $pri,
                  delay    => $delay,
                  )
                : ()
              )
            );
            $cv->send($job, $result);
          }
          elsif($resp =~ /^ (?: USING | WATCHING ) $/x) {
            delete $self->{_condvar}{$cv};
            my $retval = shift @resp;
            $cv->send($retval, $result);
          }
          else {
            delete $self->{_condvar}{$cv};
            $cv->send(1, $result);
          }
        }
      );

      return $cv;
    };

    for my $queue (@{$self->{_connect_queue} || []}) {
      $self->{_cmd_cb}->(@$queue);
    }
    delete $self->{_connect_queue};
  };

  return $cv;
}


sub watch_only {
  my $self = shift;
  my $cb   = pop if @_ and ref($_[-1]) eq 'CODE';
  my $cv   = AE::cv;
  $self->{_condvar}{$cv} = $cv;

  $cv->cb(
    sub {
      my $cv  = shift;
      my @res = $cv->recv;
      $cb->(@res);
    }
  ) if $cb;

  unless (@_) {
    delete $self->{_condvar}{$cv};
    $cv->send(undef, 'NOT_IGNORED');
    return $cv;
  }

  my %tubes = map { ($_ => 1) } @_;
  my $done = sub {
    delete $self->{_condvar}{$cv};
    $cv->send(@_);
  };
  $self->list_tubes_watched(
    sub {
      my ($tubes,$r) = @_;
      return $done->(@_) unless $r and $r =~ /^OK\b/;
      my $w = $self->{__watching} = {};
      foreach my $t (@$tubes) {
        $tubes{$t} = 0 unless delete $tubes{$t};
        $w->{$t}++;
      }
      unless (keys %tubes) {    # nothing to do
          my $ts = scalar @$tubes;
          $done->($ts, "WATCHING $ts");
      }
      my @err;    # first error
      foreach my $t (sort { $tubes{$b} <=> $tubes{$a} } keys %tubes) {
        my $cmd = $tubes{$t} ? 'watch' : 'ignore';
        $self->run_cmd(
          $cmd, $t,
          sub {
            if ($_[1] and $_[1] =~ /^WATCHING\b/) {
              $tubes{$t} ? $w->{$t}++ : delete $w->{$t};
            } else {
              @err = @_ unless @err;
            }
            delete $tubes{$t};
            return $done->(@err ? @err : @_)
              unless keys %tubes;
          }
        );
      }
    }
  );

  $cv;
}


sub put {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $opt  = shift || {};

  my $pri   = exists $opt->{priority} ? $opt->{priority} : $self->priority;
  my $ttr   = exists $opt->{ttr}      ? $opt->{ttr}      : $self->ttr;
  my $delay = exists $opt->{delay}    ? $opt->{delay}    : $self->delay;
  my $data =
      exists $opt->{data}   ? $opt->{data}
    : exists $opt->{encode} ? $self->encoder->($opt->{encode})
    :                         '';

  $pri   = int($pri   || 0) || 1;
  $ttr   = int($ttr   || 0) || 1;
  $delay = int($delay || 0) || 0;
  $data = '' unless defined $data;

  utf8::encode($data) if utf8::is_utf8($data);    # need bytes

  $self->run_cmd('put' => $pri, $delay, $ttr, length($data), $data, @cb);
}


sub stats {
  my $self = shift;
  my @cb = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  $self->run_cmd('stats' => @cb);
}


sub stats_tube {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $tube = shift;
  $self->run_cmd('stats-tube' => $tube, @cb);
}


sub stats_job {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $id   = shift || 0;
  $self->run_cmd('stats-job' => $id, @cb);
}


sub kick {
  my $self  = shift;
  my @cb    = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $bound = shift || 1;
  $self->run_cmd('kick' => $bound, @cb);
}


sub kick_job {
  my $self  = shift;
  my @cb    = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $id    = shift || 0;
  $self->run_cmd('kick-job' => $id, @cb);
}

sub use {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $tube = shift;
  $self->run_cmd(
    'use' => $tube,
    sub {
      $self->{__using} = $_[0] if @_ and $_[1] =~ /^USING\b/;
      $cb[0]->(@_) if @cb;
    }
  );
}


sub reserve {
  my $self    = shift;
  my @cb      = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $timeout = shift;

  my @cmd = defined($timeout) ? ('reserve-with-timeout' => $timeout) : "reserve";
  $self->run_cmd(@cmd, @cb);
}


sub delete {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $id   = shift || 0;
  $self->run_cmd('delete' => $id, @cb);
}


sub touch {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $id   = shift || 0;
  $self->run_cmd('touch' => $id, @cb);
}


sub release {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $id   = shift || 0;
  my $opt  = shift || {};

  my $pri   = exists $opt->{priority} ? $opt->{priority} : $self->priority;
  my $delay = exists $opt->{delay}    ? $opt->{delay}    : $self->delay;

  $self->run_cmd('release' => $id, $pri, $delay, @cb);
}


sub bury {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $id   = shift;
  my $opt  = shift || {};

  my $pri = exists $opt->{priority} ? $opt->{priority} : $self->priority;

  $self->run_cmd('bury' => $id, $pri, @cb);
}


sub watch {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $tube = shift;

  $self->run_cmd(
    'watch' => $tube,
    sub {
      $self->{__watching}{$tube} = 1 if @_ and $_[1] =~ /^WATCHING\b/;
      $cb[0]->(@_) if @cb;
    }
  );
}


sub ignore {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $tube = shift;

  $self->run_cmd(
    'ignore' => $tube,
    sub {
      delete $self->{__watching}{$tube} if @_ and $_[1] =~ /^WATCHING\b/;
      $cb[0]->(@_) if @cb;
    }
  );
}


sub peek {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $id   = shift;

  $self->run_cmd('peek' => $id, @cb);
}


sub peek_ready {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $id   = shift;

  $self->run_cmd('peek-ready' => @cb);
}


sub peek_delayed {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $id   = shift;

  $self->run_cmd('peek-delayed' => @cb);
}


sub peek_buried {
  my $self = shift;
  my @cb   = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $id   = shift;

  $self->run_cmd('peek-buried' => @cb);
}


sub list_tubes {
  my $self = shift;
  my @cb = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  $self->run_cmd('list-tubes' => @cb);
}


sub list_tube_used {
  my $self = shift;
  my @cb = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  $self->run_cmd('list-tube-used' => @cb);
}


sub list_tubes_watched {
  my $self = shift;
  my @cb = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  $self->run_cmd('list-tubes-watched' => @cb);
}


sub pause_tube {
  my $self  = shift;
  my @cb    = (@_ and ref($_[-1]) eq 'CODE') ? splice(@_, -1) : ();
  my $tube  = shift;
  my $delay = shift || 0;
  $self->run_cmd('pause-tube' => $tube, $delay, @cb);
}


sub watching {
  my $self = shift;
  return unless $self->{_sock};
  my $watching = $self->{__watching} or return;
  return keys %$watching;
}


sub using {
  my $self = shift;
  return $self->{__using};
}


sub sync {
  my $self = shift;

  while ($self->{_condvar} and my ($cv) = values %{$self->{_condvar}}) {
    $cv->recv;
  }
}

1;
__END__

=encoding utf-8

=head1 NAME

AnyEvent::Beanstalk - Async client to talk to beanstalkd server

=head1 VERSION

version 1.170590

=head1 SYNOPSIS

  use AnyEvent::Beanstalk;

  my $client = AnyEvent::Beanstalk->new(
     server => "localhost",
  );

  # Send a job with explicit data
  my $job = $client->put(
    { data     => "data",
      priority => 100,
      ttr      => 120,
      delay    => 5,
    }
  )->recv;

  # Send job, data created by encoding @args. By default with YAML
  my $job2 = $client->put(
    { priority => 100,
      ttr      => 120,
      delay    => 5,
      encode   => \@args,
    }
  )->recv;

  # Send job, data created by encoding @args with JSON
  use JSON::XS;
  $client->encoder(\&JSON::XS::encode_json);
  my $job2 = $client->put(
    { priority => 100,
      ttr      => 120,
      delay    => 5,
      encode   => \@args,
    },
  )->recv;

  # fetch a job, with a callback
  $client->reserve( sub { my $job = shift; process_job($job) });

=head1 DESCRIPTION

L<AnyEvent::Beanstalk> provides a Perl API of protocol version 1.3 to the beanstalkd server,
a fast, general-purpose, in-memory workqueue service by Keith Rarick.

See the L<beanstalkd 1.3 protocol spec|http://github.com/kr/beanstalkd/blob/v1.3/doc/protocol.txt?raw=true>
for greater detail

=head1 METHODS

=head2 Constructor

=over

=item B<new (%options)>

Any of the attributes with accessor methods described below may be passed to the constructor as key-value pairs

=back

=head2 Attribute Accessor Methods

=over

=item B<server ([$hostname])>

Get/set the hostname, and port, to connect to. The port, which defaults to 11300, can be
specified by appending it to the hostname with a C<:> (eg C<"localhost:1234">).
(Default: C<localhost:11300>)

=item B<delay ([$delay])>

Set/get a default value, in seconds, for job delay. A job with a delay will be
placed into a delayed state and will not be placed into the ready queue until
the time period has passed.  This value will be used by C<put> and C<release> as
a default. (Default: 0)

=item B<ttr ([$ttr])>

Set/get a default value, in seconds, for job ttr (time to run). This value will
be used by C<put> as a default. (Default: 120)

=item B<priority ([$priority])>

Set/get a default value for job priority. The highest priority job is the job
where the priority value is the lowest (ie jobs with a lower priority value are
run first). This value will be used by C<put>, C<release> and C<bury> as a
default. (Default: 10000)

=item B<encoder ([$encoder])>

Set/get serialization encoder. C<$encoder> is a reference to a subroutine
that will be called when arguments to C<put> need to be encoded to send
to the beanstalkd server. The subroutine should accept a single argument and
return a string representation to pass to the server. The default is to encode
the argument using YAML

=item B<decoder ([$decoder])>

Set/get the serialization decoder. C<$decoder> is a reference to a
subroutine that will be called when data from the beanstalkd server needs to be
decoded. The subroutine will be passed the data fetched from the beanstalkd
server and should return the value the application can use. The default is
to decode using YAML.

=item B<debug ([$debug])>

Set/get debug value. If set to a true value then all communication with the server will be
output with C<warn>

=item B<on_error ([$callback])>

A code reference to call when there is an error communicating with the server, for example
an enexpected EOF. A description will be passed as an argument. The default is to call
die

=item B<on_connect ([$callback])>

A code reference to call when the TCP connection has been established with the server

=back

=head2 Communication Methods

All methods that communicate with the server take an optional code reference as the last
argument and return a L<condition variable|AnyEvent/"CONDITION_VARIABLES">.

The condition variable C<recv> method will return 2 values. The first is specific to
the command that is being performed and is referred to below as the response value.
The second value returned by C<recv> is the first line of the protocol response.

If there is a protocol error the response value will be C<undef>.

If a callback is specified then the callback will be called with the same arguments
that the C<recv> method would return.

Calling C<recv> in a scalar context will only return the first of the two values.

If there is a communication error, then all condition variables will be triggered
with no values.

=head2 Producer Methods

These methods are used by clients that are placing work into the queue

=over

=item B<put ($options, [$callback])>

Insert job into the currently used tube.

The response value for a C<put> is a L<AnyEvent::Beanstalk::Job> object.

Options may be

=over

=item priority

priority to use to queue the job.
Jobs with smaller priority values will be
scheduled before jobs with larger priorities. The most urgent priority is 0

Defaults to the current value of the L<priority|/priority> attribute

=item delay

An integer number of seconds to wait before putting the job in
the ready queue. The job will be in the "delayed" state during this time

Defaults to the current value of the L<delay|/delay> attribute

=item ttr

"time to run" - An integer number of seconds to allow a worker
to run this job. This time is counted from the moment a worker reserves
this job. If the worker does not delete, release, or bury the job within
C<ttr> seconds, the job will time out and the server will release the job.
The minimum ttr is 1. If the client sends 0, the server will silently
increase the ttr to 1.

Defaults to the current value of the L<ttr|/ttr> attribute

=item data

The job body. If not specified, the value of the C<encode> option is used

=item encode

Value to encode and pass as job body, if C<data> option is not passed.

Defaults to the empty string.

=back

=item B<use ($tube, [$callback])>

Change tube that new jobs are inserted into

The response value for C<use> is a true value.

=back

=head2 Worker Methods

=over

=item B<reserve ([$timeout], [$callback])>

Reserve a job from the list of tubes currently being watched.

Returns a L<AnyEvent::Beanstalk::Job> on success. C<$timeout> is the maximum number
of seconds to wait for a job to become ready. If C<$timeout> is not given then the client
will wait indefinitely.

The response value for C<reserve> is a L<AnyEvent::Beanstalk::Job> object.

=item B<delete ($id, [$callback])>

Delete the specified job.

The response value will be true.

=item B<release ($id, [$options], [$callback])>

Release the specified job.

The response value for C<release> is a L<AnyEvent::Beanstalk::Job> object.

Valid options are

=over

=item priority

New priority to assign to the job

=item delay

An integer number of seconds to wait before putting the job in
the ready queue. The job will be in the "delayed" state during this time

=back

=item B<bury ($id, [$options], [$callback])>

The bury command puts a job into the "buried" state. Buried jobs are put into a
FIFO linked list and will not be touched by the server again until a client
kicks them with the "kick" command.

The response value for C<bury> is a L<AnyEvent::Beanstalk::Job> object.

Valid options are

=over

=item priority

New priority to assign to the job

=back

=item B<touch ($id, [$callback])>

Calling C<touch> with the id of a reserved job will reset the time left for the job to complete
back to the original ttr value.

The response value for C<touch> is a true value.

=item B<watch ($tube, [$callback])>

Specifies a tube to add to the watch
list. If the tube doesn't exist, it will be created

The response value for C<watch> is the number of tubes being watched

=item B<ignore ($tube, [$callback])>

Stop watching C<$tube>

The response value for C<ignore> is the number of tubes being watched

=item B<watch_only (@tubes, [$callback])>

C<watch_only> will submit a C<list_tubes_watching> command then submit C<watch> and C<ignore>
command to make the list match.

The response value for C<watch_only> is the number of tubes being watched

=back

=head2 Other Communication Methods

=over

=item B<peek ($id, [$callback])>

Peek at the job id specified.

The response value for C<peek> is a L<AnyEvent::Beanstalk::Job> object.

=item B<peek_ready ([$callback])>

Peek at the first job that is in the ready queue of the tube currently
being used.

The response value for C<peek_ready> is a L<AnyEvent::Beanstalk::Job> object.

=item B<peek_delayed ([$callback])>

Peek at the first job that is in the delayed queue of the tubes currently
being used.

The response value for C<peek_delayed> is a L<AnyEvent::Beanstalk::Job> object.

=item B<peek_buried ([$callback])>

Peek at the first job that is in the buried queue of the tube currently
being used.

The response value for C<peek_buried> is a L<AnyEvent::Beanstalk::Job> object.

=item B<kick ($bound, [$callback])>

The kick command applies only to the currently used tube. It moves jobs into
the ready queue. If there are any buried jobs, it will only kick buried jobs.
Otherwise it will kick delayed jobs. The server will not kick more than C<$bound>
jobs.

The response value is the number of jobs kicked

=item B<kick_job ($id, [$callback])>

Kick the specified job C<$id>.

=item B<stats_job ($id, [$callback])>

Return stats for the specified job C<$id>.

The response value for C<stats_job> is a L<AnyEvent::Beanstalk::Stats> object with
the following methods.

=over

=item *

B<id> -
The job id

=item *

B<tube> -
The name of the tube that contains this job

=item *

B<state> -
is "ready" or "delayed" or "reserved" or "buried"

=item *

B<pri> -
The priority value set by the put, release, or bury commands.

=item *

B<age> -
The time in seconds since the put command that created this job.

=item *

B<time_left> -
The number of seconds left until the server puts this job
into the ready queue. This number is only meaningful if the job is
reserved or delayed. If the job is reserved and this amount of time
elapses before its state changes, it is considered to have timed out.

=item *

B<reserves> -
The number of times this job has been reserved

=item *

B<timeouts> -
The number of times this job has timed out during a reservation.

=item *

B<releases> -
The number of times a client has released this job from a reservation.

=item *

B<buries> -
The number of times this job has been buried.

=item *

B<kicks> -
The number of times this job has been kicked.

=back

=item B<stats_tube ($tube, [$callback])>

Return stats for the specified tube C<$tube>.

The response value for C<stats_tube> is a L<AnyEvent::Beanstalk::Stats> object with
the following methods.

=over

=item *

B<name> -
The tube's name.

=item *

B<current_jobs_urgent> -
The number of ready jobs with priority < 1024 in
this tube.

=item *

B<current_jobs_ready> -
The number of jobs in the ready queue in this tube.

=item *

B<current_jobs_reserved> -
The number of jobs reserved by all clients in
this tube.

=item *

B<current_jobs_delayed> -
The number of delayed jobs in this tube.

=item *

B<current_jobs_buried> -
The number of buried jobs in this tube.

=item *

B<total_jobs> -
The cumulative count of jobs created in this tube.

=item *

B<current_waiting> -
The number of open connections that have issued a
reserve command while watching this tube but not yet received a response.

=item *

B<pause> -
The number of seconds the tube has been paused for.

=item *

B<cmd_pause_tube> -
The cumulative number of pause-tube commands for this tube.

=item *

B<pause_time_left> -
The number of seconds until the tube is un-paused.

=back


=item B<stats ([$callback])>

The response value for C<stats> is a L<AnyEvent::Beanstalk::Stats> object with
the following methods.

=over


=item *

B<current_jobs_urgent> -
The number of ready jobs with priority < 1024.

=item *

B<current_jobs_ready> -
The number of jobs in the ready queue.

=item *

B<current_jobs_reserved> -
The number of jobs reserved by all clients.

=item *

B<current_jobs_delayed> -
The number of delayed jobs.

=item *

B<current_jobs_buried> -
The number of buried jobs.

=item *

B<cmd_put> -
The cumulative number of put commands.

=item *

B<cmd_peek> -
The cumulative number of peek commands.

=item *

B<cmd_peek_ready> -
The cumulative number of peek-ready commands.

=item *

B<cmd_peek_delayed> -
The cumulative number of peek-delayed commands.

=item *

B<cmd_peek_buried> -
The cumulative number of peek-buried commands.

=item *

B<cmd_reserve> -
The cumulative number of reserve commands.

=item *

B<cmd_use> -
The cumulative number of use commands.

=item *

B<cmd_watch> -
The cumulative number of watch commands.

=item *

B<cmd_ignore> -
The cumulative number of ignore commands.

=item *

B<cmd_delete> -
The cumulative number of delete commands.

=item *

B<cmd_release> -
The cumulative number of release commands.

=item *

B<cmd_bury> -
The cumulative number of bury commands.

=item *

B<cmd_kick> -
The cumulative number of kick commands.

=item *

B<cmd_stats> -
The cumulative number of stats commands.

=item *

B<cmd_stats_job> -
The cumulative number of stats-job commands.

=item *

B<cmd_stats_tube> -
The cumulative number of stats-tube commands.

=item *

B<cmd_list_tubes> -
The cumulative number of list-tubes commands.

=item *

B<cmd_list_tube_used> -
The cumulative number of list-tube-used commands.

=item *

B<cmd_list_tubes_watched> -
The cumulative number of list-tubes-watched
commands.

=item *

B<cmd_pause_tube> -
The cumulative number of pause-tube commands

=item *

B<job_timeouts> -
The cumulative count of times a job has timed out.

=item *

B<total_jobs> -
The cumulative count of jobs created.

=item *

B<max_job_size> -
The maximum number of bytes in a job.

=item *

B<current_tubes> -
The number of currently-existing tubes.

=item *

B<current_connections> -
The number of currently open connections.

=item *

B<current_producers> -
The number of open connections that have each
issued at least one put command.

=item *

B<current_workers> -
The number of open connections that have each issued
at least one reserve command.

=item *

B<current_waiting> -
The number of open connections that have issued a
reserve command but not yet received a response.

=item *

B<total_connections> -
The cumulative count of connections.

=item *

B<pid> -
The process id of the server.

=item *

B<version> -
The version string of the server.

=item *

B<rusage_utime> -
The accumulated user CPU time of this process in seconds
and microseconds.

=item *

B<rusage_stime> -
The accumulated system CPU time of this process in
seconds and microseconds.

=item *

B<uptime> -
The number of seconds since this server started running.

=item *

B<binlog_oldest_index> -
The index of the oldest binlog file needed to
store the current jobs

=item *

B<binlog_current_index> -
The index of the current binlog file being
written to. If binlog is not active this value will be 0

=item *

B<binlog_max_size> -
The maximum size in bytes a binlog file is allowed
to get before a new binlog file is opened

=back

=item B<list_tubes ([$callback])>

The response value for C<list_tubes> is a reference to an array of the tubes that
the server currently has defined.

=item B<list_tube_used ([$callback])>

The response value for C<list_tube_used> is the name of the tune currently being used.

THis is the tube whichC<put> would place new jobs and the tube which
will be examined by the various peek commands.

=item B<list_tubes_watched ([$callback])>

The response value for C<list_tubes_watched> is a reference to an array of the tubes that
this connection is currently watching

These are the tubes that C<reserve> will check to find jobs. On error an empty list, or undef in
a scalar context, will be returned.

=item B<pause_tube ($tube, $delay, [$callback])>

Pause from reserving any jobs in C<$tube> for C<$delay> seconds.

The response value for C<pause_tube> is a true value.

=item B<connect>

Initiate a connection to the server. Once the connection is established, then
C<on_connect> handler will be called.

=item B<reconnect>

Will connect to the server then attempt to restore the tube used and the list of
tubes watched. If it is unable to restore the state, the connection will be
disconnected and the C<on_error> handler will be called

=item B<sync>

Process all pending commands. Will return when there are no pending commands

=item B<reserve_pending>

Returns the number of reserve commands that have been sent and not answered yet.

=item B<disconnect>

Disconnect from server. If there are any outstanding commands then the condition variable for
each command will be sent the empty list.

=item B<quit>

Same as C<disconnect>

=back

=head1 TODO

More tests

=head1 ACKNOWLEDGEMENTS

Large parts of this documention were lifted from the documention that comes with
beanstalkd

=head1 SEE ALSO

L<Beanstalk::Client>, L<AnyEvent>

=over

=item http://kr.github.com/beanstalkd/

=item L<beanstalkd 1.3 protocol spec|http://github.com/kr/beanstalkd/blob/v1.3/doc/protocol.txt?raw=true>


=back

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 CREDITS

=over

=item Tatsuhiko Miyagawa

Much of the structure of the code in this module was based on L<AnyEvent::Redis>

=item Keith Rarick

Author of beanstalkd

=back

=head1 COPYRIGHT

Copyright (C) 2010 by Graham Barr.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
