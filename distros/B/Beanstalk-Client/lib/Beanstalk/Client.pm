package Beanstalk::Client;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use YAML::Syck;
use Socket;
use IO::Socket::INET;

use Beanstalk::Job;
use Beanstalk::Stats;

our $VERSION = "1.07";

# use namespace::clean;

our $CRLF = "\015\012";
our $MSG_NOSIGNAL = eval { Socket::MSG_NOSIGNAL() } || 0;

BEGIN {
  __PACKAGE__->mk_accessors(
    qw(
      connect_timeout
      debug
      decoder
      default_tube
      delay
      encoder
      error
      priority
      server
      socket
      ttr
      _watching
      _using
      )
  );
}

# no namespace::clean;

sub _interact {
  my ($self, $cmd, $data) = @_;
  my $sock = $self->socket || $self->connect
    or return;

  local $SIG{PIPE} = "IGNORE" unless $MSG_NOSIGNAL;

  my $debug = $self->debug;
  warn $cmd ."\n" if $debug;

  $cmd .= $CRLF;
  $cmd .= $data . $CRLF if defined $data;

  my $offset = 0;
WRITE: {
    my $sent = send($sock, substr($cmd, $offset), $MSG_NOSIGNAL);
    if ($sent) {
      $offset += $sent;
      redo WRITE if $offset < length($cmd);
    }
    else {
      $self->error("$!");
      redo WRITE if $!{EINTR} and fileno($sock);
      return $self->disconnect;
    }
  }

  my $buffer;
  $offset = 0;
READ: {
    my $read = sysread($sock, $buffer, 1024, $offset);
    if ($read) {
      if ($buffer =~ /^([^\015\012]+)\015\012/) {
        $self->{_recv_buffer} = substr($buffer, 2 + length($1));
        warn $1,"\n" if $debug;
        return split(' ', $1);
      }
      $offset += length $buffer;
      redo READ;
    }
    else {
      $self->error("$!");
      redo READ if $!{EINTR} and fileno($sock);
    }
  }
  $self->disconnect;
  return;
}


sub _recv_data {
  my ($self, $bytes) = @_;
  my $sock = $self->socket;

  my $need   = $bytes + 2;                      # count CRLF
  my $offset = length($self->{_recv_buffer});
  my $more   = $need - $offset;

READ: while ($more > 0) {
    my $read = sysread($sock, $self->{_recv_buffer}, $more, $offset);
    if ($read) {
      $offset += $read;
      $more -= $read;
      last if $more == 0;
      redo READ;
    }
    else {
      redo READ if $!{EINTR};
      $self->error("$!");
      return $self->disconnect;
    }
  }
  warn substr($self->{_recv_buffer}, 0, $bytes),"\n" if $self->debug;
  return substr($self->{_recv_buffer}, 0, $bytes);
}


sub _interact_yaml_resp {
  my ($self, $cmd) = @_;

  my @resp = _interact($self, $cmd)
    or return;

  if ($resp[0] eq 'OK') {
    my $data = _recv_data($self, $resp[1])
      or return undef;
    return YAML::Syck::Load($data);
  }

  $self->error(join ' ', @resp);
  return undef;
}


sub _interact_stats {
  my $ret = _interact_yaml_resp(@_)
    or return undef;
  return Beanstalk::Stats->new($ret);
}


sub _peek {
  my $self = shift;
  my $cmd  = shift;

  my @resp = _interact($self, $cmd)
    or return undef;

  if ($resp[0] eq 'FOUND') {
    my $data = _recv_data($self, $resp[2]);
    return undef unless defined $data;
    return Beanstalk::Job->new(
      { id     => $resp[1],
        client => $self,
        data   => $data,
      }
    );
  }

  $self->error(join ' ', @resp);
  return undef;
}

sub __watching {
  my $self = shift;
  my $watching = $self->_watching;
  return $watching if $watching;
  $self->list_tubes_watched;
  $self->_watching;
}

# use namespace::clean;

