#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'CHANDRA_SKIP_CLIPBOARD set' if $ENV{CHANDRA_SKIP_CLIPBOARD};
}

use Chandra::Clipboard;

use Chandra::Clipboard;

{
    Chandra::Clipboard->set_text('probe');
    my $got = Chandra::Clipboard->get_text;
    unless (defined $got && $got eq 'probe') {
        plan skip_all => 'Clipboard not available on this platform';
    }
}

# ---- API exists ----
{
    can_ok('Chandra::Clipboard', qw(
        get_text set_text has_text
        get_html set_html has_html
        get_image set_image has_image
        clear
    ));
}

# ---- Text round-trip ----
{
    ok(Chandra::Clipboard->set_text('Hello clipboard'), 'set_text returns true');
    ok(Chandra::Clipboard->has_text, 'has_text after set');
    is(Chandra::Clipboard->get_text, 'Hello clipboard', 'get_text round-trip');
}

# ---- Overwrite text ----
{
    Chandra::Clipboard->set_text('first');
    is(Chandra::Clipboard->get_text, 'first', 'first text set');
    Chandra::Clipboard->set_text('second');
    is(Chandra::Clipboard->get_text, 'second', 'text overwritten');
}

# ---- UTF-8 text ----
{
    my $utf8 = "caf\x{e9} \x{2603}";  # cafe + snowman
    Chandra::Clipboard->set_text($utf8);
    my $got = Chandra::Clipboard->get_text;
    ok(defined $got, 'UTF-8 text retrieved');
    is($got, $utf8, 'UTF-8 round-trip');
}

# ---- Empty string ----
{
    ok(Chandra::Clipboard->set_text(''), 'set empty string');
    my $got = Chandra::Clipboard->get_text;
    # Empty string handling is platform-dependent:
    # - Some platforms return '' (empty string)
    # - Some platforms return undef (clipboard clears on empty)
    # - Headless systems may not retain clipboard contents at all
    ok(!defined $got || $got eq '', 'get_text returns undef or empty for empty string');
}

# ---- HTML round-trip ----
{
    my $html = '<b>Bold</b>';
    ok(Chandra::Clipboard->set_html($html), 'set_html returns true');
    # Note: on some platforms set_html may not produce has_html=true
    # (GTK stores as text), so just check set works
}

# ---- Clear ----
{
    Chandra::Clipboard->set_text('to be cleared');
    ok(Chandra::Clipboard->has_text, 'has text before clear');
    Chandra::Clipboard->clear;
    ok(!Chandra::Clipboard->has_text, 'no text after clear');
}

# ---- has_image with no image ----
{
    Chandra::Clipboard->clear;
    ok(!Chandra::Clipboard->has_image, 'no image after clear');
}

# ---- get_text after clear returns undef ----
{
    Chandra::Clipboard->clear;
    my $got = Chandra::Clipboard->get_text;
    ok(!$got, 'get_text after clear is undef or empty');
}

# ---- get_image with no image returns undef ----
{
    Chandra::Clipboard->clear;
    my $got = Chandra::Clipboard->get_image;
    ok(!defined $got, 'get_image with no image returns undef');
}

done_testing();
