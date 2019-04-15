#!perl

use Data::Frame::Setup;

use Test2::V0;

use PDL::SV ();
use Math::BigInt;

my $data = [ Math::BigInt->new('4'), Math::BigInt->new('3'), Math::BigInt->new('20'), Math::BigInt->new('2'), ];
#my $data = [ '4', '3', '20', '2', ];
my $f = PDL::SV->new( $data );

is( $f->nelem, 4 );

is( $f->at(0), 4 );

is( ref $f->at(0), 'Math::BigInt' );

is( "$f", "[ 4 3 20 2 ]" );

is( "@{[ $f->slice('1:2') ]}", "[ 3 20 ]" );

is( "@{[ $f->slice('1') ]}", "[ 3 ]" );

is( $f->element_stringify_max_width, 2 );

done_testing;
