#!/usr/bin/perl

=head1 NAME

playtab - Print chords of songs in a tabular fashion.

=head1 DESCRIPTION

This utility program is intended for musicians. It produces tabular
chord diagrams that are very handy for playing rhythm guitar or bass
in jazz, blues, and popular music.

I wrote it since in official (and unofficial) sheet music, I find it
often hard to stick to the structure of the piece. Also, as a guitar
player, I do not need all the detailed notes and such that are only
important for melody instruments. And usually I cannot turn over the
pages while playing.

For more info and examples,
see http://johan.vromans.org/software/sw_playtab.html .

B<playtab> is just a trivial wrapper around the App::Music::PlayTab module.

=cut

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";
use App::Packager;

use App::Music::PlayTab;

::run();
