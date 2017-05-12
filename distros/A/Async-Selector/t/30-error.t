use strict;
use warnings;
use Test::More;
use Test::Builder;
use Test::Warn;
use Test::Exception;
use Async::Selector;

use FindBin;
use lib "$FindBin::RealBin/lib";
use Async::Selector::testutils;


note('Test for erroneous situations.');

sub catter {
    my ($result_ref, $one_shot) = @_;
    return sub {
        my ($w, %res) = @_;
        $$result_ref .= join ',', map { "$_:$res{$_}" } sort {$a cmp $b} keys %res;
        if($one_shot) {
            $w->cancel();
        }
    };
}

{
    note('--- watch() non-existent resource');
    my $s = new_ok('Async::Selector');
    $s->register("res" => sub { my $in = shift; return $in ? "RES" : undef });
    checkWNum $s, 0;
    my $result = "";
    warning_is { $s->watch(unknown => 100, catter(\$result, 1)) } undef, "No warning for selecting non-existent resource.";
    checkWNum $s, 1;
    warning_is { $s->watch(res => 1, unknown => 20, catter(\$result, 1)) } undef, "... neither when existent resource is selected as well.";
    checkWNum $s, 1;
    is($result, "res:RES", "existent resource is provided as usual.");
    $result = "";
    $s->register("unknown" => sub { return 10 });
    is($result, "", "The result is empty");
    $s->trigger("unknown");
    is($result, "unknown:10", "The result is now 'token' because the resource 'unknown' now exists and be triggered.");
    checkWNum $s, 0;
}

{
    note('--- watch() undef resource');
    my $s = new_ok('Async::Selector');
    my $result = "";
    checkWNum $s, 0;
    warning_like {$s->watch(undef, 100, res => 200, catter(\$result, 1))}
        qr/uninitialized/i, "Selecting undef is treated as selecting a resource named empty string.";
    checkWNum $s, 1;
    $s->register(res => sub { return "RES" }, "" => sub { return "EMPTY" });
    is($result, "", "result is empty before trigger");
    $result = "";
    checkWNum $s, 1;
    $s->trigger("res", "");
    checkWNum $s, 0;
    is($result, ":EMPTY,res:RES", "Got resource after the trigger. undef(empty) resource and 'res' resource.");
}

{
    note('--- watch() with invalid callback');
    my $s = new_ok('Async::Selector');
    my $msg = qr/must be a coderef/i;
    throws_ok {$s->watch(res => 100, undef)} $msg, "callback must not be undef";
    throws_ok {$s->watch(res => 100, "string")} $msg, "... or a string";
    throws_ok {$s->watch(res => 100, [1, 2, 10])} $msg, "... or an arrayref";
    throws_ok {$s->watch(res => 100, {hoge => "foo"})} $msg, "... or a hashref.";
    checkWNum $s, 0;
}

{
    note('--- watch() with no resource');
    my $s = new_ok('Async::Selector');
    my $watcher = undef;
    my @result = ();
    warning_is {$watcher = $s->watch(sub { push(@result, 'token'); return 0 })}
        undef, "watch() finishes with no warning even if it is supplied with no resource selection.";
    isa_ok($watcher, "Async::Selector::Watcher", '... it should still return a Watcher object.');
    ok(!$watcher->active, "... but the Watcher is already inactive.");
    ## ok(!defined($selection), "... it returns no selection object. selection is silently rejected.");
    is(int(@result), 0, "... callback is not executed, because the watch is rejected.");
    checkWNum $s, 0;

    @result = ();
    warning_is {$watcher = $s->watch_et(sub { push(@result, 'token'); return 0 })}
        undef, "The behavior is the same for watch_et().";
    isa_ok($watcher, "Async::Selector::Watcher", '... it should still return a Watcher object.');
    ok(!$watcher->active, "... but the Watcher is already inactive.");
    ## ok(!defined($selection), "... it returns no selection object.");
    is(int(@result), 0, "... callback is not executed, because the watch is rejected.");
    checkWNum $s, 0;
}

{
    note('--- watch() without callback');
    my $s = new_ok('Async::Selector');
    throws_ok { $s->watch(a => 10, b => 20) }
        qr/must be a coderef/i, 'Throw exception when watch() is called without callback';
    throws_ok { $s->watch() }
        qr/must be a coderef/i, 'Throw exception when watch() is called without any argument';
    note('--- -- what if condition input is a coderef?');
    warning_like { $s->watch(a => sub {10}) }
        qr(odd number)i, 'Warning from warning pragma when watch() is called without callback but condition input is a coderef';
    my $fired = 0;
    $s->register(a => sub {
        my ($in) = @_;
        $fired = 1;
        ok(!defined($in), "condition input is undef.");
        return 1;
    });
    is(int($s->watchers), 1, "watcher is alive");
    $s->trigger('a');
    is($fired, 1, "watcher fired.");
    is(int($s->watchers), 1, "watcher is alive. cancel() is not called in the watcher callback.");
}

{
    note('--- unregister() non-existent resource');
    my $s = new_ok('Async::Selector');
    $s->register(res => sub { return 'FOOBAR'});
    is(int($s->resources), 1, "one resource registered");
    warning_is { $s->unregister(qw(this does not exist)) } undef, "non-existent resources are silently ignored in unregister().";
    warning_is { $s->unregister(qw(unknown res)) } undef, "you can unregister() existent resource as well as non-existent one.";
    is(int($s->resources), 0, "no resource registered");
}

{
    note('--- unregister() undef resource');
    my $s = new_ok('Async::Selector');
    $s->register('res' => sub { return 10 });
    is(int($s->resources), 1, "One resource.");
    warning_is { $s->unregister(undef) } undef, "unregister(undef) is silently ignored.";
    is(int($s->resources), 1, "Still one resource.");
    warning_is { $s->unregister(undef, 'res') } undef, "unregister(undef, 'res'). undef is ignored.";
    is(int($s->resources), 0, "Unresgistered.");
}

