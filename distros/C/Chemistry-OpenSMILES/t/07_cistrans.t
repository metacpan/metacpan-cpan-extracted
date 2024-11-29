#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'Br/C=C/F', 'Br(/C(=C(/F)))', 'F(\C(=C(\Br)))' ],
    [ 'C(\Br)=C/F', 'C(\Br)(=C(/F))', 'F(\C(=C(\Br)))' ],
    [ 'Br\C=C/F', 'Br(\C(=C(/F)))', 'F(\C(=C(/Br)))' ],
    [ 'C(/Br)=C/F', 'C(/Br)(=C(/F))', 'F(\C(=C(/Br)))' ],
    # Adapted from COD entry 1100225:
    [ 'Cl/C(=C\1COCN1)C',
      'Cl(/C(=C\1(C(O(C(N/1)))))(C))',
      'C(C(=C1(\N(C(O(C1)))))(\Cl))' ],
    # The following two cases are synonymous:
    [ 'C\1CCOC/1=C/O', 'C\1(C(C(O(C/1(=C(/O))))))', 'O(\C(=C/1(O(C(C(C\1))))))' ],
    [ 'C1CCOC/1=C/O',  'C\1(C(C(O(C/1(=C(/O))))))', 'O(\C(=C/1(O(C(C(C\1))))))' ],
);

plan tests => 2 * scalar @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0], { raw => 1 } );

    $result = write_SMILES( \@moieties, { raw => 1 } );
    is $result, $case->[1];

    $result = write_SMILES( \@moieties, { raw => 1, order_sub => \&reverse_order } );
    is $result, $case->[2];
}

sub reverse_order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$b}{number} <=>
                        $vertices->{$a}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}
