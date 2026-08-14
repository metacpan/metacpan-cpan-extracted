use strict;
use warnings;

# Ticket #164. Foundation::Runner used `$exit_code = $? >> 8` directly,
# which is 0 for any child that died from a signal. `$? & 127` was
# never inspected. An agent killed by the OOM-killer, an external
# SIGTERM, or SIGSEGV was booked as a clean exit-0 run -- no
# last_error, no cooldown backoff, last_exit: 0, and the next cron
# tick re-launched at full rate. Exactly the failure mode the cooldown
# exists for was the one that never triggered it.
#
# The fix is _classify_exit in Foundation/Runner.pm: read both halves
# of $?, surface a signal death as 128 + signum (the shell convention),
# fall through to the high-bits path otherwise. The timeout path's exit
# code (143, 128+SIGTERM) already used this convention; #164 pins the
# classifier for every signal, including the ones we don't fire
# ourselves.
#
# Tests below cover the classifier directly (cheap) and one end-to-end
# shape: an agent exec'd into a wrapper that execs sleep, killed
# externally with SIGKILL (standing in for the OOM-killer -- no
# special setup required), and the runner reports 128+SIGKILL = 137.

use Test::More;
use POSIX qw( WNOHANG SIGTERM SIGKILL SIGSEGV SIGINT );
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

use App::karr::Foundation;
use App::karr::Foundation::Runner;

# -----------------------------------------------------------------------
# Unit: _classify_exit
# -----------------------------------------------------------------------

# waitpid(2) encodes the child's exit as `$?`: for a normal exit, the high
# 8 bits are the exit code (low 8 are 0); for a signal death, the low 7
# bits are the signal number (high bits are 0). The runner reads `$?`
# directly, so the unit test feeds it the same encoding.

sub _status_from_exit {
    my ($code) = @_;
    return ($code & 0xff) << 8;
}

sub _status_from_signal {
    my ($sig) = @_;
    return $sig & 0x7f;
}

subtest 'classify_exit: a clean exit code passes through unchanged' => sub {
    my $runner = App::karr::Foundation::Runner->new(
        foundation => App::karr::Foundation->new( _config_data => {} ),
    );
    is $runner->_classify_exit( _status_from_exit(0) ),   0,   'exit 0';
    is $runner->_classify_exit( _status_from_exit(7) ),   7,   'exit 7';
    is $runner->_classify_exit( _status_from_exit(255) ), 255, 'exit 255';
    is $runner->_classify_exit( undef ), 0,  'undef treated as no-status';
};

subtest 'classify_exit: a signal death becomes 128 + signum' => sub {
    my $runner = App::karr::Foundation::Runner->new(
        foundation => App::karr::Foundation->new( _config_data => {} ),
    );

    is $runner->_classify_exit( _status_from_signal(SIGTERM) ), 128 + SIGTERM,
        'SIGTERM => 143';
    is $runner->_classify_exit( _status_from_signal(SIGKILL) ), 128 + SIGKILL,
        'SIGKILL => 137 (the OOM-killer case)';
    is $runner->_classify_exit( _status_from_signal(SIGSEGV) ), 128 + SIGSEGV,
        'SIGSEGV => 139';
    is $runner->_classify_exit( _status_from_signal(SIGINT)  ), 128 + SIGINT,
        'SIGINT  => 130';
};

# -----------------------------------------------------------------------
# Integration: an agent killed externally
# -----------------------------------------------------------------------

# To kill the runner's agent (not some other fork in the test process)
# we wrap the agent in a tiny Perl wrapper that records its own pid and
# then execs into /bin/sleep. The runner's fork of this wrapper sees
# stdout as a child pid, the wrapper writes the pid to a file the test
# polls, and the test sends SIGKILL to that pid.

sub write_agent_wrapper {
    my ( $scratch, $real_command ) = @_;
    my $wrapper = $scratch->child('agent-wrapper.pl');
    $wrapper->spew_utf8(<<PERL);
use strict;
use warnings;
use Path::Tiny qw(path);
my \$scratch = path("$scratch");
\$scratch->child('agent.pid')->spew_utf8("\$\$\n");
exec '$real_command';
PERL
    return $wrapper;
}

# Same as write_agent_wrapper, but installs a SIGTERM handler in the wrapper
# that ignores the signal. Used by the SIGTERM-then-SIGKILL test, where the
# wrapper's job is to make sure the eventual kill is SIGKILL (the OOM-killer
# shape, which the runner is expected to surface as 137, not 143).
sub write_signal_ignoring_wrapper {
    my ( $scratch, $real_command ) = @_;
    my $wrapper = $scratch->child('agent-wrapper.pl');
    $wrapper->spew_utf8(<<PERL);
use strict;
use warnings;
use Path::Tiny qw(path);
my \$scratch = path("$scratch");
\$scratch->child('agent.pid')->spew_utf8("\$\$\n");
\$SIG{'TERM'} = 'IGNORE';
exec '$real_command';
PERL
    return $wrapper;
}

