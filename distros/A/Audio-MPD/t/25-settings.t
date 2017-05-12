#!perl
#
# This file is part of Audio-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Audio::MPD;
use Test::More;

# are we able to test module?
eval 'use Test::Corpus::Audio::MPD';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;

plan tests => 10;
my $mpd = Audio::MPD->new;


#
# testing repeat
$mpd->repeat(1);
is( $mpd->status->repeat, 1, 'enabling repeat mode' );
$mpd->repeat(0);
is( $mpd->status->repeat, 0, 'disabling repeat mode' );
$mpd->repeat;
is( $mpd->status->repeat, 1, 'toggling repeat mode to on' );
$mpd->repeat;
is( $mpd->status->repeat, 0, 'toggling repeat mode to off' );


#
# testing random
$mpd->random(1);
is( $mpd->status->random, 1, 'enabling random mode' );
$mpd->random(0);
is( $mpd->status->random, 0, 'disabling random mode' );
$mpd->random;
is( $mpd->status->random, 1, 'toggling random mode to on' );
$mpd->random;
is( $mpd->status->random, 0, 'toggling random mode to off' );


#
# testing fade
$mpd->fade(15);
is( $mpd->status->xfade, 15, 'enabling fading' );
$mpd->fade;
is( $mpd->status->xfade,  0, 'disabling fading by default' );

