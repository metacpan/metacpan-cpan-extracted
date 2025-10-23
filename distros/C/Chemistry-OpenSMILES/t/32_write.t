#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ '[C]1[C]/C=N/[C][C][C][C][C]1', '[C]1[C]/C=N/[C][C][C][C][C]1' ],
    [ '[C:6]1[C:7]/C=N/[C:1][C:2][C:3][C:4][C:5]1', '[C:1]\1[C:2][C:3][C:4][C:5][C:6][C:7]/C=N/1' ],

    # If tetrahedral chiral atom with implicit H starts the SMILES, H atom is treated as the 'from' atom.
    # See https://github.com/opensmiles/OpenSMILES/issues/10
    [ '[C@H](Br)(Cl)[F:1]', '[F:1][C@@H](Br)Cl' ],
    [ '[C@H](Br)(Cl)F', '[C@H](Br)(Cl)F', ],

    # Examples from OpenSMILES specification, "3.7. Disconnected Structures"
    [ 'c1cc(O.NCCO)ccc1', 'c1cc(O)ccc1.NCCO' ],
    [ 'Oc1cc(.NCCO)ccc1', 'Oc1ccccc1.NCCO' ],

    # Synthetic examples for connectivity in disconnected SMILES
    [ 'C(C.CCC.CCCC.CCCCC)', 'CC.CCC.CCCC.CCCCC' ],
    [ 'CC(.CCC.CCCC.CCCCC)', 'CC.CCC.CCCC.CCCCC' ],
);

plan tests => scalar @cases;

my $parser = Chemistry::OpenSMILES::Parser->new;

for my $case (@cases) {
    my( $input, $output ) = @$case;

    my @moieties = $parser->parse( $input );

    my $result = write_SMILES( \@moieties, { order_sub => \&class_order,
                                             remove_implicit_hydrogens => 1,
                                             unsprout_hydrogens => 1 } );
    is $result, $output;
}

sub class_order
{
    my $vertices = shift;
    my @classed   = grep {  $vertices->{$_}{class} } keys %$vertices;
    my @classless = grep { !$vertices->{$_}{class} } keys %$vertices;
    my @sorted = ( (sort {  $vertices->{$a}{class}  <=> $vertices->{$b}{class}  } @classed),
                   (sort {  $vertices->{$a}{number} <=> $vertices->{$b}{number} } @classless) );
    return $vertices->{shift @sorted};
}
