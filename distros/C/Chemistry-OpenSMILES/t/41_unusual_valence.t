#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Graph::Undirected;
use Test::More;

plan tests => 6;

my $graph = Graph::Undirected->new( refvertexed => 1 );

my $C = { symbol => 'C', number => 0 };
my $O = { symbol => 'O', number => 1 };
$graph->add_edge( $C, $O );

my $options = { unsprout_hydrogens => '' };

is write_SMILES( [ $graph ] ), '[C][O]';

$graph->add_edge( $O, { symbol => 'H', number => 2 } );
is write_SMILES( [ $graph ], $options ), '[C]O[H]';

$graph->add_edge( $C, { symbol => 'H', number => 3 } );
is write_SMILES( [ $graph ], $options ), '[C](O[H])[H]';

$graph->add_edge( $C, { symbol => 'H', number => 4 } );
is write_SMILES( [ $graph ], $options ), '[C](O[H])([H])[H]';

$graph->add_edge( $C, { symbol => 'H', number => 5 } );
is write_SMILES( [ $graph ], $options ), 'C(O[H])([H])([H])[H]';

$graph->add_edge( $C, { symbol => 'H', number => 6 } );
is write_SMILES( [ $graph ], $options ), '[C](O[H])([H])([H])([H])[H]';
