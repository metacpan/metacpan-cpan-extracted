use v5.40;
use blib;
use Acme::Parataxis qw[await_sleep run fiber yield dump_fibers];
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Channel;
use Test2::V1 -ipP;
$|++;

# Diagnostics & deadlock tracing. dump_fibers() snapshots every live fiber with the state (RUNNING/WAITING/
# READY/RUNNABLE) and the wait_reason [reason, file, line] recorded at every park; the scheduler's
# FATAL deadlock report now lists each parked fiber of the deadlocked run instead of a bare string.
subtest 'run-time dump classifies a fiber blocked on a semaphore and one on a sleep' => sub {
    my $snap;
    run(
        sub {
            my $sem        = Acme::Parataxis::Semaphore->new( count => 0 );
            my $me         = Acme::Parataxis->current_fid;
            my $waiter     = fiber { $sem->down; 1 };
            my $sleep_line = __LINE__ + 1;
            my $sleeper    = fiber { await_sleep(300); 1 };
            $snap = dump_fibers();
            my %by = map { $_->{fid} => $_ } @$snap;
            ok @$snap >= 3,                                                            'the snapshot lists every live fiber';
            ok scalar( grep { $_->{fid} == $me && $_->{state} eq 'RUNNING' } @$snap ), 'the fiber doing the dump is RUNNING';
            ok my $w = $by{ $waiter->fid },                                            'the semaphore waiter is listed';
            is $w->{state},     'WAITING',        'blocked on the semaphore park';
            is $w->{reason}[0], 'Semaphore down', 'its wait reason names the wait';
            ok defined $w->{reason}[2],      'and the site is captured';
            ok my $s = $by{ $sleeper->fid }, 'the sleeper is listed';
            is $s->{state},     'WAITING',     'blocked on the sleep job';
            is $s->{reason}[0], 'await_sleep', 'its wait reason names the wait';
            like $s->{reason}[1], qr[400_diagnostics\.t$], 'the site is the fiber body that slept';
            is $s->{reason}[2], $sleep_line, 'at the exact line of the call';
            my $report = '';
            open my $cap, '>', \$report;
            dump_fibers($cap);
            like $report, qr[Acme::Parataxis live fiber dump], 'dump_fibers($fh) prints the report';
            like $report, qr[WAITING],                         'with the blocked states';
            like $report, qr[await_sleep],                     'and the wait reasons';
            $sem->up;          # release the waiter...
            $waiter->await;    # ...and let the scheduler finish it before this run ends
        }
    );
};
subtest 'a fiber that yielded back to the scheduler is READY' => sub {
    my $snap;
    run(
        sub {
            my $release = 0;
            my $spinner = fiber {
                until ($release) { Acme::Parataxis->yield }
                1
            };
            $snap = dump_fibers();    # taken while $spinner is queued, before it can run again
            ok scalar( grep { $_->{fid} == $spinner->fid && $_->{state} eq 'READY' } @$snap ), 'the queued fiber is READY';
            ok !scalar( grep { $_->{state} eq 'WAITING' } @$snap ),                            'nothing is parked';
            $release = 1;             # let the spinner finish so the run ends clean
        }
    );
};
subtest 'a finished run leaves no live fibers behind' => sub {
    is( scalar @{ dump_fibers() }, 0, 'top-level dump after clean runs is empty' );
};
subtest 'the FATAL deadlock report lists every parked fiber, its reason and site' => sub {
    like dies {
        run( sub { Acme::Parataxis::Channel->new( capacity => 1 )->get; 1 } )
    }, qr[FATAL: deadlock detected], 'the message announces the deadlock';
    is scalar( @{ dump_fibers() } ), 1, 'the parked fiber survives for post-mortem inspection';
    like dump_fibers()->[0]{reason}[0], qr[Channel get], 'and dump_fibers still reports it';
};
#
done_testing();
