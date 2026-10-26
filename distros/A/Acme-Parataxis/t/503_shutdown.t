use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis qw[run fiber yield await_sleep];
use IO::Select;
use POSIX ();
$|++;

# run( on_shutdown => ... ) makes the outermost run install SIGINT/SIGTERM handlers, fires a shutdown
# CancellationToken on the first signal, drains every fiber it created (their Error::Cancelled unwinds run their own
# cleanup - defers/DESTROYs), and returns the conventional interrupted status (130/143) instead of rethrowing.
#
# The plumbing subtests run everywhere. Real OS signal delivery (kill) is unreliable on MSWin32 perl (same reason
# t/003 skips there), so the subprocess harness that fires actual SIGINT/SIGTERM is skipped on that platform.
sub can_signal { return $^O ne 'MSWin32' }
my $int0  = $SIG{INT};
my $term0 = $SIG{TERM};
subtest 'on_shutdown option plumbing' => sub {
    my $int0  = $SIG{INT};
    my $term0 = $SIG{TERM};
    my $r     = run( code => sub {42}, on_shutdown => 1 );
    is $r,         42,     'normal completion returns the main fiber value with on_shutdown set';
    is $SIG{INT},  $int0,  'SIGINT restored after a run with on_shutdown => 1';
    is $SIG{TERM}, $term0, 'SIGTERM restored after a run with on_shutdown => 1';
    my $cb_called = 0;
    my $cb_tok    = 'unset';
    my $r2        = run( on_shutdown => sub ($tok) { $cb_called = 1; $cb_tok = $tok }, code => sub {7}, virtual => 1 );
    is $r2,        7,       'mixed option order runs and returns the main fiber value';
    is $cb_called, 0,       'the shutdown callback is NOT called on a normal completion';
    is $cb_tok,    'unset', 'the callback slot is untouched on a normal completion';
    is $SIG{INT},  $int0,   'SIGINT restored after the callback form';
    is $SIG{TERM}, $term0,  'SIGTERM restored after the callback form';
    my $r3 = run( sub {1} );
    is $r3,        1,      'plain run returns its value';
    is $SIG{INT},  $int0,  'a plain run without on_shutdown leaves SIGINT untouched';
    is $SIG{TERM}, $term0, 'a plain run without on_shutdown leaves SIGTERM untouched';
    my $e1 = dies {
        run( foo => 1, code => sub { } );
    };
    like( $e1, qr/unknown option/, 'an unknown run() option croaks' );
    my $e2 = dies {
        run( code => sub { }, on_shutdown => [] );
    };
    like( $e2, qr/on_shutdown/, 'a non-code on_shutdown ref croaks' );
    my $e3 = dies { run( on_shutdown => 1 ) };
    like( $e3, qr/code/, 'on_shutdown without code croaks' );
    is $SIG{INT},  $int0,  'SIGINT untouched after the croaks';
    is $SIG{TERM}, $term0, 'SIGTERM untouched after the croaks';
    my $inner = run(
        code => sub {
            return run( on_shutdown => 1, code => sub { return 'inner' } );
        }
    );
    is $inner,     'inner', 'a nested run with on_shutdown ignores the option and completes';
    is $SIG{INT},  $int0,   'the inner run left SIGINT untouched';
    is $SIG{TERM}, $term0,  'the inner run left SIGTERM untouched';
};

