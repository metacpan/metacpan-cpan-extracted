
use strict;
use warnings;
use Test::More;

note("Test for 1-resource 1-selection.");

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

note("--- LT select, auto-remove, not immediate.");
my @result = ();
ok(defined($s->select(
    sub {
        my ($id, %res) = @_;
        cmp_ok(int(keys %res), "==", 1, "selected one resource.");
        ok(defined($res{a}), "resource a is available.");
        push(@result, $res{a});
        return 1;
    }, a => 5)), "select() returns some value if the request is pending."
);


foreach (0 .. 4) {
    is($s->trigger('a'), $s, 'trigger() method returns the object.');
    cmp_ok(int(@result), "==", 0, 'no entry in result yet.');
    $res_a++;
}
cmp_ok($res_a, '==', 5, "now res_a is 5.");
$s->trigger('a');
cmp_ok(int(@result), '==', 1, 'one result has arrived!');
cmp_ok((shift @result), '==', $res_a, "... and it's $res_a.");

$s->trigger('a');
cmp_ok(int(@result), "==", 0, "no result anymore, because the selection was removed.");

note("--- LT select, auto-remove, immediate fire.");
ok(!defined($s->select(
    sub {
        my ($id, %res) = @_;
        push(@result, $res{a});
        return 1;
    }, a => 3)), "select() returns undef if the request is handled immediately."
);
cmp_ok(int(@result), "==", 1, "get a result without trigger()");
is((shift @result), $res_a, "... and it's $res_a");

{
    note("--- LT select, non-remove, not immediate.");
    @result = ();
    my $id = $s->select(
        sub {
            my ($id, %res) = @_;
            push(@result, $res{a});
            return 0;
        }, a => 10
    );
    ok(defined($id), "select() method returns defined ID");
    {
        my @selections = $s->selections;
        is(int(@selections), 1, "Currently 1 selection.");
        is($selections[0], $id, "... and it's $id.");
    }
    $res_a = 9; $s->trigger('a');
    cmp_ok(int(@result), "==", 0, "no result.");
    $res_a = 10; $s->trigger('a');
    cmp_ok(int(@result), "==", 1, "got a result.");
    is((shift @result), $res_a, "... and is $res_a");
    $s->trigger('a') foreach 1..3;
    cmp_ok(int(@result), "==", 3, "every call to trigger() kicks the selection callback repeatedly.");
    is($_, $res_a, "... the result is $res_a") foreach @result;
    @result = ();
    
    note("--- -- cancel() operation.");
    is($s->cancel($id), $s, "cancel() returns the object.");
    $s->trigger('a') foreach 1..3;
    cmp_ok(int(@result), "==", 0, "no result because the selection is canceled.");
    is(int($s->selections), 0, "no selections");
}

{
    note("--- LT select, non-remove, immediate.");
    @result = ();
    $res_a = 20;
    my $id = $s->select_lt(
        sub {
            my ($id, %res) = @_;
            push(@result, $res{a});
            return 0;
        }, a => 1
    );
    is(int($s->selections), 1, "One selection");
    is(($s->selections)[0], $id, "... and it's $id.");
    foreach (1 .. 3) {
        cmp_ok(int(@result), "==", 1, "got result immediately.");
        is($result[0], $res_a, "... and it's $res_a");
        @result = ();
        $s->trigger('a');
    }
    @result = ();
    note("--- -- cancel() operation.");
    $s->cancel($id);
    is(int($s->selections), 0, "No selection");
    $s->trigger('a');
    $s->trigger('a');
    cmp_ok(int(@result), "==", 0, "got no result because selection is canceled.");
}

{
    note("--- ET select, auto-remove, forcibly not immediate.");
    @result = ();
    $res_a = 5;
    my $id = $s->select_et(
        sub {
            my ($id, %res) = @_;
            push(@result, $res{a});
            return 1;
        }, a => 1
    );
    is(int($s->selections), 1, "One selection");
    is(($s->selections)[0], $id, "... and it's $id.");
    cmp_ok(int(@result), "==", 0, "got no result because it's edge-triggered.");
    $s->trigger('a');
    cmp_ok(int(@result), "==", 1, "got a result when triggerred.");
    is($result[0], $res_a, "... and is $res_a");
    @result = ();
    $s->trigger('a');
    cmp_ok(int(@result), "==", 0, "selection has been automatically removed.");
}

{
    note("--- ET select, non-remove, forcibly not immediate.");
    @result = ();
    $res_a = 0;
    my $id = $s->select_et(
        sub {
            my ($id, %res) = @_;
            push(@result, $res{a});
            return 0;
        }, a => 5
    );
    cmp_ok(int(@result), "==", 0, "got no result because it's edge-triggered.");
    $res_a = 10;
    $s->trigger('a');
    cmp_ok(int(@result), "==", 1, "got a result");
    is($result[0], $res_a, "... and is $res_a");
    @result = ();
    $s->trigger('a');
    cmp_ok($result[0], "==", $res_a, "callback executed for every trigger, even if the resource is not changed actually.");
    
    $res_a = 0;
    @result = ();
    $s->trigger('a');
    cmp_ok(int(@result), "==", 0, "If the resource is unavailable, it never calls the selection callback, even if the resource has changed.");

    $s->cancel($id);
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
    $s->select(
        sub {
            my ($id, %res) = @_;
            push(@result, $res{a});
            return 1;
        }, a => 5
    );
    foreach (1 .. 10) {
        $res_a++;
        $s->trigger('a');
    }
    cmp_ok(int(@result), "==", 1, "got 1 result.");
    cmp_ok($result[0], "==", -5, "... and it's -5");
}

note("--- unregister()");
is($s->unregister('a'), $s, "unregister() returns the object.");
cmp_ok(int($s->resources), '==', 0, "now no resource is registered.");

done_testing();

