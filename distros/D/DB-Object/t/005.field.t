#!/usr/local/bin/perl
BEGIN
{
	use strict;
	use warnings;
	use vars qw( $DEBUG );
	use lib './lib';
    use Test::More qw( no_plan );
    select(($|=1,select(STDERR),$|=1)[1]);
    use_ok( 'DB::Object::Fields::Field' ) || BAIL_OUT( "Unable to load DB::Object::Fields::Field" );
    use_ok( 'DB::Object::Tables' ) || BAIL_OUT( "Unable to load DB::Object::Tables" );
    use_ok( 'DB::Object' ) || BAIL_OUT( "Unable to load DB::Object" );
	our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

my $dbh = DB::Object->new( debug => $DEBUG );
my $t = bless( { table => 'dummy', dbo => $dbh } => 'DB::Object::Tables' );
$t->reset;
my $f = DB::Object::Fields::Field->new( name => 'test', table_object => $t, query_object => $t->query_object );
if( !defined( $f ) )
{
    diag( "Failed creating field object: ", DB::Object::Fields::Field->error ) if( $DEBUG );
}
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
is( $f == 'NULL', "test = NULL", "== operator" );
is( $f eq 'NULL', "test IS NULL", "== operator" );
is( 10 + $f, "10 + test", "reverse (10 + field)" );
is( \"inet '192.168.1.20'" << $f, "inet '192.168.1.20' << test", "check ip in in range with << operator" );
my $P = $dbh->placeholder( type => 'inet' );
is( "inet $P" << $f, "inet ? << test", "check ip in in range with << operator using placeholder object" );
