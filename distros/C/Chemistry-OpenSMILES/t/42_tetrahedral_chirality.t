#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use List::Util qw( first );
use Test::More;

my @cases = (
    # Tests from OpenSMILES specification, 3.8.2. Tetrahedral Centers
    [ 'N[C@](Br)(O)S',    [ qw( Br C O N S ) ], 'Br[C@](O)(N)S' ],
    [ 'O[C@](Br)(S)N',    [ qw( Br C S O N ) ], 'Br[C@](S)(O)N' ],
    [ 'S[C@](Br)(N)O',    [ qw( Br C N S O ) ], 'Br[C@](N)(S)O' ],
    [ 'S[C@@](Br)(O)N',   [ qw( Br C N O S ) ], 'Br[C@@](N)(O)S' ],
    [ '[C@@](S)(Br)(O)N', [ qw( C Br N O S ) ], '[C@@](Br)(N)(O)S' ],

    [ 'N[C@]([H])(O)S',   [ qw( N C O S ) ], 'N[C@H](O)S' ],

    # Local tests
    [ '[C@@](S)([H])(O)N', [ qw( C N O S ) ], '[C@@H](N)(O)S' ],
    [ '[H][C@@](N)(O)S',   [ qw( C N O S ) ], '[C@@H](N)(O)S' ],
);

plan tests => scalar @cases;

my $parser = Chemistry::OpenSMILES::Parser->new;

for my $case (@cases) {
    my( $input, $order, $output ) = @$case;

    my $order_sub = sub {
        my $vertices = shift;
        for my $symbol (@$order) {
            my $vertex = first { $_->{symbol} eq $symbol } values %$vertices;
            return $vertex if $vertex;
        }
        my( $vertex ) = values %$vertices;
        return $vertex;
    };

    my( $input_moiety ) = $parser->parse( $input );
    my $result = write_SMILES( [ $input_moiety ], { explicit_aromatic_bonds => '',
                                                    order_sub => $order_sub,
                                                    remove_implicit_hydrogens => 1,
                                                    unsprout_hydrogens => 1 } );
    is $result, $output, $input;
}

sub depict
{
    my( $vertex ) = @_;

    return '' unless exists $vertex->{symbol};

    $vertex = { %$vertex };
    delete $vertex->{chirality};
    return write_SMILES( $vertex );
}
