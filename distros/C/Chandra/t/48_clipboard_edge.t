#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use lib 't/lib';

use Chandra::Clipboard;
use Chandra::Test::Display;

Chandra::Test::Display->skip_unless_clipboard;


# ---- Large text ----
{
    my $big = 'x' x 100_000;
    ok(Chandra::Clipboard->set_text($big), 'set 100k text');
    my $got = Chandra::Clipboard->get_text;
    is(length($got), 100_000, '100k round-trip length');
    is($got, $big, '100k content matches');
}

# ---- Newlines and special chars ----
{
    my $multi = "line1\nline2\nline3\ttab";
    Chandra::Clipboard->set_text($multi);
    is(Chandra::Clipboard->get_text, $multi, 'multiline + tabs preserved');
}

# ---- Null bytes in text ----
{
    my $with_null = "before\x00after";
    Chandra::Clipboard->set_text($with_null);
    # Clipboard likely truncates at null — just verify no crash
    my $got = Chandra::Clipboard->get_text;
    ok(defined $got, 'text with null byte does not crash');
}

# ---- Rapid set/get cycles ----
{
    for my $i (1..20) {
        Chandra::Clipboard->set_text("cycle_$i");
    }
    is(Chandra::Clipboard->get_text, 'cycle_20', 'rapid cycling ends with last value');
}

# ---- set_text then clear then set_text ----
{
    Chandra::Clipboard->set_text('alpha');
    Chandra::Clipboard->clear;
    Chandra::Clipboard->set_text('beta');
    is(Chandra::Clipboard->get_text, 'beta', 'set after clear works');
}

# ---- HTML with entities ----
{
    my $html = '<p>&amp; &lt;tag&gt;</p>';
    ok(Chandra::Clipboard->set_html($html), 'set_html with entities');
}

# ---- get_html after clear ----
{
    Chandra::Clipboard->clear;
    my $got = Chandra::Clipboard->get_html;
    ok(!defined $got || $got eq '', 'get_html after clear');
}

# ---- set_image with nonexistent file ----
{
    my $ok = Chandra::Clipboard->set_image('/nonexistent/image.png');
    ok(!$ok, 'set_image with missing file returns false');
}

# ---- set_image with valid PNG ----
SKIP: {
    my $dir = tempdir(CLEANUP => 1);
    my $png_path = "$dir/test.png";

    # Minimal valid 1x1 red PNG (67 bytes)
    my $png = pack("H*",
        "89504e470d0a1a0a0000000d49484452000000010000000108020000009001" .
        "2e00000000c4944415478016360f8cf00000002000160e7274800000000" .
        "0049454e44ae426082");
    open my $fh, '>:raw', $png_path or die "Cannot write PNG: $!";
    print $fh $png;
    close $fh;

    my $ok = Chandra::Clipboard->set_image($png_path);
    skip 'image clipboard not available (headless?)', 4 unless $ok;
    ok($ok, 'set_image with valid PNG');
    ok(Chandra::Clipboard->has_image, 'has_image after set');
    my $data = Chandra::Clipboard->get_image;
    ok(defined $data, 'get_image returns data');
    ok(length($data) > 0, 'image data is non-empty') if defined $data;
}

# ---- Double clear ----
{
    Chandra::Clipboard->clear;
    Chandra::Clipboard->clear;
    ok(!Chandra::Clipboard->has_text, 'double clear is safe');
}

# ---- has_text/has_html/has_image consistency ----
{
    Chandra::Clipboard->set_text('check');
    ok(Chandra::Clipboard->has_text, 'has_text true');
    # After setting text, image should not appear
    # (platform may keep stale data, but at minimum no crash)
    Chandra::Clipboard->has_image;
    Chandra::Clipboard->has_html;
    pass('has_* methods do not crash with mixed content');
}

done_testing();
