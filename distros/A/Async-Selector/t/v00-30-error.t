use strict;
use warnings;
use Test::More;
use Test::Builder;
use Test::Warn;
use Test::Exception;
use Async::Selector;

note('Test for erroneous situations.');

sub catter {
    my ($result_ref, $ret_val) = @_;
    return sub {
        my ($id, %res) = @_;
        $$result_ref .= join ',', map { "$_:$res{$_}" } sort {$a cmp $b} grep { defined($res{$_}) } keys %res;
        return $ret_val;
    };
}

sub checkSNum {
    my ($selector, $selection_num) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is(int($selector->selections), $selection_num, "$selection_num selections.");
}

sub checkRNum {
    my ($selector, $resource_num) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is(int($selector->resources), $resource_num, "$resource_num resources.");
}


{
    note('--- select() non-existent resource');
    my $s = new_ok('Async::Selector');
    $s->register("res" => sub { my $in = shift; return $in ? "RES" : undef });
    checkSNum $s, 0;
    my $result = "";
    warning_is { $s->select(catter(\$result, 1), unknown => 100) } undef, "No warning for selecting non-existent resource.";
    checkSNum $s, 1;
    warning_is { $s->select(sub { return 1 }, res => 1, unknown => 20) } undef, "... neither when existent resource is selected as well.";
    checkSNum $s, 1;
    $s->register("unknown" => sub { return 10 });
    is($result, "", "The result is empty");
    $s->trigger("unknown");
    is($result, "unknown:10", "The result is now 'token' because the resource 'unknown' now exists and be triggered.");
    checkSNum $s, 0;
}

{
    note('--- select() undef resource');
    my $s = new_ok('Async::Selector');
    my $result = "";
    checkSNum $s, 0;
    warning_like {$s->select(catter(\$result, 1), undef, 100, res => 200)}
        qr/uninitialized/i, "Selecting undef is treated as selecting a resource named empty string.";
    checkSNum $s, 1;
    $s->register(res => sub { return "RES" }, "" => sub { return "EMPTY" });
    is($result, "", "result is empty before trigger");
    $result = "";
    checkSNum $s, 1;
    $s->trigger("res", "");
    checkSNum $s, 0;
    is($result, ":EMPTY,res:RES", "Got resource after the trigger. undef(empty) resource and 'res' resource.");
}

{
    note('--- select() with invalid callback');
    my $s = new_ok('Async::Selector');
    my $msg = qr/must be a coderef/i;
    throws_ok {$s->select(undef, res => 100)} $msg, "callback must not be undef";
    throws_ok {$s->select("string", res => 100)} $msg, "... or a string";
    throws_ok {$s->select([1, 2, 10], res => 100)} $msg, "... or an arrayref";
    throws_ok {$s->select({hoge => "foo"})} $msg, "... or a hashref.";
    checkSNum $s, 0;
}

{
    note('--- select() with no resource');
    my $s = new_ok('Async::Selector');
    my $id = undef;
    my @result = ();
    warning_is {$id = $s->select(sub { push(@result, 'token'); return 0 })}
        undef, "select() finishes with no warning even if it is supplied with no resource selection.";
    ok(!defined($id), "... it returns no selection ID. selection is silently rejected.");
    is(int(@result), 0, "... callback is not executed, because the selection is rejected.");
    checkSNum $s, 0;

    @result = ();
    warning_is {$id = $s->select_et(sub { push(@result, 'token'); return 0 })}
        undef, "The behavior is the same for select_et().";
    ok(!defined($id), "... it returns no selection ID.");
    is(int(@result), 0, "... callback is not executed, because the selection is rejected.");
    checkSNum $s, 0;
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
    note('--- unregister() while selection is active.');
    my $s = new_ok('Async::Selector');
    my $res = 0;
    $s->register('res' => sub { my $in = shift; return $res >= $in ? $res : undef });
    my $result = "";
    my @ids = ();
    push @ids, $s->select(catter(\$result, 0), 'res' => 5);
    push @ids, $s->select(catter(\$result, 1), 'res' => 10);
    checkSNum $s, 2;
    warning_is { $s->unregister('res') } undef, "unregister() does not warn even when the deleted resource is now selected.";
    checkSNum $s, 2;
    $res = 100;
    $s->trigger('res');
    is($result, "", "Resource 'res' is no longer registered, so triggering it does no effect.");
    checkSNum $s, 2;
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
    checkSNum $s, 0;
    $s->select(catter(\$result, 1), '', 10);
    is($result, ":10", "Get result from a selection");
    checkSNum $s, 0;
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
    $s->select(sub { warn "Callback fired."; return 0 }, want => 10);
    checkSNum $s, 1;
    warning_is { $s->trigger(qw(that does not here)) } undef, "trigger() non-selected resource does not fire selection.";
    
    note('--- trigger() nothing');
    warning_is { $s->trigger() } undef, "trigger() with no argument is OK (but meaningless).";
}

{
    note('--- cancel() undef selection');
    my $s = new_ok('Async::Selector');
    warning_is { $s->cancel(undef, undef, undef) } undef, "cancel(undef) is OK.";
    my $id = $s->select(sub { warn "Callback fired."; return 1 }, want => 10);
    checkSNum $s, 1;
    is(($s->selections)[0], $id, "selection ID is $id.");
    warning_is { $s->cancel(undef) } undef, "cancel(undef) does nothing.";
    checkSNum $s, 1;
    note('--- cancel() multiple times');
    warning_is { $s->cancel($id, $id, $id) } undef, "It's OK to cancel() the same ID multiple times at once.";
    checkSNum $s, 0;
    warning_is { $s->cancel($id, 'this', "not", "exists") } undef, "cancel() non-existent IDs  is OK. Ignored.";
}

done_testing();
