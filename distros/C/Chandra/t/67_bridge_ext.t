#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Bridge::Extension');
use_ok('Chandra::Bridge');
use_ok('Chandra::App');

# clean slate
Chandra::Bridge::Extension->clear;

# ---- register / is_registered / source ----
{
    ok(Chandra::Bridge::Extension->register('utils', 'return { add: function(a,b) { return a+b; } };'),
        'register utils');
    ok(Chandra::Bridge::Extension->is_registered('utils'), 'is_registered utils');
    ok(!Chandra::Bridge::Extension->is_registered('nonexistent'), 'is_registered nonexistent false');

    my $src = Chandra::Bridge::Extension->source('utils');
    like($src, qr/add/, 'source contains expected code');
    is(Chandra::Bridge::Extension->source('nonexistent'), undef, 'source for unknown returns undef');
}

# ---- list ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('alpha', 'return {};');
    Chandra::Bridge::Extension->register('beta', 'return {};');

    my @list = Chandra::Bridge::Extension->list;
    is(scalar @list, 2, 'list returns 2 extensions');
    is($list[0], 'alpha', 'list order: alpha first');
    is($list[1], 'beta', 'list order: beta second');
}

# ---- dependency ordering ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('base', 'return { x: 1 };');
    Chandra::Bridge::Extension->register('child', 'return { y: 2 };', depends => ['base']);
    Chandra::Bridge::Extension->register('grandchild', 'return { z: 3 };', depends => ['child']);

    my @list = Chandra::Bridge::Extension->list;
    is(scalar @list, 3, 'dependency chain: 3 extensions');
    is($list[0], 'base', 'base first');
    is($list[1], 'child', 'child second');
    is($list[2], 'grandchild', 'grandchild third');
}

# ---- unregister ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('tmp', 'return {};');
    ok(Chandra::Bridge::Extension->is_registered('tmp'), 'tmp registered');
    ok(Chandra::Bridge::Extension->unregister('tmp'), 'unregister returns true');
    ok(!Chandra::Bridge::Extension->is_registered('tmp'), 'tmp gone after unregister');
    ok(!Chandra::Bridge::Extension->unregister('tmp'), 'unregister unknown returns false');
}

# ---- clear ----
{
    Chandra::Bridge::Extension->register('a', 'return {};');
    Chandra::Bridge::Extension->register('b', 'return {};');
    Chandra::Bridge::Extension->clear;
    my @list = Chandra::Bridge::Extension->list;
    is(scalar @list, 0, 'clear removes all');
}

# ---- generate_js ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('greet', 'return { hello: function() { return "hi"; } };');

    my $js = Chandra::Bridge::Extension->generate_js;
    like($js, qr/window\.chandra\.greet/, 'generate_js contains window.chandra.greet');
    like($js, qr/\(function\(\)/, 'generate_js wraps in IIFE');
    like($js, qr/hello/, 'generate_js contains source code');
}

# ---- generate_js_escaped ----
{
    my $escaped = Chandra::Bridge::Extension->generate_js_escaped;
    ok(defined $escaped, 'generate_js_escaped is defined');
    unlike($escaped, qr/\n/, 'escaped has no raw newlines');
}

# ---- bridge js_code includes extensions ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('myext', 'return { val: 42 };');

    my $bridge_js = Chandra::Bridge->js_code;
    like($bridge_js, qr/window\.chandra\.myext/, 'bridge js_code includes extension');
    like($bridge_js, qr/val: 42/, 'bridge js_code includes extension source');
    like($bridge_js, qr/window\.chandra\s*=\s*\{/, 'bridge js_code still has core bridge');
}

# ---- bridge js_code_escaped includes extensions ----
{
    my $escaped = Chandra::Bridge->js_code_escaped;
    like($escaped, qr/window\.chandra\.myext/, 'bridge js_code_escaped includes extension');
}

# ---- reserved name rejection ----
{
    Chandra::Bridge::Extension->clear;
    for my $reserved (qw(invoke call _resolve _event _eventData _callbacks _id)) {
        eval { Chandra::Bridge::Extension->register($reserved, 'return {};'); };
        like($@, qr/reserved/, "register '$reserved' croaks as reserved");
    }
}

# ---- register_file ----
{
    Chandra::Bridge::Extension->clear;
    use File::Temp qw(tempfile);
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.js', UNLINK => 1);
    print $fh 'return { fromFile: true };';
    close $fh;

    Chandra::Bridge::Extension->register_file('filed', $tmpfile);
    ok(Chandra::Bridge::Extension->is_registered('filed'), 'register_file works');
    like(Chandra::Bridge::Extension->source('filed'), qr/fromFile/, 'file source loaded');
}

# ---- App extend_bridge ----
{
    Chandra::Bridge::Extension->clear;
    my $app = Chandra::App->new(title => 'Test');
    $app->extend_bridge('helpers', 'return { aid: function() {} };');
    ok(Chandra::Bridge::Extension->is_registered('helpers'), 'extend_bridge registers extension');

    my $js = Chandra::Bridge->js_code;
    like($js, qr/window\.chandra\.helpers/, 'extend_bridge visible in bridge js_code');
}

# ---- no extensions gives clean bridge ----
{
    Chandra::Bridge::Extension->clear;
    my $js = Chandra::Bridge->js_code;
    unlike($js, qr/window\.chandra\.\w+\s*=\s*\(function/, 'no extensions = no extension IIFEs');
    like($js, qr/window\.chandra\s*=\s*\{/, 'core bridge still present');
}

done_testing();
