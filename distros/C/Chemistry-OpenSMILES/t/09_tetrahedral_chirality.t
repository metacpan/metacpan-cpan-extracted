#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'N[C@](Br)(O)C', 'N([C@](Br)(O)(C))', 'C([C@](O)(Br)(N))' ],
    [ 'Br[C@](O)(N)C', 'Br([C@](O)(N)(C))', 'C([C@](N)(O)(Br))' ],
    [ 'O[C@](Br)(C)N', 'O([C@](Br)(C)(N))', 'N([C@](C)(Br)(O))' ],
    [ 'Br[C@](C)(O)N', 'Br([C@](C)(O)(N))', 'N([C@](O)(C)(Br))' ],
    [ 'C[C@](Br)(N)O', 'C([C@](Br)(N)(O))', 'O([C@](N)(Br)(C))' ],
    [ 'Br[C@](N)(C)O', 'Br([C@](N)(C)(O))', 'O([C@](C)(N)(Br))' ],
    [ 'C[C@@](Br)(O)N', 'C([C@@](Br)(O)(N))', 'N([C@@](O)(Br)(C))' ],
    [ 'Br[C@@](N)(O)C', 'Br([C@@](N)(O)(C))', 'C([C@@](O)(N)(Br))' ],
    [ '[C@@](C)(Br)(O)N', '[C@@](C)(Br)(O)(N)', 'N([C@@](O)(Br)(C))' ],
    [ '[C@@](Br)(N)(O)C', '[C@@](Br)(N)(O)(C)', 'C([C@@](O)(N)(Br))' ],
);

plan tests => 2 * scalar @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0], { raw => 1 } );

    $result = write_SMILES( \@moieties );
    is( $result, $case->[1] );

    $result = write_SMILES( \@moieties, \&reverse_order );
    is( $result, $case->[2] );
}

sub reverse_order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$b}{number} <=>
                        $vertices->{$a}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}
