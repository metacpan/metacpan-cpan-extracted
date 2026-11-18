#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Errno;
use File::Temp qw( tempdir );
use IO::Socket::UNIX;
use Time::HiRes qw( time );
use API::Docker;
use API::Docker::Error::Timeout;

# The connect timeout of API::Docker::Role::HTTP (karr k61).
#
# read_timeout (karr k59) bounds reading and nothing else, so a daemon that
# accepts and then says nothing is caught while a socket that never accepts is
# not. connect_timeout is the other half.
#
# Nothing here reaches a Docker daemon and nothing here touches the network:
# the one end-to-end assertion runs against a local Unix listener whose backlog
# has been filled, which is the only way an AF_UNIX connect blocks at all. So
# there is no is_live()/can_write() gating -- it is unconditionally safe with
# no engine installed.

# A client that records what _build__socket was handed instead of connecting,
# so the per-request resolution can be asserted at the seam it has to cross.
package Test::ConnectTimeout::Probe;
use Moo;
extends 'API::Docker';

has seen    => (is => 'ro', required => 1);
has pending => (is => 'ro', default  => sub { [] });

sub _build__socket {
  my ($self) = @_;
  my $pending = $self->_pending_connect;
  push @{ $self->seen },    $pending ? $pending->{timeout} : 'no pending';
  push @{ $self->pending }, $pending;
  die "no socket here\n";
}

package main;

my $client = API::Docker->new(
  host        => 'unix:///nonexistent.sock',
  api_version => '1.41',
);

# ---------------------------------------------------------------------------
subtest 'the attribute is off by default and off when set to 0' => sub {
  is $client->connect_timeout, undef,
    'no default -- every existing caller connects exactly as it always did';

  is $client->_connect_timeout_value(undef), undef, 'undef is off';
  is $client->_connect_timeout_value(0), undef,
    '0 is off too, which is how a client-wide default is turned off for one '
    . 'request';
  is $client->_connect_timeout_value(2.5), 2.5, 'a fraction is kept as one';

  my $set = API::Docker->new(
    host            => 'unix:///nonexistent.sock',
    api_version     => '1.41',
    connect_timeout => 5,
  );
  is $set->connect_timeout, 5, 'and it is a constructor argument';
};

subtest 'a value that is not a number is refused, not rounded' => sub {
  for my $bad ('soon', '', [], {}, -1) {
    eval { $client->_connect_timeout_value($bad) };
    like $@, qr/connect_timeout must be a non-negative number/,
      'refused: ' . (ref $bad || "'$bad'");
  }

  # The message names connect_timeout rather than read_timeout: the two share
  # one check, and a caller who mistyped one must not be told about the other.
  eval { $client->_read_timeout_value('soon') };
  like $@, qr/read_timeout must be a non-negative number/,
    'and the read timeout still names itself';
};

# ---------------------------------------------------------------------------
# What counts as the bound firing, and what does not. This is the whole of the
# discrimination: a refused connection and a missing socket path are diagnoses
# the caller can act on, and reporting them as a timeout would replace one with
# a cause that is not true.
subtest '_connect_expired: only the bound firing counts as a timeout' => sub {
  {
    # IO::Socket's own marker for its select() running out, measured against a
    # host that drops SYNs.
    local $@ = 'IO::Socket::INET: connect: timeout';
    local $! = Errno::ETIMEDOUT();
    ok $client->_connect_expired(2), q{'connect: timeout' is the bound};
    ok !$client->_connect_expired(undef),
      'but not with no connect_timeout in force -- the kernel produces '
      . 'ETIMEDOUT on its own after two minutes';
  }

  {
    # The unix:// shape: IO::Socket does the timed connect non-blocking and an
    # AF_UNIX connect has no in-progress state, so a full backlog comes back
    # at once with EAGAIN instead of blocking.
    local $@ = 'connect: Resource temporarily unavailable';
    local $! = Errno::EAGAIN();
    ok $client->_connect_expired(1), 'EAGAIN with a bound in force is it too';
    ok !$client->_connect_expired(0), 'and 0 is no bound';
  }

  {
    local $@ = 'connect: Connection refused';
    local $! = Errno::ECONNREFUSED();
    ok !$client->_connect_expired(2),
      'a refused connection is not a timeout, bound or no bound';
  }

  {
    local $@ = 'connect: No such file or directory';
    local $! = Errno::ENOENT();
    ok !$client->_connect_expired(2), 'nor is a socket path that is not there';
  }
};

subtest 'a missing socket still croaks the string it always did' => sub {
  my $missing = API::Docker->new(
    host            => 'unix:///nonexistent-api-docker-61.sock',
    api_version     => '1.41',
    connect_timeout => 5,
  );

  eval { $missing->get('/probe') };
  my $err = $@;
  ok !(ref $err && $err->isa('API::Docker::Error::Timeout')),
    'not turned into a timeout by having a connect_timeout set';
  like "$err", qr/Cannot connect to Unix socket/,
    'the diagnosis is the one the caller can act on';
};

