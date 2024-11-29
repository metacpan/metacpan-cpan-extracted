#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw( valence );
use Chemistry::OpenSMILES::Parser;
use Test::More;

my @cases = (
    [ 'C', '4,1,1,1,1' ],
    [ '[C]', '0' ],
    [ 'CCC', '4,4,4,1,1,1,1,1,1,1,1' ],
    [ '[C@](C)(N)(O)', '3,4,3,2,1,1,1,1,1,1' ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my $result;

    my $parser = Chemistry::OpenSMILES::Parser->new;
    my( $moiety ) = $parser->parse( $case->[0] );

    is join( ',', map { valence( $moiety, $_ ) } sort { $a->{number} <=> $b->{number} } $moiety->vertices ),
       $case->[1];
}
