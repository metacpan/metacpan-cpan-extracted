use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::RealBin/lib";
use Async::Selector::testutils;

note("Test for 1-resource 1-watcher.");

BEGIN {
    use_ok('Async::Selector');
}

my $s = new_ok('Async::Selector');
cmp_ok(int($s->resources), '==', 0, 'zero resources registered.');

my $res_a = 0;
is($s->register(
    "a", sub {
        my $in = shift;
        return $res_a >= $in ? $res_a : undef;
    }
), $s, 'register() returns the object.');

cmp_ok(int($s->resources), "==", 1, "one resource registered.");
is(($s->resources)[0], 'a', '... and its name is "a".');
ok($s->registered('a'), 'a is registered');
ok(!$s->registered('b'), 'b is not registered');
ok(!$s->registered('A'), 'A is not registered');

my @result = ();
{
    note("--- LT select, one-shot, not immediate.");
    my $w; $w = $s->watch(a => 5, sub {
        my ($watcher, %res) = @_;
        isa_ok($watcher, 'Async::Selector::Watcher');
        is($watcher, $w, "The watcher in the callback is the watcher returned.");
        checkCond($watcher, ['a'], {a => 5}, "watcher in callback");
        cmp_ok(int(keys %res), "==", 1, "selected one resource.");
        ok(defined($res{a}), "resource a is available.");
        push(@result, $res{a});
        $watcher->cancel();
    });
    isa_ok($w, 'Async::Selector::Watcher', "watch() always returns a Watcher.");
    ok($w->active, 'the watcher is active.');
    foreach (0 .. 4) {
        is($s->trigger('a'), $s, 'trigger() method returns the object.');
        cmp_ok(int(@result), "==", 0, 'no entry in result yet.');
        $res_a++;
    }
    cmp_ok($res_a, '==', 5, "now res_a is 5.");
    $s->trigger('a');
    cmp_ok(int(@result), '==', 1, 'one result has arrived!');
    cmp_ok((shift @result), '==', $res_a, "... and it's $res_a.");
    ok(!$w->active, "the watcher is inactive.");
    checkCond($w, ['a'], {a => 5}, "inactive watcher");

    $s->trigger('a');
    cmp_ok(int(@result), "==", 0, "no result anymore, because the watcher was removed.");
}

{
    note("--- LT select, one-shot, immediate fire.");
    my $w = $s->watch(a => 3, sub {
        my ($watcher, %res) = @_;
        push(@result, $res{a});
        $watcher->cancel();
    });
    isa_ok($w, 'Async::Selector::Watcher', "watch() returns a watcher even if the request is handled immediately.");
    ok(!$w->active, 'So the watcher is inactive.');
    checkCond($w, ['a'], {a => 3}, 'immediately fired watcher');
    cmp_ok(int(@result), "==", 1, "get a result without trigger()");
    is((shift @result), $res_a, "... and it's $res_a");
}

{
    note("--- LT select, continuous, not immediate.");
    @result = ();
    my $w = $s->watch(a => 10, sub {
        my ($watcher, %res) = @_;
        push(@result, $res{a});
    });
    ok(defined($w), "watch() method returns defined value...");
    isa_ok($w, 'Async::Selector::Watcher', "... and it's an Async::Selector::Watcher");
    ok($w->active, "... and it's active");
    {
        my @watchers = $s->watchers;
        is(int(@watchers), 1, "Currently 1 watcher.");
        is($watchers[0], $w, "... and it's $w.");
    }
    $res_a = 9; $s->trigger('a');
    cmp_ok(int(@result), "==", 0, "no result.");
    $res_a = 10; $s->trigger('a');
    cmp_ok(int(@result), "==", 1, "got a result.");
    is((shift @result), $res_a, "... and is $res_a");
    $s->trigger('a') foreach 1..3;
    cmp_ok(int(@result), "==", 3, "every call to trigger() kicks the watcher callback repeatedly.");
    is($_, $res_a, "... the result is $res_a") foreach @result;
    ok($w->active, "watcher is still active");
    checkCond($w, ['a'], {a => 10}, "watcher fired several times");
    @result = ();
    
    note("--- -- cancel() operation.");
    is($w->cancel(), $w, "cancel() returns the Watcher object.");
    $s->trigger('a') foreach 1..3;
    cmp_ok(int(@result), "==", 0, "no result because the watcher is canceled.");
    is(int($s->watchers), 0, "no watchers");
    ok(!$w->active, 'watcher is now inactive');
    checkCond($w, ['a'], {a => 10}, "canceled watcher");
}

