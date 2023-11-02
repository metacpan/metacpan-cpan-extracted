#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'N[C@SP1](Br)(O)C', 'N([C@SP1](Br)(O)(C))', 'C([C@SP1](O)(Br)(N))' ],
    [ 'N[C@SP2](Br)(O)C', 'N([C@SP2](Br)(O)(C))', 'C([C@SP2](O)(Br)(N))' ],
    [ 'N[C@SP3](Br)(O)C', 'N([C@SP3](Br)(O)(C))', 'C([C@SP3](O)(Br)(N))' ],
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