sub new {
  my $proto  = shift;
  my $fields = shift || {};
  my $self   = $proto->SUPER::new(
    { delay    => 0,
      ttr      => 120,
      priority => 10_000,
      encoder  => \&YAML::Syck::Dump,
      decoder  => \&YAML::Syck::Load,
      %$fields,
    }
  );
  $self->{_recv_buffer} = '';
  $self;
}


sub connect {
  my $self   = shift;
  my $server = $self->server || "127.0.0.1";

  $server .= ":11300" unless $server =~ /:/;

  my $timeout = $self->connect_timeout;

  my $sock = IO::Socket::INET->new(
    PeerAddr => $server,
    Timeout  => $timeout,
  );

  unless ($sock) {
    $self->error("connect: $@");
    return $self->disconnect;
  }

  $self->socket($sock);

  my $was_watching = $self->_watching;
  my $was_using = $self->_using;

  $self->list_tubes_watched;
  if ($was_watching) {
    $self->watch_only(keys %$was_watching)
      or return $self->disconnect;
  }
  elsif (my $default_tube = $self->default_tube) {
    $self->use($default_tube) && $self->watch_only($default_tube)
      or return $self->disconnect;
  }

  if (defined $was_using) {
    $self->use($was_using)
      or return $self->disconnect;
  }

  $sock;
}


sub disconnect {
  my $self = shift;
  if (my $sock = $self->socket) {
    close($sock);
  }
  $self->socket(undef);
}

sub quit {
  shift->disconnect;
  return 1;
}


sub put {
  my $self = shift;
  my $opt  = shift || {};

  my $pri   = exists $opt->{priority} ? $opt->{priority} : $self->priority;
  my $ttr   = exists $opt->{ttr}      ? $opt->{ttr}      : $self->ttr;
  my $delay = exists $opt->{delay}    ? $opt->{delay}    : $self->delay;
  my $data  = exists $opt->{data}     ? $opt->{data}     : $self->encoder->(@_);

  utf8::encode($data) if utf8::is_utf8($data);    # need bytes

  my $bytes = length($data);

  my @resp = _interact($self, "put $pri $delay $ttr $bytes", $data)
    or return undef;

  if ($resp[0] =~ /( INSERTED | BURIED )/x) {
    return Beanstalk::Job->new(
      { id     => $resp[1],
        client => $self,
        buried => $1 eq 'BURIED' ? 1 : 0,
        data   => $data,
      }
    );
  }

  $self->error(join ' ', @resp);

  return undef;
}


sub stats {
  my $self = shift;
  _interact_stats($self, "stats");
}


sub stats_tube {
  my $self = shift;
  my $tube = @_ ? shift: 'default';
  _interact_stats($self, "stats-tube $tube");
}


sub stats_job {
  my $self = shift;
  my $id = shift || 0;
  _interact_stats($self, "stats-job $id");
}


sub kick {
  my $self  = shift;
  my $bound = shift || 1;

  my @resp = _interact($self, "kick $bound")
    or return undef;

  return $resp[1] if $resp[0] eq 'KICKED';

  $self->error(join ' ', @resp);
  return undef;
}


sub kick_job {
  my $self  = shift;
  my $job   = shift;

  my @resp = _interact($self, "kick-job $job")
    or return undef;

  return 1 if $resp[0] eq 'KICKED';

  $self->error(join ' ', @resp);
  return undef;
}


sub use {
  my $self = shift;
  my $tube = shift;

  my @resp = _interact($self, "use $tube")
    or return undef;

  return $self->_using($resp[1]) if $resp[0] eq 'USING';

  $self->error(join ' ', @resp);
  return undef;
}


sub reserve {
  my $self    = shift;
  my $timeout = shift;

  my $cmd     = defined($timeout) ? "reserve-with-timeout $timeout" : "reserve";
  my @resp    = _interact($self, $cmd)
    or return undef;

  if ($resp[0] eq 'RESERVED') {
    my $data = _recv_data($self, $resp[2]);
    return undef unless defined $data;

    return Beanstalk::Job->new(
      { id       => $resp[1],
        client   => $self,
        reserved => 1,
        data     => $data,
      }
    );
  }

  $self->error(join ' ', @resp);
  return undef;
}


