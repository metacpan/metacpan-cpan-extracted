#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw( mirror );
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Stereo qw( chirality_to_pseudograph );
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use Data::Dumper;
use List::Util qw( first );
use Test::More;

my @cases = (
    # Tests from OpenSMILES specification
    [ 'S[As@TB1](F)(Cl)(Br)N',  [ qw( S As Br Cl F N ) ], 'S[As@TB2](Br)(Cl)(F)N'  ],
    [ 'S[As@TB5](F)(N)(Cl)Br',  [ qw( F As S Cl N Br ) ], 'F[As@TB10](S)(Cl)(N)Br' ],
    [ 'F[As@TB15](Cl)(S)(Br)N', [ qw( Br As Cl S F N ) ], 'Br[As@TB20](Cl)(S)(F)N' ],

    # Local tests
    [ 'S[As@TB20](F)(Cl)(Br)N', [ qw( S As F Cl Br N ) ], 'S[As@TB20](F)(Cl)(Br)N' ],
    [ 'S[As@TB20](F)(Cl)(Br)N', [ qw( S As Br Cl F N ) ], 'S[As@TB15](Br)(Cl)(F)N' ],
    [ 'S[As@TB20](F)(Cl)(Br)N', [ qw( S As Br N F Cl ) ], 'S[As@TB20](Br)(N)(F)Cl' ],
    [ 'S[As@TB20](F)(Cl)(Br)N', [ qw( S As F N Br Cl ) ], 'S[As@TB15](F)(N)(Br)Cl' ],
);

eval 'use Graph::Nauty qw( are_isomorphic )';
my $has_Graph_Nauty = !$@;

plan tests => @cases + $has_Graph_Nauty * 2 * @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    my $order_sub = sub {
        my( $vertices ) = @_;
        for my $symbol (@{$case->[1]}) {
            my $vertex = first { $_->{symbol} eq $symbol } values %$vertices;
            return $vertex if $vertex;
        }
        return values %$vertices;
    };

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0], { raw => 1 } );

    $result = write_SMILES( \@moieties, { raw => 1, order_sub => $order_sub } );
    is $result, $case->[2];

    next unless $has_Graph_Nauty;

    # Ensuring the SMILES representations describe isomorphic graphs
    my @graphs = map { $parser->parse( $_ ) } $case->[0], $case->[2], $case->[0];
    mirror $graphs[2];
    for (@graphs) {
        chirality_to_pseudograph( $_ );
    }
    ok  are_isomorphic( $graphs[0], $graphs[1], \&depict ), $case->[0] . ' <=> ' . $case->[2];
    ok !are_isomorphic( $graphs[0], $graphs[2], \&depict ), $case->[0] . ' <=> ' . $case->[0];
}

sub depict
{
    my( $vertex ) = @_;

    if( ref $vertex eq 'HASH' && exists $vertex->{symbol} ) {
        $vertex = { %$vertex };
        delete $vertex->{chirality};
        return write_SMILES( $vertex );
    }

    return Dumper $vertex;
}
