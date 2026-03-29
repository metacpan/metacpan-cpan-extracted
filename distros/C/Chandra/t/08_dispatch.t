#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra');
use_ok('Chandra::Bind');
use_ok('Chandra::Bridge');

# Test the full dispatch flow that Chandra::_dispatch uses
# without actually opening a window.

# --- Chandra->bind registers functions ---
{
    my $app = Chandra->new();
    $app->bind('greet', sub {
        my ($name) = @_;
        return "Hello, $name!";
    });
    ok(1, 'bind does not die');
    
    $app->bind('add', sub { $_[0] + $_[1] });
    ok(1, 'bind second function');
}

# --- Chandra->bind chaining ---
{
    my $app = Chandra->new();
    my $ret = $app->bind('f1', sub {})->bind('f2', sub {})->bind('f3', sub {});
    isa_ok($ret, 'Chandra', 'bind chaining returns Chandra object');
}

# --- Bind dispatch round-trip ---
{
    my $bind = Chandra::Bind->new();
    
    $bind->bind('greet', sub {
        my ($name) = @_;
        return "Hello, $name!";
    });
    
    # Simulate a JS call
    my $json = '{"type":"call","id":100,"method":"greet","args":["World"]}';
    my $result = $bind->dispatch($json);
    
    is($result->{id}, 100, 'dispatch result id');
    is($result->{result}, 'Hello, World!', 'dispatch result value');
    ok(!defined $result->{error}, 'no error');
    
    # Generate js_resolve
    my $js = $bind->js_resolve($result->{id}, $result->{result}, $result->{error});
    like($js, qr/window\.chandra\._resolve\(100/, 'js_resolve has correct id');
    like($js, qr/"Hello, World!"/, 'js_resolve has correct result');
    
    $bind->unbind('greet');
}

# --- Error round-trip ---
{
    my $bind = Chandra::Bind->new();
    
    $bind->bind('fail', sub { die "test error" });
    
    my $json = '{"type":"call","id":200,"method":"fail","args":[]}';
    my $result = $bind->dispatch($json);
    
    is($result->{id}, 200, 'error dispatch id');
    ok(defined $result->{error}, 'error present');
    like($result->{error}, qr/test error/, 'error message');
    
    my $js = $bind->js_resolve($result->{id}, $result->{result}, $result->{error});
    like($js, qr/_resolve\(200, null/, 'error resolve has null result');
    like($js, qr/test error/, 'error resolve has error message');
    
    $bind->unbind('fail');
}

# --- Event dispatch with data ---
{
    my $bind = Chandra::Bind->new();
    my ($got_type, $got_id, $got_val);
    
    $bind->bind('on_click', sub {
        my ($event) = @_;
        $got_type = $event->type;
        $got_id   = $event->target_id;
        $got_val  = $event->value;
    });
    
    my $json = '{"type":"event","handler":"on_click","event":{"type":"click","targetId":"myBtn","value":"clicked"}}';
    my $result = $bind->dispatch($json);
    
    is($result->{ok}, 1, 'event dispatch ok');
    is($got_type, 'click', 'event handler received type');
    is($got_id, 'myBtn', 'event handler received target_id');
    is($got_val, 'clicked', 'event handler received value');
    
    $bind->unbind('on_click');
}

# --- Sequential calls with incrementing IDs ---
{
    my $bind = Chandra::Bind->new();
    my $counter = 0;
    $bind->bind('inc', sub { return ++$counter });
    
    for my $i (1..5) {
        my $json = sprintf('{"type":"call","id":%d,"method":"inc","args":[]}', $i);
        my $r = $bind->dispatch($json);
        is($r->{id}, $i, "sequential call id $i");
        is($r->{result}, $i, "sequential call result $i");
    }
    
    $bind->unbind('inc');
}

# --- Full JSON encode/decode round-trip with special characters ---
{
    my $bind = Chandra::Bind->new();
    $bind->bind('echo', sub { return $_[0] });
    
    # String with quotes
    my $r = $bind->dispatch('{"type":"call","id":300,"method":"echo","args":["say \\"hello\\""]}');
    is($r->{result}, 'say "hello"', 'string with quotes');
    
    # String with backslash
    $r = $bind->dispatch('{"type":"call","id":301,"method":"echo","args":["path\\\\to\\\\file"]}');
    is($r->{result}, 'path\\to\\file', 'string with backslashes');
    
    $bind->unbind('echo');
}

done_testing();
