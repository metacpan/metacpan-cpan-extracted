#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ '[C@](C)(N)O',  '[C@](C)(N)O',  'O[C@@](N)C' ],
    # Same as before, inverting enumeration direction:
    [ '[C@@](C)(N)O', '[C@@](C)(N)O', 'O[C@](N)C' ],

    [ 'C[C@](O)N',    'C([C@](O)N)',  'N[C@@](O)C' ],
    # Same as before, inverting enumeration direction:
    [ 'C[C@@](O)N',   'C([C@@](O)N)', 'N[C@](O)C' ],
);

plan tests => 2 * scalar @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0] );

    $result = write_SMILES( \@moieties, { unsprout_hydrogens => '' } );
    is drop_H( $result ), $case->[1];

    $result = write_SMILES( \@moieties, { order_sub => \&reverse_order,
                                          unsprout_hydrogens => '' } );
    is drop_H( $result ), $case->[2];
}

sub drop_H
{
    my( $smiles ) = @_;
    $smiles =~ s/\(\[H\]\)//g;
    $smiles =~ s/\[H\]//g;
    return $smiles;
}

sub reverse_order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$b}{number} <=>
                        $vertices->{$a}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}
