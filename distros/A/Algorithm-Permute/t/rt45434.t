#!perl

use strict;
use warnings;
use Test::More;

use Algorithm::Permute;

my $p = Algorithm::Permute->new( [ 1 .. 4 ], 2 );

$p->reset;

my $i = 0;
while ( my @a = $p->next ) { diag( join( ',', @a ) ); $i++; }

is( $i, 12 );

$p->reset;

$i = 0;
while ( my @a = $p->next ) { diag( join( ',', @a ) ); $i++; }

is( $i, 12 );

done_testing;
