#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use BSON;

my $bin = BSON::Binary->new( [ 1, 2, 3, 4, 5 ] );
isa_ok( $bin, 'BSON::Binary' );
is_deeply( $bin->data, [ 1, 2, 3, 4, 5 ] );
is( $bin->type, 0 );
is_deeply( [ unpack 'C*', $bin->to_s ], [ 5, 0, 0, 0, 0, 1, 2, 3, 4, 5 ] );

$bin = BSON::Binary->new( "\1\2\3\4\5", 5 );
isa_ok( $bin, 'BSON::Binary' );
is_deeply( $bin->data, [ 1, 2, 3, 4, 5 ] );
is( $bin->type, 5 );
is_deeply( [ unpack 'C*', $bin->to_s ], [ 5, 0, 0, 0, 5, 1, 2, 3, 4, 5 ] );
