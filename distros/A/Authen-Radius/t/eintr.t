use strict;
use warnings;

use Test::More tests => 14 + 1;
use Test::MockModule;
use Test::NoWarnings;

use English qw($OS_ERROR $OSNAME);
use POSIX qw();
use Time::HiRes qw(time);

BEGIN { use_ok('Authen::Radius') };

# Verify recv_packet treats EINTR (signal interruption of select()) as a
# retryable event with the remaining timeout budget rather than mapping it
# to ETIMEOUT.

# --- Mocked EINTR: must retry, not bail out as ETIMEOUT immediately -----
{
    my $r = Authen::Radius->new(
        Host    => '127.0.0.1',
        Secret  => 'x',
        TimeOut => 5,
    );
    ok($r, 'object created (EINTR mock test)');

    # Dummy state so recv_packet does not blow up before reaching select.
    $r->{authenticator} = "\0" x 16;
    $r->{attributes}    = '';

    my $calls   = 0;
    my @timeouts_seen;
    my $eintr_v = POSIX::EINTR();
    my $mock    = Test::MockModule->new('IO::Select');
    $mock->mock(can_read => sub {
        my (undef, $timeout) = @_;
        $calls++;
        push @timeouts_seen, $timeout;
        if ($calls == 1) {
            # "signal interrupted me": empty list with $OS_ERROR = EINTR.
            $OS_ERROR = $eintr_v;
            return ();
        }
        # Subsequent call: plain timeout (no signal).
        $OS_ERROR = 0;
        return ();
    });

    my $res = $r->recv_packet();

    is($res, undef, 'recv_packet returns undef when no reply arrives');
    is($r->get_error, 'ETIMEOUT', 'real timeout still maps to ETIMEOUT');
    cmp_ok($calls, '>=', 2,
        "can_read retried after EINTR (got $calls call(s))");
    cmp_ok($timeouts_seen[1], '>', 0,
        'retry after EINTR still has positive remaining budget');
    cmp_ok($timeouts_seen[1], '<', $timeouts_seen[0],
        'retry uses *remaining* budget, not a fresh full TimeOut');
}

# --- Live signal: SIGALRM mid-recv must not collapse the timeout --------
SKIP: {
    skip 'Time::HiRes::alarm not implemented on MSWin32', 4
        if $OSNAME eq 'MSWin32';

    my $r = Authen::Radius->new(
        Host    => '127.0.0.1',
        Secret  => 'x',
        TimeOut => 0.6,
    );
    ok($r, 'object created (live-signal test)');
    $r->{authenticator} = "\0" x 16;
    $r->{attributes}    = '';

    local $SIG{ALRM} = sub { 1 };       # no-op handler so the signal does not kill us
    Time::HiRes::alarm(0.1);            # fire mid-recv_packet

    my $start = time();
    my $res   = $r->recv_packet();
    my $elapsed = time() - $start;
    Time::HiRes::alarm(0);              # cancel any leftover alarm

    is($res, undef, 'recv_packet returns undef when no reply arrives');
    is($r->get_error, 'ETIMEOUT', 'eventual outcome is ETIMEOUT');
    cmp_ok($elapsed, '>=', 0.5,
        sprintf('full timeout honoured despite SIGALRM at 0.1s (%.3fs)', $elapsed));
}

# --- Real timeout (no traffic, no signal) is still ETIMEOUT --------------
{
    my $r = Authen::Radius->new(
        Host    => '127.0.0.1',
        Secret  => 'x',
        TimeOut => 0.3,
    );
    ok($r, 'object created (plain-timeout test)');
    $r->{authenticator} = "\0" x 16;
    $r->{attributes}    = '';

    my $start = time();
    my $res   = $r->recv_packet();
    my $elapsed = time() - $start;

    is($res, undef, 'plain timeout: recv_packet returns undef');
    is($r->get_error, 'ETIMEOUT', 'plain timeout: ETIMEOUT');
}
