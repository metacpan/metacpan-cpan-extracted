#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Data::Dumper;
use Test::More;

eval 'use Graph::Nauty qw(are_isomorphic)';
plan skip_all => 'no Graph::Nauty' if $@;

my @cases = (
    [ 'c1ccccc12ccccc2', 'c1ccccc11ccccc1' ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = map { $parser->parse( $_ ) } @$case;
    ok are_isomorphic( @moieties, \&depict );
}

sub depict
{
    my( $vertex ) = @_;
    return ref $vertex eq 'HASH' && exists $vertex->{symbol}
        ? write_SMILES( $vertex )
        : Dumper $vertex;
}
