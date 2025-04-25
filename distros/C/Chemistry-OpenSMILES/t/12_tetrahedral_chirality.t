#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'Br[C@H](Cl)(I)', 'Br[C@](Cl)(I)[H]', '[H][C@](I)(Cl)Br' ],
);

plan tests => 2 * scalar @cases;

my $parser = Chemistry::OpenSMILES::Parser->new;

for my $case (@cases) {
    my $result;

    my @moieties = $parser->parse( $case->[0] );

    $result = write_SMILES( \@moieties, { unsprout_hydrogens => '' } );
    is $result, $case->[1];

    $result = write_SMILES( \@moieties, { order_sub => \&reverse_order,
                                          unsprout_hydrogens => '' } );
    is $result, $case->[2];
}

sub reverse_order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$b}{number} <=>
                        $vertices->{$a}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}
