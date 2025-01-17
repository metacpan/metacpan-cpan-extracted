#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ '[CH:4](=[CH:3]/[C:2][O:1])\[C:5][O:6]', '[C:4](=[C:3](/[C:2]([O:1]))([H]))(\[C:5]([O:6]))([H])', '[H]([C:3](/[C:2]([O:1]))(=[C:4]([H])(\[C:5]([O:6]))))', '[O:1]([C:2](\[C:3](=[C:4](\[C:5]([O:6]))([H]))([H])))' ],
);

plan tests => 3 * scalar @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0] );

    $result = write_SMILES( \@moieties );
    is $result, $case->[1];

    $result = write_SMILES( \@moieties, { order_sub => \&reverse_order } );
    is $result, $case->[2];

    $result = write_SMILES( \@moieties, { order_sub => \&class_order } );
    is $result, $case->[3];
}

sub reverse_order
{
    my $vertices = shift;
    my @sorted = sort { $vertices->{$b}{number} <=>
                        $vertices->{$a}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
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
