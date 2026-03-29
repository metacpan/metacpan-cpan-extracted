#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Bridge');

# --- js_code returns non-empty string ---
{
    my $js = Chandra::Bridge->js_code;
    ok(defined $js, 'js_code is defined');
    ok(length($js) > 100, 'js_code is substantial');
}

# --- js_code is idempotent ---
{
    my $a = Chandra::Bridge->js_code;
    my $b = Chandra::Bridge->js_code;
    is($a, $b, 'js_code returns same value each time');
}

# --- js_code contains key structures ---
{
    my $js = Chandra::Bridge->js_code;
    
    like($js, qr/window\.chandra/, 'contains window.chandra');
    like($js, qr/invoke/, 'contains invoke method');
    like($js, qr/call/, 'contains call method');
    like($js, qr/_resolve/, 'contains _resolve method');
    like($js, qr/_event/, 'contains _event method');
    like($js, qr/_eventData/, 'contains _eventData method');
    like($js, qr/_callbacks/, 'contains _callbacks storage');
    like($js, qr/_id/, 'contains _id counter');
    like($js, qr/Promise/, 'uses Promises');
    like($js, qr/window\.external\.invoke/, 'calls window.external.invoke');
    like($js, qr/JSON\.stringify/, 'uses JSON.stringify');
}

# --- js_code is a self-executing function ---
{
    my $js = Chandra::Bridge->js_code;
    like($js, qr/^\s*\(function\(\)/, 'starts with IIFE');
    like($js, qr/\}\)\(\);\s*$/, 'ends with IIFE invocation');
}

# --- js_code has guard against double initialization ---
{
    my $js = Chandra::Bridge->js_code;
    like($js, qr/if\s*\(window\.chandra\)\s*return/, 'has guard clause');
}

# --- js_code_escaped ---
{
    my $escaped = Chandra::Bridge->js_code_escaped;
    ok(defined $escaped, 'js_code_escaped is defined');
    unlike($escaped, qr/\n/, 'escaped code has no raw newlines');
    like($escaped, qr/\\n/, 'escaped code has escaped newlines');
}

# --- no // comments in js_code (they break data URI encoding) ---
{
    my $js = Chandra::Bridge->js_code;
    my @lines = split /\n/, $js;
    my @bad = grep { /^\s*\/\// } @lines;
    is(scalar @bad, 0, 'no // line comments in bridge JS');
}

done_testing();
