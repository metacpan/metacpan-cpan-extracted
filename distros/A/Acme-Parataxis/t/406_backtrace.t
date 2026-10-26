use v5.40;
use blib;
use Acme::Parataxis qw[run fiber yield await_sleep dump_fibers backtrace_depth];
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Channel;
use Test2::V1 -ipP;
$|++;

# Full park-site backtraces. Every _park now hangs a bounded, user-side caller chain off the wait-reason
# record as its fourth element: wait_reason returns [reason, file, line, backtrace] where backtrace is an arrayref
# of [pkg, file, line, sub] frames running from just below the recorded site back to the fiber body (no library
# frames; [] when the park is reached directly from the body or capture is off). backtrace_depth() sets the cap.
subtest 'a park reached through nested user subs records the chain back to the fiber body' => sub {
    my ( $r, $first_line );
    run(
        sub {
            my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
            my $w   = fiber {
                my $inner = sub {
                    $first_line = __LINE__ + 1;
                    $sem->down;
                };
                my $outer = sub { $inner->() };
                $outer->();
            };
            yield;
            $r = $w->wait_reason;
            is $r->[0], 'Semaphore down', 'the record still names the wait';
            ok !scalar( grep { index( $_->[0], 'Acme::Parataxis' ) == 0 } @{ $r->[3] } ), 'no library frames pollute the chain';
            ok( scalar( @{ $r->[3] } ) >= 2, 'the chain has at least the {inner, outer} user frames below the wait' );
            is $r->[3][0][1], __FILE__, 'first chain frame file';
            ok $r->[3][0][2] >= $first_line, 'first chain frame sits at or below the down() call line';
            ok( defined $r->[3][0][3] && $r->[3][0][3] ne q{}, 'the frame carries a sub name' );
            $sem->up;
            $w->await;
            ok !defined $w->wait_reason, 'the record (backtrace included) is cleared on the natural wake';
        }
    );
};
subtest 'a wait reached straight from the fiber body has an empty chain' => sub {
    my ( $r, $line );
    run(
        sub {
            my $w = fiber {
                $line = __LINE__ + 1;
                await_sleep(30);
            };
            yield;
            $r = $w->wait_reason;
            is $r->[0], 'await_sleep', 'the record still names the wait';
            ok !@{ $r->[3] }, 'no user frame below the site: empty chain, record shape intact';
            $w->await;
        }
    );
};
subtest 'the capture depth is configurable and caps the chain' => sub {
    my $orig = backtrace_depth();
    is $orig, 6, 'default depth is 6';
    backtrace_depth(2);
    my ( $r, $n );
    run(
        sub {
            my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
            my $w   = fiber {
                my $h1 = sub { $sem->down };
                my $h2 = sub { $h1->() };
                my $h3 = sub { $h2->() };
                my $h4 = sub { $h3->() };
                $h4->();
            };
            yield;
            $r = $w->wait_reason;
            $n = scalar @{ $r->[3] };
            $sem->up;
            $w->await;
        }
    );
    is $n, 2, 'a depth-2 capture stops after two user frames despite a four-frame chain';
    backtrace_depth(0);
    run(
        sub {
            my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
            my $w   = fiber { $sem->down };
            yield;
            ok !@{ $w->wait_reason->[3] }, 'depth 0 disables the capture entirely';
            $sem->up;
            $w->await;
        }
    );
    like dies { backtrace_depth(-1) },  qr[non-negative], 'negative depth croaks';
    like dies { backtrace_depth('x') }, qr[non-negative], 'non-integer depth croaks';
    backtrace_depth($orig);
    is backtrace_depth(), $orig, 'depth restored for the rest of the suite';
};
subtest 'the snapshot and the human report carry the chain' => sub {
    my ( $snap, $report, $bt );
    run(
        sub {
            my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
            my $w   = fiber {
                my $h = sub { $sem->down };
                $h->();
            };
            yield;
            $snap = dump_fibers();
            $bt   = ( grep { $_->{fid} == $w->fid } @$snap )[0]{reason}[3];
            ok( scalar(@$bt) >= 1, 'dump_fibers() records expose the backtrace' );
            open my $cap, '>', \$report;
            dump_fibers($cap);
            $sem->up;
            $w->await;
        }
    );
    like $report, qr/        at .*:\d+\s+\S/, 'the human report prints each frame as an indented "at" line';
    like $report, qr/at \Q$0\E:\d+/,          'the chain frame names this test file';
};
subtest 'the FATAL deadlock report shows each parked fiber\'s chain back to user code' => sub {
    my $dead;
    ok(
        $dead = dies {
            run(
                sub {
                    my $deadlock = sub { Acme::Parataxis::Channel->new( capacity => 1 )->get; 1 };
                    $deadlock->();
                    1;
                }
            );
        }
    );
    like $dead, qr/FATAL: deadlock detected/,   'the message announces the deadlock';
    like $dead, qr/Channel get/,                'it names the parked wait';
    like $dead, qr/        at \Q$0\E:\d+\s+\S/, 'and the chain back to user code';
    is( scalar( @{ dump_fibers() } ), 1, 'the parked fiber survives for post-mortem inspection' );
    ok( scalar( @{ dump_fibers()->[0]{reason}[3] } ) >= 1, 'the leaked fiber still carries its backtrace' );
};
done_testing();
