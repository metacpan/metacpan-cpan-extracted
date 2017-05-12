#!/usr/bin/env perl
use strict;
use warnings;
use Bracket;

Bracket->setup_engine('PSGI');
my $app = sub { Bracket->run(@_) };


# START NOTE: One can start this script from the parent directory like so:
# plackup -s Standalone::Prefork script/bracket.psgi
# This requires the installation of Plack (cpan Plack).
