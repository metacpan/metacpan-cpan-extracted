#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Graph::Undirected;
use Test::More;

plan tests => 2;

my $graph = Graph::Undirected->new( refvertexed => 1 );
$graph->add_vertex( { symbol => 'C', number => 1 } );
$graph->add_vertex( { symbol => 'O', number => 2 } );

my $warning;
local $SIG{__WARN__} = sub { $warning = $_[0] };

is( write_SMILES( [ $graph ] ), 'C' );
is( $warning, '1 unreachable atom(s) detected in moiety' . "\n" );