sub delete {
  my $self = shift;
  my $id   = shift;
  my @resp = _interact($self, "delete $id")
    or return undef;
  return 1 if $resp[0] eq 'DELETED';

  $self->error(join ' ', @resp);
  return undef;
}

sub touch {
  my $self = shift;
  my $id   = shift;
  my @resp = _interact($self, "touch $id")
    or return undef;
  return 1 if $resp[0] eq 'TOUCHED';

  $self->error(join ' ', @resp);
  return undef;
}


sub release {
  my $self = shift;
  my $id   = shift;
  my $opt  = shift || {};

  my $pri   = exists $opt->{priority} ? $opt->{priority} : $self->priority;
  my $delay = exists $opt->{delay}    ? $opt->{delay}    : $self->delay;

  my @resp = _interact($self, "release $id $pri $delay")
    or return undef;
  return 1 if $resp[0] eq 'RELEASED';

  $self->error(join ' ', @resp);
  return undef;
}


sub bury {
  my $self = shift;
  my $id   = shift;
  my $opt  = shift || {};

  my $pri = exists $opt->{priority} ? $opt->{priority} : $self->priority;

  my @resp = _interact($self, "bury $id $pri")
    or return undef;
  return 1 if $resp[0] eq 'BURIED';

  $self->error(join ' ', @resp);
  return undef;
}


sub watch {
  my $self = shift;
  my $tube = shift;

  my $watching = $self->__watching or return undef;
  return scalar keys %$watching if $watching->{$tube};

  my @resp = _interact($self, "watch $tube")
    or return undef;

  if ($resp[0] eq 'WATCHING') {
    $watching->{$tube}++;
    return $resp[1];
  }

  $self->error(join ' ', @resp);
  return undef;
}


sub ignore {
  my $self = shift;
  my $tube = shift;

  my $watching = $self->__watching or return undef;
  return scalar keys %$watching unless $watching->{$tube};

  my @resp = _interact($self, "ignore $tube")
    or return undef;

  if ($resp[0] eq 'WATCHING') {
    delete $watching->{$tube};
    return $resp[1];
  }

  $self->error(join ' ', @resp);
  return undef;
}


sub watch_only {
  my $self = shift;
  my $watching = $self->__watching or return undef;
  my %watched = %$watching;
  my $ret;
  foreach my $watch (@_) {
    next if delete $watched{$watch};
    $ret = $self->watch($watch) or return undef;
  }
  foreach my $ignore (keys %watched) {
    $ret = $self->ignore($ignore) or return undef;
  }
  return $ret || scalar keys %$watching;
}


sub peek         { _peek($_[0], "peek $_[1]") }
sub peek_ready   { _peek(shift, "peek-ready") }
sub peek_delayed { _peek(shift, "peek-delayed") }
sub peek_buried  { _peek(shift, "peek-buried") }


sub list_tubes {
  my $self = shift;
  my $ret = _interact_yaml_resp($self, "list-tubes")
    or return undef;
  return @$ret;
}


sub list_tube_used {
  my $self = shift;
  my @resp = _interact($self, "list-tube-used")
    or return undef;
  return $resp[1] if $resp[0] eq 'USING';

  $self->error(join ' ', @resp);
  return undef;
}


sub list_tubes_watched {
  my $self = shift;
  my $ret = _interact_yaml_resp($self, "list-tubes-watched")
    or return;
  $self->_watching( { map { ($_,1) } @$ret });
  @$ret;
}


sub pause_tube {
  my $self = shift;
  my $tube = shift;
  my $delay= shift || 0;
  my @resp = _interact($self, "pause-tube $tube $delay")
    or return undef;
  return 1 if $resp[0] eq 'PAUSED';

  $self->error(join ' ', @resp);
  return undef;
}

1;

__END__

=encoding utf-8

=head1 NAME

Beanstalk::Client - Client class to talk to beanstalkd server

