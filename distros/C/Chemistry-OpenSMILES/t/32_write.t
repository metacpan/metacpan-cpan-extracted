#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ '[C]1[C]/C=N/[C][C][C][C][C]1', '[C]1([C](/C(=N(/[C]([C]([C]([C]([C]1))))))([H])))' ],
    [ '[C:6]1[C:7]/C=N/[C:1][C:2][C:3][C:4][C:5]1', '[C:1]\1([C:2]([C:3]([C:4]([C:5]([C:6]([C:7](/C(=N/1)([H]))))))))' ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0] );

    $result = write_SMILES( \@moieties, { order_sub => \&class_order } );
    is $result, $case->[1];
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
