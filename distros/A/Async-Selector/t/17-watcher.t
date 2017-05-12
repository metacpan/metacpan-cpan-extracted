use strict;
use warnings;
use Test::More;
use Test::Builder;
use Test::Warn;

use FindBin;
use lib "$FindBin::RealBin/lib";
use Async::Selector::testutils;

BEGIN {
    use_ok('Async::Selector');
    use_ok('Async::Selector::Watcher');
}

{
    note('--- active() method.');
    my $s = Async::Selector->new();
    my $res = 0;
    $s->register(a => sub {
        my $in = shift;
        return $res >= $in ? $res : undef;
    });
    my @result = ();
    my $w = $s->watch(a => 10, sub {
        my ($w, %res) = @_;
        push(@result, $res{a});
        $w->cancel();
    });
    isa_ok($w, 'Async::Selector::Watcher');
    ok($w->active, "watcher is active");
    is(int($s->watchers), 1, "1 pending watcher");
    is(int(@result), 0, "result empty");
    $res = 10;
    $s->trigger('a');
    ok(!$w->active, "watcher is now inactive");
    is(int($s->watchers), 0, "0 pending watcher");
    is(int(@result), 1, "1 result...");
    is($result[0], 10, '... and it is 10');

    note('--- -- immediate');
    @result = ();
    $w = $s->watch(a => 5, sub {
        my ($w, %res) = @_;
        push(@result, $res{a});
        $w->cancel();
    });
    is($result[0], 10, 'immediate fire');
    is(int($s->watchers), 0, 'no watcher');
    isa_ok($w, 'Async::Selector::Watcher', 'even in the immediate fire case, watch() should return a Watcher');
    ok(!$w->active, '... and it is inactive.');

    note('--- -- empty watch');
    $w = $s->watch(sub {
        fail('This should not be executed.');
    });
    isa_ok($w, "Async::Selector::Watcher");
    ok(!$w->active, 'empty watch should return an inactive watcher.');
}

sub testConditions {
    my ($s, $watch_args, $exp_res, $exp_cond, $case) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $w = $s->watch(@$watch_args);
    checkCond($w, $exp_res, $exp_cond, $case);
}

{
    note('--- condition() and resources() methods.');
    my $s = Async::Selector->new();
    my $failcb = sub { fail('This should not be executed.') };
    testConditions($s, [a => 10, $failcb], ['a'], {a => 10}, "watch 1 resource");
    my $cond_array = [qw(x y z)];
    testConditions(
        $s, [b => 'foobar', c => 992.5, a => $cond_array, $failcb],
        [qw(a b c)], { a => $cond_array, b => 'foobar', c => 992.5 },
        'watch 3 resources'
    );
    testConditions($s, [$failcb], [], {}, "empty watch")
}

{
    note('--- cancel() multiple times on the same Watcher.');
    my $s = Async::Selector->new();
    my $w = $s->watch(a => 10, sub {
        fail("This should not be executed.");
    });
    is(int($s->watchers), 1, '1 pending watcher.');
    $s->trigger('a');
    $s->trigger('a');
    is(int($s->watchers), 1, '1 pending watcher.');
    $w->cancel();
    is(int($s->watchers), 0, '0 pending watcher.');
    warning_is { $w->cancel() } undef, 'calling cancel() multiple times is ok.';
}

{
    note('--- cancel() while two Selectors exist');
    my $sa = Async::Selector->new();
    my $sb = Async::Selector->new();
    my @w = (
        (map { $sa->watch(a => 10, sub { fail('sa: this should not be executed') }) } 1..5),
        (map { $sb->watch(a => 10, sub { fail('sb: this should not be executed') }) } 1..5),
    );
    is(int($sa->watchers), 5);
    is(int($sb->watchers), 5);
    $w[$_]->cancel() foreach (0, 4, 6, 7, 9);
    is(int($sa->watchers), 3);
    is(int($sb->watchers), 2);
    $w[$_]->cancel() foreach (2, 3, 5, 8);
    is(int($sa->watchers), 1);
    is(int($sb->watchers), 0);
    $w[1]->cancel();
    is(int($sa->watchers), 0);
}

{
    note('--- new() with undef selector.');
    my $w;
    warning_is {
        $w = Async::Selector::Watcher->new(
            undef, {}, sub { fail('This should not be executed.') }
        );
    } undef, 'No warning when Watcher->new(undef, ...)';
    ok(!$w->active, 'watcher is inactive');
    warning_is { $w->cancel() } undef, '$w->cancel() is ok. It does nothing';
    warning_is { $w->cancel() } undef, '... so you can call $w->cancel() multiple times.';
}

done_testing();