{
    note('--- unregister() a resource multiple times.');
    my $s = new_ok('Async::Selector');
    $s->register('res' => sub { return 10 });
    is(int($s->resources), 1, "One resource.");
    warning_is { $s->unregister('res', 'res', 'res') } undef, "unregister() the same resource multiple times at once is no problem.";
    is(int($s->resources), 0, "Unregistered.");
}

{
    note('--- unregister() while watcher is active.');
    my $s = new_ok('Async::Selector');
    my $res = 0;
    $s->register('res' => sub { my $in = shift; return $res >= $in ? $res : undef });
    my $result = "";
    my @watchers = ();
    push @watchers, $s->watch('res' => 5, catter(\$result, 0));
    push @watchers, $s->watch('res' => 10, catter(\$result, 1));
    checkWNum $s, 2;
    warning_is { $s->unregister('res') } undef, "unregister() does not warn even when the deleted resource is now selected.";
    checkWNum $s, 2;
    $res = 100;
    $s->trigger('res');
    is($result, "", "Resource 'res' is no longer registered, so triggering it does no effect.");
    checkWNum $s, 2;
}

{
    note('--- register() with no resource');
    my $s = new_ok('Async::Selector');
    checkRNum $s, 0;
    warning_is { $s->register() } undef, "It's OK to call register() with no argument. It does nothing.";
    checkRNum $s, 0;
}

{
    note('--- register() undef resource');
    my $s = new_ok('Async::Selector');
    checkRNum $s, 0;
    warnings_like { $s->register(undef, sub { return 10 }) }
        qr/uninitialized/i, "undef resource causes warning, and it's treated as empty-named resource.";
    checkRNum $s, 1;
    is(($s->resources)[0], "", "Empty named resource");
    my $result = "";
    checkWNum $s, 0;
    $s->watch('', 10, catter(\$result, 1));
    is($result, ":10", "Get result from the watcher");
    checkWNum $s, 0;
}

{
    note('--- register() with invalid providers (undef, scalar, arrayref, hashref)');
    my $s = new_ok('Async::Selector');
    checkRNum $s, 0;
    throws_ok { $s->register(res => undef) } qr(must be coderef)i, "Resource provider must not be undef";
    throws_ok { $s->register(res => 'string') } qr(must be coderef)i, "... or a string";
    throws_ok { $s->register(res => [10, 20]) } qr(must be coderef)i, "... or an arrayref";
    throws_ok { $s->register(res => {foo => 'bar'}) } qr(must be coderef)i, "... or a hashref";
    checkRNum $s, 0;
}

{
    note('--- trigger() to non-existent resource');
    my $s = new_ok('Async::Selector');
    warning_is { $s->trigger(qw(this does not exist)) } undef, "trigger() non-existent resources is OK. Just ignored.";
    $s->watch(want => 10, sub { fail("Callback fired.") });
    checkWNum $s, 1;
    warning_is { $s->trigger(qw(that is not here)) } undef, "trigger() non-selected resource does not fire the watcher.";
}

{    
    note('--- trigger() undef and other junks ');
    my $s = new_ok('Async::Selector');
    my @result = ();
    $s->register(a => sub { 10 }, "" => sub { 20 });
    $s->watch_et(a => 0, sub {
        my ($w, %res) = @_;
        $result[0] = $res{a};
    });
    $s->watch_et("" => 0, sub {
        my ($w, %res) = @_;
        $result[1] = $res{''};
    });
    is(int(@result), 0, "not fired.");

    @result = ();
    warning_is { $s->trigger() } undef, "trigger() with no argument complains nothing and does nothing.";
    is_deeply(\@result, [], "not fired");

    @result = ();
    warning_is { $s->trigger(undef) } undef, "trigger ignores undef. no warning.";
    is_deeply(\@result, [], 'not fired');

    @result = ();
    warning_is { $s->trigger(11.02) } undef, 'trigger(number) complains nothing.';
    is_deeply(\@result, [], 'not fired');

    @result = ();
    warning_is { $s->trigger(sub {}, [], {}) } undef, 'triggering other junks complains nothing';
    is_deeply(\@result, [], 'not fired');

    @result = ();
    warning_is { $s->trigger('a', undef, 'a') } undef, 'trigger(..., undef, ...): undef is still ignored and no warning.';
    is_deeply(\@result, [10], 'fired');

    @result = ();
    warning_is { $s->trigger('b', undef, '', 'a') } undef, 'trigger(..., undef, "", ...): no warning';
    is_deeply(\@result, [10, 20], 'both fired');
}

{
    note('--- registered(junk)');
    my $s = Async::Selector->new();
    $s->register('' => sub {10}, a => sub {20}, 3 => sub {30});
    my $ret;
    foreach my $arg ('', 'a', 3) {
        warning_is { $ret = $s->registered($arg) } undef, "no warning for '$arg', of course";
        ok($ret, "'$arg' is registered");
    }
    warning_like { $ret = $s->registered(undef) } undef, "no warning for undef.";
    ok(!$ret, "undef is not registered");
    warning_is { $ret = $s->registered([]) } undef, "no warning for arrayref.";
    ok(!$ret, "arrayref is not registered");
    warning_is { $ret = $s->registered({}) } undef, "no warning for hashref.";
    ok(!$ret, "hashref is not registered");
    warning_is { $ret = $s->registered(sub {}) } undef, "no warning for coderef.";
    ok(!$ret, "coderef is not registered");
    warning_is { $ret = $s->registered() } undef, "no warning for no argument";
    ok(!$ret, "returns false for no argument.");
}

done_testing();