=head1 SYNOPSIS

  use Beanstalk::Client;

  my $client = Beanstalk::Client->new(
    { server       => "localhost",
      default_tube => 'mine',
    }
  );

  # Send a job with explicit data
  my $job = $client->put(
    { data     => "data",
      priority => 100,
      ttr      => 120,
      delay    => 5,
    }
  );

  # Send job, data created by encoding @args. By default with YAML
  my $job2 = $client->put(
    { priority => 100,
      ttr      => 120,
      delay    => 5,
    },
    @args
  );

  # Send job, data created by encoding @args with JSON
  use JSON::XS;
  $client->encoder(sub { encode_json(\@_) });
  my $job2 = $client->put(
    { priority => 100,
      ttr      => 120,
      delay    => 5,
    },
    @args
  );

  # fetch a job
  my $job3 = $client->reserve;

=head1 DESCRIPTION

L<Beanstalk::Client> provides a Perl API of protocol version 1.0 to the beanstalkd server,
a fast, general-purpose, in-memory workqueue service by Keith Rarick.

=head1 METHODS

=head2 Constructor

=over

=item B<new ($options)>

The constructor accepts a single argument, which is a reference to a hash containing options.
The options can be any of the accessor methods listed below.

=back

=head2 Accessor Methods

=over

=item B<server ([$hostname])>

Get/set the hostname, and port, to connect to. The port, which defaults to 11300, can be
specified by appending it to the hostname with a C<:> (eg C<"localhost:1234">).
(Default: C<localhost:11300>)

=item B<socket>

Get the socket connection to the server.

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
to the beanstalkd server. The subroutine should accept a list of arguments and
return a string representation to pass to the server. (Default: YAML::Syck::Dump)

=item B<decoder ([$decoder])>

Set/get the serialization decoder. C<$decoder> is a reference to a
subroutine that will be called when data from the beanstalkd server needs to be
decoded. The subroutine will be passed the data fetched from the beanstalkd
server and should return a list of values the application can use.
(Default: YAML::Syck::Load)

=item B<error>

Fetch the last error that happened.

=item B<connect_timeout ([$timeout])>

Get/set timeout, in seconds, to use for the connect to the server.

=item B<default_tube ([$tube])>

Set/get the name of a default tube to put jobs into and fetch from.

By default a connection to a beanstalkd server will put into the C<default>
queue and also watch the C<default> queue. If C<default_tube> is set when
C<connect> is called the connection will be initialized so that C<put> will put
into the given tube and C<reserve> will fetch jobs from the given tube.
(Default: none)

=item B<debug ([$debug])>

Set/get debug value. If set to a true value then all communication with the server will be
output with C<warn>

=back

=head2 Producer Methods

These methods are used by clients that are placing work into the queue

=over

=item B<put ($options [, @args])>

Insert job into the currently used tube. Options may be

=over

=item priority

priority to use to queue the job.
Jobs with smaller priority values will be
scheduled before jobs with larger priorities. The most urgent priority is 0

Defaults to C<$self->priority>

=item delay

An integer number of seconds to wait before putting the job in
   the ready queue. The job will be in the "delayed" state during this time

Defaults to C<$self->delay>

=item ttr

"time to run" - An integer number of seconds to allow a worker
to run this job. This time is counted from the moment a worker reserves
this job. If the worker does not delete, release, or bury the job within
C<ttr> seconds, the job will time out and the server will release the job.
The minimum ttr is 1. If the client sends 0, the server will silently
increase the ttr to 1.

=item data

The job body. Defaults to the result of calling the current encoder passing C<@args>

=back

=item B<use ($tube)>

Change tube that new jobs are inserted into

=back

=head2 Worker Methods

=over

=item B<reserve ([$timeout])>

Reserve a job from the list of tubes currently being watched.

Returns a L<Beanstalk::Job> on success. C<$timeout> is the maximum number
of seconds to wait for a job to become ready. If C<$timeout> is not given then the client
will wait indefinitely.

Returns undef on error or if C<$timeout> expires.

=item B<delete ($id)>

Delete the specified job.

=item B<release ($id, [, $options])>

Release the specified job. Valid options are

=over

=item priority

New priority to assign to the job

=item delay

An integer number of seconds to wait before putting the job in
the ready queue. The job will be in the "delayed" state during this time

=back

