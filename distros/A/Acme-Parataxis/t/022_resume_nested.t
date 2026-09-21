use v5.40;
use blib;
use Acme::Parataxis qw[async yield await fiber];
use Test2::V1 -ipP;
$|++;
#
subtest 'Resume after nested spawn' => sub {

    # Regression: coro_call overwrote the fiber's saved top_env on every
    # resume, so a fiber that yielded AFTER a nested spawn came back with
    # PL_top_env pointing at the caller's (main) stack.  The resumed fiber's
    # call_sv then failed perl.c:3298 "Assertion PL_top_env == &cur_env
    # failed" on threaded-debug perls (abort, exit 134).
    my $out = '';
    async {
        fiber {1};
        yield;
        $out = 'done';
    };
    is $out, 'done', 'fiber completed its body after yield following a nested spawn';
};
subtest 'Spawn and await in the same fiber, then yield' => sub {
    my @log;
    async {
        my $child = fiber {1};
        my $r     = await($child);
        push @log, "child=$r";
        yield;
        push @log, 'parent-done';
    };
    is "@log", 'child=1 parent-done', 'resumed fiber saw both its nested result and the post-yield continuation';
};
#
done_testing();
