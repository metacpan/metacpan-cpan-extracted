use v5.40;
no warnings 'recursion';    # fibers run on separate heap stacks; Perl's C-stack-depth heuristic misfires there
use blib;
use Acme::Parataxis qw[async fiber await_sleep];
use Test2::V1 -ipP;
use Time::HiRes 'time';
$|++;

# Fibers run on separate heap stacks; Perl's C-stack-depth heuristic can misfire and falsely report "Deep recursion"
# (it ignores lexical 'no warnings' once a framework such as Test2 is loaded). Genuine runaway recursion inside a fiber
# surfaces as a hang, access violation, or croak the harness already catches, so filter the noise.
BEGIN {
    $SIG{__WARN__} = sub { return if $_[0] =~ /^Deep recursion on subroutine/; warn @_ }
}
my $BASE = Acme::Parataxis::get_live_fiber_count();

# init_threads seeds the pool with two workers and submit_c_job used to grow it only when jobs were ALREADY pending
# BEFORE the new job was inserted. A lone submission against a pool whose every worker sat in a long TASK_SLEEP thus saw
# pending == 0, spawned nothing, and queued behind those sleeps: a 10ms await_sleep submitted while a 400ms timer sleep
# and a 600ms sleeper held both workers woke at 400ms. Every timing assertion below is paired with a control so it
# cannot pass vacuously by the long sleeps having quietly finished.
subtest 'a lone short sleep gets its own worker instead of queueing behind long sleeps' => sub {
    my ( $t0, $short_ms, $out_after, @long_done );
    async {
        $t0 = time;

        # Occupy every worker the pool starts with before main submits anything.
        my @long = map {
            my $ms = $_;
            fiber { await_sleep($ms); push @long_done, [ $ms, ( time - $t0 ) * 1000 ] }
        } 600, 400;
        Acme::Parataxis->yield while Acme::Parataxis::get_outstanding_jobs() < 2;
        my $t = time;
        await_sleep(10);
        $short_ms  = ( time - $t ) * 1000;
        $out_after = Acme::Parataxis::get_outstanding_jobs();
        $_->await for @long;
    };
    ok defined $short_ms, 'the short sleep returned at all';
    cmp_ok $short_ms, '<', 300, sprintf 'a 10ms sleep came back in %.0fms with both workers busy (the bug queued it ~400ms)', $short_ms;

    # Control for the timing above: it did not win by luck. Both long sleeps were still outstanding when the short one
    # returned, which is only possible if the pool grew a worker rather than a long sleep having freed up.
    ok $out_after >= 2, sprintf 'control: both long sleeps still in flight when it returned (outstanding=%d)', $out_after // -1;

    # Control for that control: the long sleeps really were sleeping, each to its own deadline.
    is scalar @long_done, 2, 'both long sleepers finished';
    for my $d (@long_done) {
        my ( $ms, $el ) = @$d;
        cmp_ok $el, '>=', $ms * 0.9, sprintf 'control: the %dms sleeper really slept (%.0fms elapsed, not released early)', $ms, $el;
    }
};
subtest 'a whole backlog of short sleeps is covered in one go, not one worker per submit' => sub {
    my ( $t0, @took );
    async {
        $t0 = time;
        my @long = map {
            my $ms = $_;
            fiber { await_sleep($ms) }
        } 1000, 1000;
        Acme::Parataxis->yield while Acme::Parataxis::get_outstanding_jobs() < 2;

        # Submitted back to back with no idle worker anywhere: the pool must grow by the deficit, not trickle.
        my @s = map {
            fiber { my $u = time; await_sleep(20); push @took, ( time - $u ) * 1000 }
        } 1 .. 8;
        $_->await for @s;
        $_->await for @long;
    };
    is scalar @took, 8, 'all 8 concurrent short sleeps ran';
    my $worst = 0;
    $worst = $_ > $worst ? $_ : $worst for @took;
    cmp_ok $worst, '<', 500, sprintf 'slowest of the 8 took %.0fms (the bug left them queued until a 1000ms sleep ended)', $worst;
};
is Acme::Parataxis::get_live_fiber_count(), $BASE, 'every fiber created by these scenarios was reaped';
#
done_testing;
