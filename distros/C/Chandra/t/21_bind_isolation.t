#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Bind');

# Helper to build dispatch JSON
sub _call_json {
    my ($id, $method, @args) = @_;
    my $args_str = '[' . join(',', map {
        ref $_ ? Cpanel::JSON::XS::encode_json($_)
               : defined $_ ? (looks_like_number($_) ? $_ : qq{"$_"})
               : 'null'
    } @args) . ']';
    return qq|{"type":"call","id":$id,"method":"$method","args":$args_str}|;
}

sub looks_like_number {
    return $_[0] =~ /^-?\d+(\.\d+)?$/;
}

use Cpanel::JSON::XS ();
my $json = Cpanel::JSON::XS->new->utf8->allow_nonref;

# === Global registry is shared across instances ===
{
    my $bind1 = Chandra::Bind->new;
    my $bind2 = Chandra::Bind->new;

    $bind1->bind('shared_func', sub { 'from bind1' });
    ok($bind2->is_bound('shared_func'), 'bind2 sees bind1 registration');

    my @list = $bind2->list;
    ok(grep({ $_ eq 'shared_func' } @list), 'shared_func in bind2 list');

    $bind1->unbind('shared_func');
}

# === Unbinding in one instance affects all ===
{
    my $bind1 = Chandra::Bind->new;
    my $bind2 = Chandra::Bind->new;

    $bind1->bind('to_unbind', sub { 'x' });
    ok($bind2->is_bound('to_unbind'), 'visible before unbind');

    $bind1->unbind('to_unbind');
    ok(!$bind2->is_bound('to_unbind'), 'gone after unbind');
}

# === Dispatch works across instances ===
{
    my $bind1 = Chandra::Bind->new;
    my $bind2 = Chandra::Bind->new;

    $bind1->bind('cross_dispatch', sub { return $_[0] * 2 });
    my $result = $bind2->dispatch('{"type":"call","id":1,"method":"cross_dispatch","args":[5]}');
    is($result->{result}, 10, 'dispatch across instances works');

    $bind1->unbind('cross_dispatch');
}

# === Rebinding replaces handler globally ===
{
    my $bind1 = Chandra::Bind->new;
    my $bind2 = Chandra::Bind->new;

    $bind1->bind('rebind_test', sub { 'original' });
    $bind2->bind('rebind_test', sub { 'replaced' });

    my $result = $bind1->dispatch('{"type":"call","id":2,"method":"rebind_test","args":[]}');
    is($result->{result}, 'replaced', 'rebind replaces handler globally');

    $bind1->unbind('rebind_test');
}

# === Dispatch with various argument types ===
{
    my $bind = Chandra::Bind->new;

    $bind->bind('type_test', sub {
        my ($str, $num, $bool, $arr, $obj) = @_;
        return {
            str => $str,
            num => $num,
            bool => $bool,
            arr => $arr,
            obj => $obj,
        };
    });

    my $result = $bind->dispatch('{"type":"call","id":3,"method":"type_test","args":["hello",42,true,[1,2],{"key":"val"}]}');
    is($result->{result}{str}, 'hello', 'string arg preserved');
    is($result->{result}{num}, 42, 'numeric arg preserved');
    is_deeply($result->{result}{arr}, [1, 2], 'array arg preserved');
    is_deeply($result->{result}{obj}, { key => 'val' }, 'object arg preserved');

    $bind->unbind('type_test');
}

# === Dispatch with empty args ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('no_args', sub { return 'ok' });
    my $result = $bind->dispatch('{"type":"call","id":4,"method":"no_args","args":[]}');
    is($result->{result}, 'ok', 'dispatch with empty args');

    $bind->unbind('no_args');
}

# === Dispatch with malformed JSON ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('bad_json', sub { return 'should not reach' });
    my $result = $bind->dispatch('not json at all');
    ok(defined $result, 'malformed JSON handled');
    ok(exists $result->{error}, 'error key present for bad JSON');

    $bind->unbind('bad_json');
}

# === Dispatch to unregistered function ===
{
    my $bind = Chandra::Bind->new;
    my $result = $bind->dispatch('{"type":"call","id":5,"method":"nonexistent","args":[]}');
    ok(defined $result, 'dispatch to unregistered returns something');
    ok(exists $result->{error}, 'error key for unknown method');
    like($result->{error}, qr/Unknown method/, 'error message for unknown method');
}

# === Bind validation - name required ===
{
    my $bind = Chandra::Bind->new;
    eval { $bind->bind(undef, sub { }) };
    like($@, qr/name/, 'bind requires name');
}

# === Bind validation - handler required ===
{
    my $bind = Chandra::Bind->new;
    eval { $bind->bind('valid_name', undef) };
    like($@, qr/coderef/, 'bind requires handler');
}

