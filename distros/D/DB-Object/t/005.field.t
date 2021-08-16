#!/usr/local/bin/perl

BEGIN
{
	use strict;
	use warnings;
	use lib './lib';
    use Test::More qw( no_plan );
    select(($|=1,select(STDERR),$|=1)[1]);
    use_ok( 'DB::Object::Fields::Field' ) || BAIL_OUT( "Unable to load DB::Object::Fields::Field" );
    use_ok( 'DB::Object::Tables' ) || BAIL_OUT( "Unable to load DB::Object::Tables" );
};

my $t = bless( { table => 'dummy' } => 'DB::Object::Tables' );
my $f = DB::Object::Fields::Field->new( name => 'test', table_object => $t );
isa_ok( $t, 'DB::Object::Tables' );
isa_ok( $f, 'DB::Object::Fields::Field' );

is( $f > 10, "test > 10", "> operator" );
is( $f >= 10, "test >= 10", ">= operator" );
is( $f < 10, "test < 10", "< operator" );
is( $f <= 10, "test <= 10", "<= operator" );
is( $f != 10, "test <> 10", "!= operator" );
is( $f + 10, "test + 10", "+ operator" );
is( $f - 10, "test - 10", "- operator" );
is( $f * 10, "test * 10", "* operator" );
is( $f / 10, "test / 10", "/ operator" );
is( $f % 10, "test % 10", "% operator" );
is( $f & 10, "test & 10", "& operator" );
is( $f ^ 10, "test ^ 10", "^ operator" );
is( $f | 10, "test | 10", "| operator" );
is( $f << 10, "test << 10", "<< operator" );
is( $f >> 10, "test >> 10", ">> operator" );
is( $f == 'NULL', "test IS NULL", "== operator" );
is( 10 + $f, "10 + test", "reverse (10 + field)" );
is( "inet '192.168.1.20'" << $f, "inet '192.168.1.20' << test", "check ip in in range with << operator" );
