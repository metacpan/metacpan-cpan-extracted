#!perl
use strictures 2;
use Test::More;

use DBIx::Class;
use Acme::CuckooMith;

is( DBIx::Class->VERSION, 42 );
is( Acme::CuckooMith->VERSION, 41 );

done_testing;
