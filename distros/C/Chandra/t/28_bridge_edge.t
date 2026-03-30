#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Bridge');

# === js_code_escaped preserves all critical structures ===
{
    my $escaped = Chandra::Bridge->js_code_escaped;
    like($escaped, qr/window\.chandra/, 'escaped code has window.chandra');
    like($escaped, qr/invoke/, 'escaped code has invoke');
    like($escaped, qr/Promise/, 'escaped code has Promise');
    like($escaped, qr/_resolve/, 'escaped code has _resolve');
    like($escaped, qr/_event/, 'escaped code has _event');
    like($escaped, qr/_eventData/, 'escaped code has _eventData');
}

# === js_code_escaped escapes backslashes before quotes ===
{
    my $escaped = Chandra::Bridge->js_code_escaped;
    # Should not contain unescaped single quotes
    # The escaped version replaces ' with \' and \ with \\
    unlike($escaped, qr/(?<!\\)'/, 'no unescaped single quotes in escaped code');
}

# === js_code_escaped is idempotent ===
{
    my $a = Chandra::Bridge->js_code_escaped;
    my $b = Chandra::Bridge->js_code_escaped;
    is($a, $b, 'js_code_escaped returns same value each time');
}

# === js_code and js_code_escaped have consistent content ===
{
    my $raw = Chandra::Bridge->js_code;
    my $escaped = Chandra::Bridge->js_code_escaped;
    # The escaped version should be longer due to escape sequences
    ok(length($escaped) >= length($raw), 'escaped is at least as long as raw');
    # Both should contain core functionality
    like($raw, qr/window\.external\.invoke/, 'raw has external.invoke');
    like($escaped, qr/window\.external\.invoke/, 'escaped has external.invoke');
}

# === js_code contains call method with arguments slicing ===
{
    my $js = Chandra::Bridge->js_code;
    like($js, qr/Array\.prototype\.slice/, 'call method uses Array slice for arguments');
}

# === js_code_escaped has no raw newlines but has escaped ones ===
{
    my $escaped = Chandra::Bridge->js_code_escaped;
    my @lines = split /\n/, $escaped;
    is(scalar @lines, 1, 'escaped code is a single line');
}

# === JS_BRIDGE constant accessible via js_code ===
{
    my $js = Chandra::Bridge->js_code;
    ok(length($js) > 0, 'JS_BRIDGE constant is non-empty');
    # Verify it's a complete IIFE
    my $open_parens = () = $js =~ /\(/g;
    my $close_parens = () = $js =~ /\)/g;
    is($open_parens, $close_parens, 'balanced parentheses in bridge JS');
}

# === js_code event data extraction includes all fields ===
{
    my $js = Chandra::Bridge->js_code;
    like($js, qr/targetId/, 'eventData extracts targetId');
    like($js, qr/targetName/, 'eventData extracts targetName');
    like($js, qr/e\.target/, 'eventData checks e.target');
    like($js, qr/e\.key/, 'eventData extracts key');
    like($js, qr/e\.keyCode/, 'eventData extracts keyCode');
    like($js, qr/checked/, 'eventData extracts checked');
}

done_testing;