# The shutdown drain itself is driver-agnostic: handing run() a CancellationToken as on_shutdown means anyone - a
# health port, a parent process, or a test - can begin the graceful shutdown in-process, with no OS signal required.
# This exercises the whole interrupt/drain/status path on every platform; only the OS signal delivery itself is
# Unix-only below.
subtest 'shutdown via the on_shutdown token (portable)' => sub {
    my $tok = Acme::Parataxis::CancellationToken->new;
    my $r   = run( on_shutdown => $tok, code => sub { return 'quick' } );
    is $r, 'quick', 'an unused on_shutdown token leaves the run normal';
    ok !$tok->cancelled, 'the token was not fired by a normal run';

    # Re-run with a canceller fiber: the token fires from inside the run, every fiber is interrupted, the waiter's
    # Error::Cancelled is swallowed by its own eval, and run() reports the interrupted status after draining.
    my $tok2         = Acme::Parataxis::CancellationToken->new;
    my $fired_marker = 0;
    my $r2           = run(
        on_shutdown => $tok2,
        code        => sub {
            my $g = bless {}, 'ShutdownProbe2';
            fiber { $tok2->cancel; $fired_marker++ };
            fiber {
                eval { await_sleep(60_000); 1 };
                $fired_marker++
            };
            my $out = eval { await_sleep(60_000); 'slept' };
            return $out;
        },
    );
    is $r2,           130,    'cancelling the on_shutdown token inside the run returns the interrupted status (130)';
    is $fired_marker, 2,      'every run fiber was woken and completed draining (no fiber outlived the shutdown)';
    is $SIG{INT},     $int0,  'SIGINT restored after the token shutdown';
    is $SIG{TERM},    $term0, 'SIGTERM restored after the token shutdown';
    my $cb_called = 0;
    my $r3        = run(
        on_shutdown => sub ($tok) { $cb_called++ },
        code        => sub {
            fiber {
                sub { }
                    ->()
            };    # no-op
            return 'ok';
        },
    );
    is $r3, 'ok', 'a plain completion with the callback form is untouched';
    my $r4 = run( sub {5} );
    is $r4,        5,      'the scheduler is reusable after a token-driven shutdown';
    is $SIG{INT},  $int0,  'SIGINT untouched after the reuse run';
    is $SIG{TERM}, $term0, 'SIGTERM untouched after the reuse run';
    my $e4 = dies {
        run( code => sub { }, on_shutdown => bless( {}, 'Nope::NotaToken' ) );
    };
    like( $e4, qr/on_shutdown/, 'an unrelated object as on_shutdown croaks' );
};

# The rest is a subprocess harness: a child perl installs run()'s handlers, sleeps, and the parent delivers real OS
# signals, reading the child's drain log through a pipe.
sub deadline () { return time + 30 }

sub pump {
    my ( $r, $buf ) = @_;
    return 0 unless my @rd = IO::Select->new($r)->can_read(0.1);
    my $n = sysread( $r, my $chunk, 4096 );
    return 0 unless defined $n && $n > 0;
    $$buf .= $chunk;
    return 1;
}

sub wait_for {
    my ( $r, $buf, $re, $limit ) = @_;
    while ( time < $limit ) {
        return 1 if $$buf =~ $re;
        pump( $r, $buf );
    }
    return 0;
}

sub spawn_child {
    my ($body) = @_;
    $ENV{PERL_BADLANG} = 0;    # breaks a broken-locale perl (Haiku's SIGINT leg) no longer spams "Setting locale failed."

    # startup warnings into the drained pipe, which would break the exact-4-lines assertion
    pipe my ( $r, $w ) or die "pipe: $!";
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ( !$pid ) {
        close $r;
        open STDOUT, '>&', $w or die "dup: $!";
        open STDERR, '>&', $w or die "dup: $!";
        $w->autoflush(1);
        my $code = join "\n", 'use v5.40; use blib; use Acme::Parataxis qw[run await_sleep]; $|++;', $body, '';
        exec $^X, '-Mblib', '-e', $code or die "exec: $!";
    }
    close $w;
    return ( $pid, $r );
}