sub write_driver {
    my ( $scratch, $wrapper_path ) = @_;
    my $lib = path('lib')->absolute->stringify;
    my $driver = $scratch->child('driver.pl');
    $driver->spew_utf8(<<PERL);
use strict;
use warnings;
use lib '$lib';
use App::karr::Foundation;
use Path::Tiny qw(path);

my \$scratch = path("$scratch");
my \$repo    = \$scratch->child('repo');

my \$f = App::karr::Foundation->new( _config_data => {} );
\$f->_run_command(\$repo, { max_runtime => 30 }, 'exec $^X $wrapper_path');
exit 0;
PERL
    return $driver;
}

sub reap_wait {
    my ( $pid, $max ) = @_;
    $max //= 10;
    my $end = time + $max;
    while ( time < $end ) {
        my $w = waitpid( $pid, WNOHANG );
        return $w if $w > 0 || $w < 0;
        select undef, undef, undef, 0.05;
    }
    diag "driver $pid did not exit within ${max}s; killing";
    kill 'KILL', $pid;
    waitpid( $pid, 0 );
    return -1;
}

sub wait_for_pid_file {
    my ( $pid_file, $timeout ) = @_;
    my $pid;
    my $end = time + $timeout;
    while ( time < $end && !$pid ) {
        if ( -e $pid_file ) {
            my $content = $pid_file->slurp_utf8;
            chomp $content;
            $pid = $content if $content =~ /^\d+$/;
        }
        select undef, undef, undef, 0.05;
    }
    return $pid;
}

subtest 'agent killed by SIGKILL is reported as 128+SIGKILL, not exit 0' => sub {
    my $scratch = path( tempdir( CLEANUP => 1 ) );
    my $repo    = $scratch->child('repo');
    $repo->mkpath;
    $repo->child('.karr.log')->touch;
    my $pid_file = $scratch->child('agent.pid');

    my $wrapper = write_agent_wrapper( $scratch, '/bin/sleep 20' );
    my $driver  = write_driver( $scratch, $wrapper );

    my $dpid = fork;
    die "fork: $!" unless defined $dpid;
    if ( $dpid == 0 ) {
        exec( $^X, "$driver" ) or die;
    }

    my $agent_pid = wait_for_pid_file( $pid_file, 5 );
    ok $agent_pid, 'agent was forked (pid file populated)'
        or BAIL_OUT 'no agent pid recorded -- the runner did not fork';

    select undef, undef, undef, 0.1;
    ok kill( 0, $agent_pid ), 'agent is alive in /proc before the kill';

    # External SIGKILL -- the OOM-killer shape.
    kill 'KILL', $agent_pid;

    reap_wait($dpid);

    my $log = -e $repo->child('.karr.log') ? $repo->child('.karr.log')->slurp_utf8 : '';
    like $log, qr/END elapsed=\d+s exit=(\d+)/, 'log has END line'
        or diag "log was: $log";

    my ($reported) = $log =~ /END elapsed=\d+s exit=(\d+)/;
    is $reported, 128 + SIGKILL,
        "exit code in log is 128+SIGKILL=137 (was: $reported)"
        or diag "runner reported $reported for a SIGKILLed agent -- bug #164 still present";

    isnt $reported, 0,
        'the SIGKILLed agent is NOT booked as exit 0'
        or diag 'agent was killed by SIGKILL but runner said exit 0';
};

subtest 'agent killed by external SIGTERM+SIGKILL is reported as 128+SIGKILL' => sub {
    # The wrapper ignores SIGTERM (so the kill actually escalates), then
    # the test sends SIGKILL to simulate the kernel OOM-killer landing
    # mid-escalation. The runner sees only SIGKILL because SIGTERM was
    # caught by the wrapper.
    my $scratch = path( tempdir( CLEANUP => 1 ) );
    my $repo    = $scratch->child('repo');
    $repo->mkpath;
    $repo->child('.karr.log')->touch;
    my $pid_file = $scratch->child('agent.pid');

    my $wrapper = write_signal_ignoring_wrapper( $scratch, '/bin/sleep 20' );
    my $driver  = write_driver( $scratch, $wrapper );

    my $dpid = fork;
    die "fork: $!" unless defined $dpid;
    if ( $dpid == 0 ) {
        exec( $^X, "$driver" ) or die;
    }

    my $agent_pid = wait_for_pid_file( $pid_file, 5 );
    ok $agent_pid, 'agent was forked';

    select undef, undef, undef, 0.1;
    kill 'TERM', $agent_pid;
    select undef, undef, undef, 0.1;
    kill 'KILL', $agent_pid;

    reap_wait($dpid);

    my $log = -e $repo->child('.karr.log') ? $repo->child('.karr.log')->slurp_utf8 : '';
    like $log, qr/END elapsed=\d+s exit=(\d+)/, 'log has END line'
        or diag "log was: $log";

    my ($reported) = $log =~ /END elapsed=\d+s exit=(\d+)/;
    ok defined $reported, 'log has END line (parsed)';
    isnt $reported, 0, 'killed agent is not booked as exit 0';
    is $reported, 128 + SIGKILL,
        'reported exit is 128+SIGKILL (the actual kill signal)'
        or diag "runner reported $reported for a SIGTERM->SIGKILLed agent";
};

done_testing;