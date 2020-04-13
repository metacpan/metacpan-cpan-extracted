#!/usr/bin/perl

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 8;

BEGIN
{
	use_ok( 'DB::Object' );
	use_ok( 'DB::Object::Tables' );
	use_ok( 'DB::Object::Statement' );
	use_ok( 'DB::Object::Query' );
	use_ok( 'DB::Object::Fields' );
	use_ok( 'DB::Object::Fields::Field' );
	use_ok( 'DB::Object::Cache::Tables' );
}

my $object = DB::Object->new();
isa_ok( $object, 'DB::Object' );


