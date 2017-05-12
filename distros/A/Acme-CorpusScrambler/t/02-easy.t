#!/usr/bin/perl

use strict;
use warnings;
use Acme::CorpusScrambler;

use Test::More tests => 1;

my $sc = Acme::CorpusScrambler->new;

my $text1 = $sc->scramble;
ok( length($text1) > 0 );

print $text1,"\n";