{
    note("--- LT select, continuous, immediate.");
    @result = ();
    $res_a = 20;
    my $w = $s->watch_lt(a => 1, sub {
        my ($w, %res) = @_;
        push(@result, $res{a});
    });
    is(int($s->watchers), 1, "One watcher");
    is(($s->watchers)[0], $w, "... and it's $w.");
    foreach (1 .. 3) {
        cmp_ok(int(@result), "==", 1, "got result immediately.");
        is($result[0], $res_a, "... and it's $res_a");
        @result = ();
        $s->trigger('a');
    }
    ok($w->active, "watcher is active");
    checkCond($w, ['a'], {a => 1}, "LT continuous watcher");
    @result = ();
    note("--- -- cancel() operation.");
    $w->cancel();
    is(int($s->watchers), 0, "No watcher");
    $s->trigger('a');
    $s->trigger('a');
    cmp_ok(int(@result), "==", 0, "got no result because watcher is canceled.");
    ok(!$w->active, "watcher is inactive");
    checkCond($w, ['a'], {a => 1}, 'canceled watcher');
}

{
    note("--- ET select, one-shot, forcibly not immediate.");
    @result = ();
    $res_a = 5;
    my $w = $s->watch_et(a => 1, sub {
        my ($w, %res) = @_;
        push(@result, $res{a});
        $w->cancel();
    });
    is(int($s->watchers), 1, "One watcher");
    is(($s->watchers)[0], $w, "... and it's $w.");
    ok($w->active, "watcher is active.");
    checkCond($w, ['a'], {a => 1}, "ET watcher");
    cmp_ok(int(@result), "==", 0, "got no result because it's edge-triggered.");
    $s->trigger('a');
    cmp_ok(int(@result), "==", 1, "got a result when triggerred.");
    is($result[0], $res_a, "... and is $res_a");
    @result = ();
    $s->trigger('a');
    cmp_ok(int(@result), "==", 0, "watcher has been automatically removed.");
    cmp_ok(int($s->watchers), "==", 0, "No watchers");
    ok(!$w->active, 'watcher is inactive');
}

{
    note("--- ET select, continuous, forcibly not immediate.");
    @result = ();
    $res_a = 7;
    my $w = $s->watch_et(a => 5, sub {
        my ($w, %res) = @_;
        push(@result, $res{a});
    });
    cmp_ok(int(@result), "==", 0, "got no result because it's edge-triggered.");
    ok($w->active, "watcher is active");
    checkCond($w, ['a'], {a => 5}, 'ET watcher');
    $res_a = 10;
    $s->trigger('a');
    cmp_ok(int(@result), "==", 1, "got a result");
    is($result[0], $res_a, "... and is $res_a");
    ok($w->active, "watcher is still active");
    @result = ();
    $s->trigger('a');
    cmp_ok($result[0], "==", $res_a, "callback executed for every trigger, even if the resource is not changed actually.");
    
    $res_a = 0;
    @result = ();
    $s->trigger('a');
    cmp_ok(int(@result), "==", 0, "If the resource is unavailable, it never calls the watcher callback, even if the resource has changed.");
    ok($w->active, 'watcher is still active');

    $w->cancel();
    cmp_ok(int($s->watchers), "==", 0, "No watcher.");
    ok(!$w->active, 'watcher is now inactive');
}

{
    note("--- register() to update the provider.");
    $s->register(
        a => sub {
            my ($in) = @_;
            return $res_a >= $in ? -$res_a : undef;
        }
    );
    @result = ();
    $res_a = 0;
    my $w = $s->watch(a => 5, sub {
        my ($w, %res) = @_;
        push(@result, $res{a});
        $w->cancel();
    });
    ok($w->active, "watcher is active");
    foreach (1 .. 10) {
        $res_a++;
        $s->trigger('a');
    }
    cmp_ok(int(@result), "==", 1, "got 1 result.");
    cmp_ok($result[0], "==", -5, "... and it's -5");
    ok(!$w->active, 'watcher is inactive.');
    checkCond($w, ['a'], {a => 5}, 'inactive watcher.');
}

note("--- unregister()");
is($s->unregister('a'), $s, "unregister() returns the object.");
cmp_ok(int($s->resources), '==', 0, "now no resource is registered.");
ok(!$s->registered('a'), 'a is not registered anymore');

done_testing();