# ---------------------------------------------------------------------------
# The one end-to-end assertion. An AF_UNIX connect blocks in exactly one
# situation -- the listener's backlog is full and nobody is accepting --
# measured with Listen => 1 and no accept: still blocked after 8 seconds. So
# the backlog is filled here, and then the bound has something to bound.
subtest 'the real socket: a connect that would block raises the timeout'
  => sub {
  my $dir  = tempdir(CLEANUP => 1);
  my $path = $dir . '/backlog.sock';
  my $srv  = IO::Socket::UNIX->new(Local => $path, Listen => 1)
    or plan skip_all => "cannot listen on a Unix socket here: $!";

  # Filled with the same bounded connect the code under test uses, so this
  # loop cannot be the thing that hangs. Nothing ever accepts on $srv.
  my @held;
  my $full = 0;
  for (1 .. 200) {
    my $c = IO::Socket::UNIX->new(
      Peer => $path, Type => SOCK_STREAM, Timeout => 1);
    unless ($c) {
      $full = ($! == Errno::EAGAIN() || $! == Errno::EWOULDBLOCK()) ? 1 : 0;
      last;
    }
    push @held, $c;
  }
  plan skip_all => 'the listen backlog does not fill the way this platform '
    . 'was measured to' unless $full;

  my $blocked = API::Docker->new(
    host            => 'unix://' . $path,
    api_version     => '1.41',
    connect_timeout => 1,
  );

  # The alarm is the harness's own bound, not the one under test: without the
  # Timeout on the constructor this connect blocks forever, and a test that
  # hangs reports nothing. With it, the alarm never fires.
  my $t0 = time;
  eval {
    local $SIG{ALRM} = sub { die "the connect was never bounded at all\n" };
    alarm 10;
    $blocked->get('/probe');
    alarm 0;
    1;
  };
  my $err = $@;
  alarm 0;
  my $elapsed = time - $t0;

  isa_ok $err, 'API::Docker::Error::Timeout';
  is ref $err && $err->phase, 'connect',
    'the phase says the daemon was never reached';
  is ref $err && $err->timeout, 1, 'and names the bound that expired';
  is ref $err && $err->partial, '',
    'with no partial: there is no response to have part of';
  is ref $err && $err->summary, undef, 'and no summary';
  like "$err", qr{\QGET /v1.41/probe\E},
    'the request is named in the string';
  like "$err", qr/connect timeout/, 'and it says which bound this was';
  cmp_ok $elapsed, '<', 5,
    'it gave up rather than hanging (' . sprintf('%.2fs', $elapsed) . ')';

  # Without the bound this same connect blocks indefinitely, so it is not
  # attempted here -- the assertion above is that the bound is what ended it,
  # and the measurement that it blocks without one is in the POD.

  close $_ for @held;
  close $srv;
};

# ---------------------------------------------------------------------------
subtest 'the per-request option overrides the attribute either way' => sub {
  # What reached _build__socket, read where the constructors read it. Nothing
  # about this can be seen from the outside -- the connect either blocks or it
  # does not -- so the assertion is made at the seam the value has to cross.
  my @seen;
  my $probe = Test::ConnectTimeout::Probe->new(
    host            => 'unix:///nonexistent-api-docker-61.sock',
    api_version     => '1.41',
    connect_timeout => 5,
    seen            => \@seen,
  );

  eval { $probe->get('/probe') };
  eval { $probe->get('/probe', connect_timeout => 2) };
  # Resolved with exists rather than truth, so 0 is "wait as long as it takes"
  # rather than "no opinion", which is how a client-wide default is turned off
  # for one request.
  eval { $probe->get('/probe', connect_timeout => 0) };

  is_deeply \@seen, [5, 2, undef],
    'the attribute, then the option overriding it, then an explicit 0 '
    . 'turning it off';
  is_deeply [ map { $_->{endpoint} } @{ $probe->pending } ],
    [ ('GET /v1.41/probe') x 3 ],
    'and the endpoint travels with it, so the exception can name the request';
};

subtest 'the pending bound does not outlive the request that set it' => sub {
  my $missing = API::Docker->new(
    host            => 'unix:///nonexistent-api-docker-61.sock',
    api_version     => '1.41',
    connect_timeout => 5,
  );

  eval { $missing->get('/probe') };
  is $missing->_pending_connect, undef,
    'cleared even though the connect croaked -- a later socket built by '
    . 'anything but a request must not inherit the last one';
};

subtest 'a read timeout still says it was a read' => sub {
  # The default of the new attribute, asserted where it is cheap: every
  # Error::Timeout raised before this existed described a read.
  my $err = API::Docker::Error::Timeout->new(
    message => 'x', timeout => 2);
  is $err->phase, 'read', 'phase defaults to read';
};

done_testing;
