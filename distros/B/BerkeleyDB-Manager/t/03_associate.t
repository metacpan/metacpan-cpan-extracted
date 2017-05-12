#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";
use BerkeleyDB::Manager::Test 4.6, "no_plan";

use Test::More;

use Test::TempDir;

use ok 'BerkeleyDB::Manager';

{
	isa_ok( my $m = BerkeleyDB::Manager->new( home => temp_root, create => 1 ), "BerkeleyDB::Manager" );

	isa_ok( $m->env, "BerkeleyDB::Env" );

	my $pri = $m->open_db("primary.db");
	my $sec = $m->open_db("secondary.db");

	$m->associate(
		primary => $pri,
		secondary => $sec,
		callback => sub { return $_[1] }
	);

	$pri->db_put( "foo", "bar" );

	my ( $pkey, $v );
	sok( $sec->db_pget( "bar", $pkey, $v ), "get on secondary" );

	is( $pkey, "foo", "pkey fetched" );
	is( $v, "bar", "value" );
}