=item B<bury ($id [, $options])>

The bury command puts a job into the "buried" state. Buried jobs are put into a
FIFO linked list and will not be touched by the server again until a client
kicks them with the "kick" command.

Valid options are

=over

=item priority

New priority to assign to the job

=back

=item B<touch ($id)>

Calling C<touch> with the id of a reserved job will reset the time left for the job to complete
back to the original ttr value.

=item B<watch ($tube)>

Specifies a tube to add to the watch
list. If the tube doesn't exist, it will be created

=item B<ignore ($tube)>

Stop watching C<$tube>

=item B<watch_only (@tubes)>

Watch only the list of given tube names

=back

=head2 Other Methods

=over

=item B<connect>

Connect to server. If sucessful, set the tube to use and tube to watch if
a C<default_tube> was specified.

=item B<disconnect>

Disconnect from server. C<socket> method will return undef.

=item B<quit>

Disconnect from server. C<socket> method will return undef.

=item B<peek ($id)>

Peek at the job id specified. If the job exists returns a L<Beanstalk::Job> object. Returns
C<undef> on error or if job does not exist.

=item B<peek_ready>

Peek at the first job that is in the ready queue. If there is a job in the
ready queue returns a L<Beanstalk::Job> object. Returns C<undef>
on error or if there are no ready jobs.

=item B<peek_delayed>

Peek at the first job that is in the delayed queue. If there is a job in the
delayed queue returns a L<Beanstalk::Job> object. Returns C<undef>
on error or if there are no delayed jobs.

=item B<peek_buried>

Peek at the first job that is in the buried queue. If there is a job in the
buried queue returns a L<Beanstalk::Job> object. Returns C<undef>
on error or if there are no buried jobs.

=item B<kick ($bound)>

The kick command applies only to the currently used tube. It moves jobs into
the ready queue. If there are any buried jobs, it will only kick buried jobs.
Otherwise it will kick delayed jobs. The server will not kick more than C<$bound>
jobs. Returns the number of jobs kicked, or undef if there was an error.

=item B<kick_job ($id)>

The kick-job command is a variant of kick that operats with a single job
identified by its job id. If the given job id exists and is in a buried or
delayed state, it will be moved to the ready queue of the same tube where it
currently belongs. Returns C<undef> on error.

Note: the kick_job command was only introduced on version 1.8 of beanstalk. If you
have a version of beanstalk prior to this then the command will return an error.

=item B<stats_job ($id)>

Return stats for the specified job C<$id>. Returns C<undef> on error.

If the job exists, the return will be a Stats object with the following methods

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

=over

=back

=item B<stats_tube ($tube)>

Return stats for the specified tube C<$tube>. Returns C<undef> on error.

If the tube exists, the return will be a Stats object with the following methods

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


=item B<stats>

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

=item B<list_tubes>

Returns a list of tubes

=item B<list_tube_used>

Returns the current tube being used. This is the tube which C<put> will place jobs.

=item B<list_tubes_watched>

Returns a list of tubes being watched, or the number of tubes being watched in a scalar context.
These are the tubes that C<reserve> will check to find jobs. On error an empty list, or undef in
a scalar context, will be returned.

=item B<pause_tube ($tube, $delay)>

Pause from reserving any jobs in C<$tube> for C<$delay> seconds.

Returns true on success and C<undef> on error.

=back

=head1 TODO

More tests

=head1 ACKNOWLEDGEMTS

Large parts of this documention were lifted from the documention that comes with
beanstalkd

=head1 SEE ALSO

http://kr.github.com/beanstalkd/

L<Beanstalk::Pool>, L<Beanstalk::Job>, L<Beanstalk::Stats>

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 CREDITS

=over

=item * Ask Bjørn Hansen

=item * Rhesa Rozendaal

=item * Ian Docherty

=back

=head1 BUGS

The Git repository is available at http://github.com/gbarr/perl-beanstalk-client

Please report any bugs or feature requests to the issue tracker at http://github.com/gbarr/perl-beanstalk-client/issues

=head1 COPYRIGHT

Copyright (C) 2008-2012 by Graham Barr.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

