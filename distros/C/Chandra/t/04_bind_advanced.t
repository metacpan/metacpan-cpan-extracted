#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Bind');
use_ok('Chandra::Event');

my $bind = Chandra::Bind->new();

# --- list() ---
{
    is_deeply([sort $bind->list], [], 'list() empty initially');

    $bind->bind('alpha', sub { 'a' });
    $bind->bind('beta', sub { 'b' });
    $bind->bind('gamma', sub { 'g' });

    my @listed = sort $bind->list;
    is_deeply(\@listed, [qw(alpha beta gamma)], 'list() returns all bound names');

    $bind->unbind('beta');
    @listed = sort $bind->list;
    is_deeply(\@listed, [qw(alpha gamma)], 'list() updated after unbind');

    # cleanup
    $bind->unbind('alpha');
    $bind->unbind('gamma');
}

# --- rebinding a function ---
{
    $bind->bind('rebind_me', sub { 'old' });
    my $json = '{"type":"call","id":10,"method":"rebind_me","args":[]}';
    my $r = $bind->dispatch($json);
    is($r->{result}, 'old', 'original binding returns old');

    $bind->bind('rebind_me', sub { 'new' });
    $r = $bind->dispatch($json);
    is($r->{result}, 'new', 'rebinding replaces function');
    ok($bind->is_bound('rebind_me'), 'still bound after rebind');

    $bind->unbind('rebind_me');
}

# --- bind validation ---
{
    eval { $bind->bind(undef, sub {}) };
    like($@, qr/requires a name/, 'bind undef name dies');

    eval { $bind->bind('foo', 'not_a_coderef') };
    like($@, qr/requires a coderef/, 'bind non-coderef dies');

    eval { $bind->bind('foo', undef) };
    like($@, qr/requires a coderef/, 'bind undef sub dies');
}

# --- unbind nonexistent (should not die) ---
{
    eval { $bind->unbind('does_not_exist') };
    is($@, '', 'unbind nonexistent does not die');
}

# --- dispatch with various arg types ---
{
    $bind->bind('echo', sub { return $_[0] });

    # string arg
    my $r = $bind->dispatch('{"type":"call","id":20,"method":"echo","args":["hello"]}');
    is($r->{result}, 'hello', 'string arg passed through');

    # numeric arg
    $r = $bind->dispatch('{"type":"call","id":21,"method":"echo","args":[42]}');
    is($r->{result}, 42, 'numeric arg passed through');

    # null arg
    $r = $bind->dispatch('{"type":"call","id":22,"method":"echo","args":[null]}');
    is($r->{result}, undef, 'null arg becomes undef');

    # boolean
    $r = $bind->dispatch('{"type":"call","id":23,"method":"echo","args":[true]}');
    ok($r->{result}, 'true arg is truthy');

    $bind->unbind('echo');
}

# --- dispatch with multiple args ---
{
    $bind->bind('multi', sub { return join('-', @_) });

    my $r = $bind->dispatch('{"type":"call","id":30,"method":"multi","args":["a","b","c"]}');
    is($r->{result}, 'a-b-c', 'multiple args passed');

    $bind->unbind('multi');
}

# --- dispatch with no args field ---
{
    $bind->bind('noargs', sub { return 'ok' });

    my $r = $bind->dispatch('{"type":"call","id":31,"method":"noargs"}');
    is($r->{result}, 'ok', 'missing args field defaults to empty');

    $bind->unbind('noargs');
}

# --- dispatch with complex return values ---
{
    $bind->bind('hash_return', sub { return { key => 'value', num => 42 } });
    my $r = $bind->dispatch('{"type":"call","id":40,"method":"hash_return","args":[]}');
    is_deeply($r->{result}, { key => 'value', num => 42 }, 'hash return value');

    $bind->bind('array_return', sub { return [1, 2, 3] });
    $r = $bind->dispatch('{"type":"call","id":41,"method":"array_return","args":[]}');
    is_deeply($r->{result}, [1, 2, 3], 'array return value');

    $bind->bind('undef_return', sub { return undef });
    $r = $bind->dispatch('{"type":"call","id":42,"method":"undef_return","args":[]}');
    is($r->{result}, undef, 'undef return value');

    $bind->unbind('hash_return');
    $bind->unbind('array_return');
    $bind->unbind('undef_return');
}

