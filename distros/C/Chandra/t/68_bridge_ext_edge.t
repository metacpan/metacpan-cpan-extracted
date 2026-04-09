#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Bridge::Extension');
use_ok('Chandra::Bridge');

# clean slate
Chandra::Bridge::Extension->clear;

# ---- circular dependency ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('ca', 'return {};', depends => ['cb']);
    Chandra::Bridge::Extension->register('cb', 'return {};', depends => ['ca']);

    eval { Chandra::Bridge::Extension->list; };
    like($@, qr/circular/i, 'circular dependency detected');

    eval { Chandra::Bridge->js_code; };
    like($@, qr/circular/i, 'circular dependency in js_code croaks');

    Chandra::Bridge::Extension->clear;
}

# ---- missing dependency ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('orphan', 'return {};', depends => ['ghost']);

    eval { Chandra::Bridge::Extension->list; };
    like($@, qr/unknown extension/i, 'missing dependency detected');

    Chandra::Bridge::Extension->clear;
}

# ---- duplicate registration (overwrite) ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('dup', 'return { v: 1 };');
    is(Chandra::Bridge::Extension->source('dup'), 'return { v: 1 };', 'first registration');

    Chandra::Bridge::Extension->register('dup', 'return { v: 2 };');
    is(Chandra::Bridge::Extension->source('dup'), 'return { v: 2 };', 'overwrite works');

    my @list = Chandra::Bridge::Extension->list;
    is(scalar @list, 1, 'overwrite does not duplicate');
}

# ---- empty source ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('empty', '');
    ok(Chandra::Bridge::Extension->is_registered('empty'), 'empty source registers');
    is(Chandra::Bridge::Extension->source('empty'), '', 'empty source is empty string');

    my $js = Chandra::Bridge::Extension->generate_js;
    like($js, qr/window\.chandra\.empty/, 'empty source still produces IIFE');
}

# ---- very large JS source ----
{
    Chandra::Bridge::Extension->clear;
    my $big = 'var x = ' . ('"a"' x 5000) . '; return { big: true };';
    Chandra::Bridge::Extension->register('big', $big);
    ok(length(Chandra::Bridge::Extension->source('big')) > 10000, 'large source stored');

    my $js = Chandra::Bridge::Extension->generate_js;
    like($js, qr/window\.chandra\.big/, 'large source in generate_js');
    Chandra::Bridge::Extension->clear;
}

# ---- invalid extension name ----
{
    eval { Chandra::Bridge::Extension->register('bad-name', 'return {};'); };
    like($@, qr/invalid character/i, 'hyphen in name rejected');

    eval { Chandra::Bridge::Extension->register('bad.name', 'return {};'); };
    like($@, qr/invalid character/i, 'dot in name rejected');

    eval { Chandra::Bridge::Extension->register('bad name', 'return {};'); };
    like($@, qr/invalid character/i, 'space in name rejected');

    eval { Chandra::Bridge::Extension->register('', 'return {};'); };
    like($@, qr/must not be empty/i, 'empty name rejected');
}

# ---- unicode in JS source ----
{
    Chandra::Bridge::Extension->clear;
    my $unicode_src = 'return { emoji: "\x{2603}\x{1F600}" };';
    Chandra::Bridge::Extension->register('uniext', $unicode_src);
    my $src = Chandra::Bridge::Extension->source('uniext');
    like($src, qr/emoji/, 'unicode source stored');
}

# ---- deeply nested dependency chain ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('d0', 'return { level: 0 };');
    for my $i (1..10) {
        my $prev = 'd' . ($i - 1);
        Chandra::Bridge::Extension->register("d$i", "return { level: $i };",
            depends => [$prev]);
    }

    my @list = Chandra::Bridge::Extension->list;
    is(scalar @list, 11, 'deep chain: 11 extensions');
    for my $i (0..10) {
        is($list[$i], "d$i", "deep chain order: d$i at position $i");
    }
    Chandra::Bridge::Extension->clear;
}

# ---- extension with JS syntax errors passes through ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('broken', 'return { {{{{ };');
    my $js = Chandra::Bridge::Extension->generate_js;
    like($js, qr/\{\{\{\{/, 'syntax errors pass through (runtime JS error)');
    Chandra::Bridge::Extension->clear;
}

# ---- multiple dependencies ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('dep_a', 'return { a: 1 };');
    Chandra::Bridge::Extension->register('dep_b', 'return { b: 2 };');
    Chandra::Bridge::Extension->register('combo', 'return { c: 3 };',
        depends => ['dep_a', 'dep_b']);

    my @list = Chandra::Bridge::Extension->list;
    is(scalar @list, 3, 'multi-dep: 3 extensions');
    is($list[2], 'combo', 'combo comes after both deps');
}

# ---- escaped version has no raw newlines ----
{
    Chandra::Bridge::Extension->clear;
    Chandra::Bridge::Extension->register('esc_test', "return {\n  x: 1\n};");
    my $escaped = Chandra::Bridge::Extension->generate_js_escaped;
    unlike($escaped, qr/\n/, 'escaped has no raw newlines');
    like($escaped, qr/\\n/, 'escaped has escaped newlines');
}

# ---- generate_js with no extensions ----
{
    Chandra::Bridge::Extension->clear;
    my $js = Chandra::Bridge::Extension->generate_js;
    is($js, '', 'generate_js with no extensions returns empty string');
}

# ---- register_file with missing file ----
{
    eval { Chandra::Bridge::Extension->register_file('bad', '/nonexistent/path.js'); };
    like($@, qr/cannot open/i, 'register_file with missing file croaks');
}

done_testing();
