#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Bind');
use_ok('Chandra::Error');

# === encode_result with undef ===
{
    my $bind = Chandra::Bind->new;
    my $encoded = $bind->encode_result(undef);
    is($encoded, 'null', 'undef encodes to null');
}

# === encode_result with empty string ===
{
    my $bind = Chandra::Bind->new;
    my $encoded = $bind->encode_result('');
    is($encoded, '""', 'empty string encodes to ""');
}

# === encode_result with nested structure ===
{
    my $bind = Chandra::Bind->new;
    my $encoded = $bind->encode_result({ a => [1, { b => 'c' }] });
    like($encoded, qr/"a"/, 'nested structure encoded');
    like($encoded, qr/"b"/, 'inner hash encoded');
}

# === dispatch with missing args field ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('no_args_field', sub { return 'ok' });
    my $result = $bind->dispatch('{"type":"call","id":1,"method":"no_args_field"}');
    is($result->{result}, 'ok', 'dispatch works without args field');
    $bind->unbind('no_args_field');
}

# === dispatch with null args ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('null_args', sub { return scalar @_ });
    my $result = $bind->dispatch('{"type":"call","id":2,"method":"null_args","args":null}');
    is($result->{result}, 0, 'null args treated as empty array');
    $bind->unbind('null_args');
}

# === dispatch with args containing null values ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('null_in_args', sub { return defined $_[0] ? 'defined' : 'undef' });
    my $result = $bind->dispatch('{"type":"call","id":3,"method":"null_in_args","args":[null]}');
    is($result->{result}, 'undef', 'null arg passed as undef');
    $bind->unbind('null_in_args');
}

# === dispatch with empty JSON object ===
{
    my $bind = Chandra::Bind->new;
    my $result = $bind->dispatch('{}');
    is($result->{type}, 'raw', 'empty object treated as raw');
}

# === dispatch with unknown type ===
{
    my $bind = Chandra::Bind->new;
    my $result = $bind->dispatch('{"type":"unknown","data":"test"}');
    is($result->{type}, 'raw', 'unknown type treated as raw');
}

# === event dispatch with missing event field ===
{
    my $bind = Chandra::Bind->new;
    my $event_received;
    $bind->bind('_h_missing_event', sub { $event_received = $_[0] });
    my $result = $bind->dispatch('{"type":"event","handler":"_h_missing_event"}');
    ok($result->{ok}, 'event dispatch succeeds without event field');
    isa_ok($event_received, 'Chandra::Event', 'handler gets Event even without data');
    $bind->unbind('_h_missing_event');
}

# === event handler receives app reference ===
{
    my $mock_app = bless {}, 'MockBindApp';
    my $bind = Chandra::Bind->new(app => $mock_app);
    my $received_app;
    $bind->bind('_h_app_ref', sub { $received_app = $_[1] });
    $bind->dispatch('{"type":"event","handler":"_h_app_ref","event":{"type":"click"}}');
    is($received_app, $mock_app, 'event handler receives app reference');
    $bind->unbind('_h_app_ref');
}

# === event handler that dies captures error ===
{
    Chandra::Error->clear_handlers;
    my $captured;
    Chandra::Error->on_error(sub { $captured = $_[0] });

    my $bind = Chandra::Bind->new;
    $bind->bind('_h_dying', sub { die "event handler crash" });
    my $result = $bind->dispatch('{"type":"event","handler":"_h_dying","event":{}}');
    ok(exists $result->{error}, 'error returned from dying event handler');
    like($result->{error}, qr/event handler crash/, 'error message preserved');
    ok($captured, 'error was captured via Error module');
    like($captured->{context}, qr/event\(_h_dying\)/, 'error context mentions handler');

    $bind->unbind('_h_dying');
    Chandra::Error->clear_handlers;
}

# === bind returns self for chaining ===
{
    my $bind = Chandra::Bind->new;
    my $ret = $bind->bind('chain1', sub { });
    is($ret, $bind, 'bind returns self');
    $bind->unbind('chain1');
}

# === unbind returns self for chaining ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('chain2', sub { });
    my $ret = $bind->unbind('chain2');
    is($ret, $bind, 'unbind returns self');
}

# === unbind non-existent is safe ===
{
    my $bind = Chandra::Bind->new;
    eval { $bind->unbind('never_existed') };
    is($@, '', 'unbinding non-existent function is safe');
}

# === js_resolve with undef result ===
{
    my $bind = Chandra::Bind->new;
    my $js = $bind->js_resolve(10, undef);
    like($js, qr/_resolve\(10/, 'ID in resolve');
    like($js, qr/null/, 'undef result becomes null');
}

# === js_resolve with string result ===
{
    my $bind = Chandra::Bind->new;
    my $js = $bind->js_resolve(11, 'hello world');
    like($js, qr/hello world/, 'string result in resolve JS');
}

# === js_resolve with array result ===
{
    my $bind = Chandra::Bind->new;
    my $js = $bind->js_resolve(12, [1, 2, 3]);
    like($js, qr/\[1,2,3\]/, 'array result in resolve JS');
}

# === handler returning complex result ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('complex_return', sub {
        return { list => [1, 2], nested => { key => 'val' } };
    });
    my $result = $bind->dispatch('{"type":"call","id":20,"method":"complex_return","args":[]}');
    is_deeply($result->{result}{list}, [1, 2], 'complex return: array');
    is($result->{result}{nested}{key}, 'val', 'complex return: nested hash');
    $bind->unbind('complex_return');
}

# === handler with multiple args ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('multi_args', sub { return join('-', @_) });
    my $result = $bind->dispatch('{"type":"call","id":21,"method":"multi_args","args":["a","b","c"]}');
    is($result->{result}, 'a-b-c', 'multiple args passed correctly');
    $bind->unbind('multi_args');
}

# === call dispatch error includes id ===
{
    my $bind = Chandra::Bind->new;
    $bind->bind('error_with_id', sub { die "boom" });
    my $result = $bind->dispatch('{"type":"call","id":42,"method":"error_with_id","args":[]}');
    is($result->{id}, 42, 'error response preserves request ID');
    $bind->unbind('error_with_id');
}

# === dispatch with numeric-only JSON ===
{
    my $bind = Chandra::Bind->new;
    my $result = $bind->dispatch('42');
    is($result->{type}, 'raw', 'numeric JSON treated as raw');
}

# === dispatch with JSON string ===
{
    my $bind = Chandra::Bind->new;
    my $result = $bind->dispatch('"just a string"');
    is($result->{type}, 'raw', 'string JSON treated as raw');
}

done_testing;
