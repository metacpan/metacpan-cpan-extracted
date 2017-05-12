#!/usr/bin/perl

use strict;
use warnings;

use Acme::CPANAuthors;

use Test::More tests => 2;

my $authors = Acme::CPANAuthors->new('Israeli');
# TEST
is ($authors->count, 19, 'number of authors');
# TEST
is_deeply([sort $authors->id ], 
    [qw(
        AMOSS
        EILARA
        FELIXL
        GENIE
        ISAAC
        MIGO
        NUFFIN
        PETERG
        PRILUSKYJ
        RAZINF
        REUVEN
        ROMM
        SCHOP
        SEMUELF
        SHLOMIF
        SHLOMOY
        SMALYSHEV
        SZABGAB
        YOSEFM
    )],
    'Author IDs');