# --- dispatch: function that dies ---
{
    $bind->bind('die_func', sub { die "something went wrong" });
    my $r = $bind->dispatch('{"type":"call","id":50,"method":"die_func","args":[]}');
    is($r->{id}, 50, 'error dispatch has correct id');
    ok(defined $r->{error}, 'error is set when function dies');
    like($r->{error}, qr/something went wrong/, 'error message captured');

    $bind->unbind('die_func');
}

# --- dispatch: invalid JSON ---
{
    my $r = $bind->dispatch('not valid json{{{');
    ok(defined $r->{error}, 'invalid JSON returns error');
    like($r->{error}, qr/Invalid JSON/i, 'error mentions invalid JSON');
}

# --- dispatch: unknown type ---
{
    my $r = $bind->dispatch('{"type":"unknown_type","data":"test"}');
    is($r->{type}, 'raw', 'unknown type returns raw');
    ok(defined $r->{data}, 'raw data present');
}

# --- dispatch: empty type ---
{
    my $r = $bind->dispatch('{"id":60,"method":"x"}');
    is($r->{type}, 'raw', 'missing type treated as raw');
}

# --- event dispatch ---
{
    my $received_event;
    $bind->bind('click_handler', sub {
        my ($event, $app) = @_;
        $received_event = $event;
    });

    my $event_json = '{"type":"event","handler":"click_handler","event":{"type":"click","targetId":"btn1","value":"test_val"}}';
    my $r = $bind->dispatch($event_json);

    is($r->{ok}, 1, 'event dispatch returns ok');
    isa_ok($received_event, 'Chandra::Event');
    is($received_event->type, 'click', 'event type from dispatch');
    is($received_event->target_id, 'btn1', 'event target_id from dispatch');
    is($received_event->value, 'test_val', 'event value from dispatch');

    $bind->unbind('click_handler');
}

# --- event dispatch with unknown handler ---
{
    my $event_json = '{"type":"event","handler":"nonexistent_handler","event":{}}';
    my $r = $bind->dispatch($event_json);
    ok(defined $r->{error}, 'event with unknown handler returns error');
    like($r->{error}, qr/Unknown handler/, 'error mentions unknown handler');
}

# --- event handler that dies ---
{
    $bind->bind('bad_handler', sub { die "handler boom" });
    my $event_json = '{"type":"event","handler":"bad_handler","event":{"type":"click"}}';
    my $r = $bind->dispatch($event_json);
    ok(defined $r->{error}, 'dying event handler returns error');
    like($r->{error}, qr/handler boom/, 'event handler error captured');

    $bind->unbind('bad_handler');
}

# --- js_resolve ---
{
    my $js = $bind->js_resolve(1, 'hello', undef);
    like($js, qr/window\.chandra\._resolve/, 'js_resolve contains _resolve call');
    like($js, qr/\b1\b/, 'js_resolve contains id');
    like($js, qr/"hello"/, 'js_resolve contains result');

    # error case
    $js = $bind->js_resolve(2, undef, 'oops');
    like($js, qr/"oops"/, 'js_resolve error case contains error');
    like($js, qr/null/, 'js_resolve error case has null for result');
}

# --- encode_result ---
{
    my $encoded = $bind->encode_result({ id => 1, result => 'ok' });
    like($encoded, qr/"id"/, 'encode_result produces JSON with id');
    like($encoded, qr/"result"/, 'encode_result produces JSON with result');
}

# --- bind returns self for chaining ---
{
    my $ret = $bind->bind('chain1', sub {});
    is($ret, $bind, 'bind returns self');
    $ret = $bind->unbind('chain1');
    is($ret, $bind, 'unbind returns self');
}

done_testing();
