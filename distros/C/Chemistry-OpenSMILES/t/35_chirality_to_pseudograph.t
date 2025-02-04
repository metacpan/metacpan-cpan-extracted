#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw(clean_chiral_centers);
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Stereo qw(chirality_to_pseudograph);
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

eval 'use Graph::Nauty qw(orbits)';
plan skip_all => 'no Graph::Nauty' if $@;

sub depict { ref $_[0] && exists $_[0]->{symbol} ? &write_SMILES : '' }

my @cases = (
    [ '[C@H4]', 'C,HHHH' ],
    [ '[C@H3][C@H3]', 'CC,HHHHHH' ],
    [ '[P@@](C(C)C)(C(C)C)(C(C)C)N', 'CCC,CCCCCC,HH,HHH,HHHHHHHHHHHHHHHHHH,N,P' ],
    [ '[P@@]([C@@H](C)C)([C@@H](C)C)([C@@H](C)C)N', 'CCC,CCC,CCC,HH,HHH,HHHHHHHHH,HHHHHHHHH,N,P' ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my( $smiles, $orbits_test ) = @$case;

    my $parser = Chemistry::OpenSMILES::Parser->new;
    my( $moiety ) = $parser->parse( $smiles );

    my $copy = $moiety->copy;
    chirality_to_pseudograph( $copy );

    my $orbits_result = join ',', sort map  { join '', map { $_->{symbol} } @$_ }
                                       grep { exists $_->[0]{symbol} }
                                            orbits( $copy, \&depict );
    is $orbits_result, $orbits_test, $smiles;
}