sub reap {
    my ( $pid, $r, $buf, $limit ) = @_;
    my $status;
    while ( time < $limit ) {
        my $kid = waitpid( $pid, &POSIX::WNOHANG );
        if ( $kid == $pid ) {
            $status = $?;
            last;
        }
        pump( $r, $buf );
    }
    waitpid( $pid, 0 ) unless defined $status;    # the loop gave up; block to clean up
    return ( $$buf, $status );
}
subtest 'shutdown by real signals (subprocess harness)' => sub {
    plan skip_all => 'real OS signal delivery is unreliable on this platform (t/003 skips signals on MSWin32)' unless can_signal();

    # Child 1: SIGINT during a 30s await_sleep. run() must drain the run (the fiber catches, prints DEFER_RAN,
    # its DESTROY runs as the fiber frame pops), return 130, and the child exits 0 after reporting it.
    {
        my ( $pid, $r ) = spawn_child(<<'CHILD');
my $got = run( on_shutdown => 1, code => sub {
    my $g = bless {}, 'ShutdownProbe';
    say 'READY';
    my $out = eval { await_sleep(30_000); 'slept' };
    say 'DEFER_RAN' if $@;
    say 'UNREACHABLE' unless $@;
} );
say 'DRAINED:' . $got;
exit(0);
package ShutdownProbe;
use v5.40;
sub DESTROY { say 'DESTROY_RAN' }
CHILD
        my $buf = '';
        my $lim = deadline();
        ok wait_for( $r, \$buf, qr/READY/, $lim ), 'child reported READY';
        kill 'INT' => $pid;
        ok wait_for( $r, \$buf, qr/DRAINED:130/, $lim ), 'SIGINT drained the run and run() returned 130';
        like $buf,   qr/READY.*DEFER_RAN.*DESTROY_RAN.*DRAINED:130/s, 'the drain log shows the defer and the DESTROY running before the status';
        unlike $buf, qr/UNREACHABLE/,                                 'the sleep did not complete';
        my ( $out, $status ) = reap( $pid, $r, \$buf, $lim );
        is( $status,         0, 'the child exited cleanly (0) after reporting the drained shutdown' );
        is( $out =~ tr/\n//, 4, 'the drain log is exactly the four expected lines' );
    }

    # Child 2: SIGTERM maps to status 143, same drain.
    {
        my ( $pid, $r ) = spawn_child(<<'CHILD');
my $got = run( on_shutdown => 1, code => sub {
    say 'READY';
    my $out = eval { await_sleep(60_000); 'slept' };
    die 'sleep completed' unless $@;
} );
say 'DRAINED:' . $got;
exit(0);
CHILD
        my $buf = '';
        my $lim = deadline();
        ok wait_for( $r, \$buf, qr/READY/, $lim ), 'child reported READY';
        kill 'TERM' => $pid;
        ok wait_for( $r, \$buf, qr/DRAINED:143/, $lim ), 'SIGTERM drained the run and run() returned 143';
        my ( $out, $status ) = reap( $pid, $r, \$buf, $lim );
        is( $status, 0, 'the child exited cleanly (0) after the TERM shutdown' );
    }

    # Child 3: a second SIGINT while the drain is still open (the fiber's cleanup sleeps) must deliver the default
    # kill - the handler never blocks a second Ctrl+C - so the process dies and never prints DRAINED.
    {
        my ( $pid, $r ) = spawn_child(<<'CHILD');
my $got = run( on_shutdown => 1, code => sub {
    say 'READY';
    my $out = eval { await_sleep(60_000); 'slept' };
    if ($@) { say 'DEFER_RAN'; select undef, undef, undef, 3; say 'CLEANED' }
} );
say 'DRAINED:' . $got;
CHILD
        my $buf = '';
        my $lim = deadline();
        ok wait_for( $r, \$buf, qr/READY/, $lim ), 'child reported READY';
        kill 'INT' => $pid;
        ok wait_for( $r, \$buf, qr/DEFER_RAN/, $lim ), 'first SIGINT was caught and the drain began';
        kill 'INT' => $pid;
        my $out = reap( $pid, $r, \$buf, $lim );
        unlike $out, qr/DRAINED/, 'the second SIGINT killed the process before the drain finished (no DRAINED)';
        unlike $out, qr/CLEANED/, 'the second SIGINT killed the process mid-cleanup';
    }
};
done_testing();
