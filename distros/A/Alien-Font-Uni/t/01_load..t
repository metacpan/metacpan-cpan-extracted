#!/usr/bin/perl -w
use strict;
BEGIN { unshift @INC, 'lib' };

use Test::More tests => 3;

use_ok( 'Alien::Font::Uni' );
is(-e Alien::Font::Uni::get_path(), 1, 'font file present');
ok(Alien::Font::Uni::get_path() =~ Alien::Font::Uni::font_version(), 'version propably right');

exit (0);


