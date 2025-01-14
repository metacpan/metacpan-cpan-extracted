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

sub depict
{
    my( $vertex ) = @_;
    if( ref $vertex && exists $vertex->{symbol} ) {
        return &write_SMILES;
    } else {
        return '';
    }
}

my @orbits;
sub orbit
{
    my( $vertex ) = @_;
    for my $i (0..$#orbits) {
        return $i if grep { $_ == $vertex } @{$orbits[$i]};
    }
}

my @cases = (
    [ 'CC[C@](CO)(CCl)C', 0 ],
    [ 'CC[C@](CC)(CC)CC', 1 ],
    [ 'C[S@](O)(O)[O-]',  0 ], # FIXME: Something is off here, should be 1!

    # Anomers
    [ '[C@]1(F)(Cl)CCCCC1', 0 ],
    [ '[C@]1(F)(F)CCCCC1',  1 ],
    [ '[C@H2]1CCCCC1',      1 ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my( $smiles, $changed ) = @$case;

    my $parser = Chemistry::OpenSMILES::Parser->new;
    my( $moiety ) = $parser->parse( $smiles );

    my $copy = $moiety->copy;
    chirality_to_pseudograph( $copy );

    @orbits = orbits( $copy, \&depict );
    is scalar clean_chiral_centers( $moiety, \&orbit ), $changed, $smiles;
}