# === Bind validation - handler must be coderef ===
{
    my $bind = Chandra::Bind->new;
    eval { $bind->bind('valid_name', 'not a sub') };
    like($@, qr/coderef/, 'bind requires coderef handler');
}

# === list returns names ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('zzz_last', sub { });
    $bind->bind('aaa_first', sub { });

    my @list = $bind->list;
    my @our_funcs = grep { /^(aaa_first|zzz_last)$/ } @list;
    is(scalar @our_funcs, 2, 'both functions listed');

    $bind->unbind('zzz_last');
    $bind->unbind('aaa_first');
}

# === js_resolve with numeric ID ===
{
    my $bind = Chandra::Bind->new;
    my $js = $bind->js_resolve(123, { status => 'ok' });
    ok(defined $js, 'js_resolve returns something');
    like($js, qr/123/, 'request ID in resolve JS');
    like($js, qr/_resolve/, 'resolve function called');
    like($js, qr/status/, 'result encoded');
}

# === js_resolve with error ===
{
    my $bind = Chandra::Bind->new;
    my $js = $bind->js_resolve(456, undef, 'something failed');
    like($js, qr/456/, 'ID in error resolve');
    like($js, qr/something failed/, 'error message in resolve');
    like($js, qr/null/, 'result is null on error');
}

# === encode_result with various types ===
{
    my $bind = Chandra::Bind->new;

    my $str = $bind->encode_result("hello");
    like($str, qr/hello/, 'string encoded');

    my $num = $bind->encode_result(42);
    like($num, qr/42/, 'number encoded');

    my $arr = $bind->encode_result([1, 2, 3]);
    like($arr, qr/\[1,2,3\]/, 'array encoded');

    my $hash = $bind->encode_result({ key => 'val' });
    like($hash, qr/"key"/, 'hash encoded');
}

# === Handler that dies is caught ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('dies_func', sub { die "handler crash" });
    my $result = $bind->dispatch('{"type":"call","id":6,"method":"dies_func","args":[]}');
    ok(defined $result, 'dispatch catches handler die');
    ok(exists $result->{error}, 'error key present');
    like($result->{error}, qr/handler crash/, 'error message from handler');

    $bind->unbind('dies_func');
}

# === Handler returning undef ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('undef_func', sub { return undef });
    my $result = $bind->dispatch('{"type":"call","id":7,"method":"undef_func","args":[]}');
    ok(defined $result, 'dispatch handles undef return');
    is($result->{id}, 7, 'response ID matches request');
    ok(!exists $result->{error} || !defined $result->{error}, 'no error for undef return');

    $bind->unbind('undef_func');
}

# === Event dispatch ===
{
    my $bind = Chandra::Bind->new;
    my @received_events;
    $bind->bind('_h_test_event', sub {
        my ($event) = @_;
        push @received_events, $event;
    });

    my $result = $bind->dispatch('{"type":"event","handler":"_h_test_event","event":{"type":"click","targetId":"btn1"}}');
    ok(defined $result, 'event dispatch returns result');
    is(scalar @received_events, 1, 'event handler called');
    isa_ok($received_events[0], 'Chandra::Event', 'handler receives Event object');
    is($received_events[0]->type, 'click', 'event type correct');
    is($received_events[0]->target_id, 'btn1', 'event target_id correct');

    $bind->unbind('_h_test_event');
}

# === Event dispatch to unknown handler ===
{
    my $bind = Chandra::Bind->new;
    my $result = $bind->dispatch('{"type":"event","handler":"_h_nonexistent","event":{}}');
    ok(exists $result->{error}, 'error for unknown event handler');
}

# === register_handler class method ===
{
    Chandra::Bind->register_handler('_direct_reg', sub { 'direct' });
    my $bind = Chandra::Bind->new;
    ok($bind->is_bound('_direct_reg'), 'register_handler makes it visible');

    my $result = $bind->dispatch('{"type":"call","id":8,"method":"_direct_reg","args":[]}');
    is($result->{result}, 'direct', 'directly registered handler works');

    $bind->unbind('_direct_reg');
}

# === Dispatch with missing type defaults to raw ===
{
    my $bind = Chandra::Bind->new;
    my $result = $bind->dispatch('{"data":"something"}');
    ok(defined $result, 'dispatch without type returns result');
    is($result->{type}, 'raw', 'unknown type treated as raw');
}

# === Dispatch response includes request ID ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('id_test', sub { 'result' });
    my $result = $bind->dispatch('{"type":"call","id":999,"method":"id_test","args":[]}');
    is($result->{id}, 999, 'response ID matches request ID');

    $bind->unbind('id_test');
}

done_testing;
