#!/usr/bin/perl -w

# use this program to play the examples in this directory
# use: ./beep_player.pl music_file

use strict;
use Audio::Beep;

undef $/;

my $beeper = Audio::Beep->new();
$beeper->play(<>);

