#!/usr/bin/env perl

use utf8;
use v5.14;
use strict;
use warnings;
no warnings 'redefine';
no warnings 'once';

binmode(\*STDERR, ':encoding(utf8)');
binmode(\*STDOUT, ':encoding(utf8)');

use autodie;
use Test::Roo;
use List::Util qw(all);
use FindBin qw($Bin);
use Attean;
use AtteanX::Store::DBI;
use Module::Load::Conditional qw(can_load);
use namespace::clean;

unless (can_load( modules => { 'DBD::mysql' => 0 })) {
	plan skip_all => "DBD::mysql not available.";
}

with 'Test::Attean::SPARQLSuite';

sub BUILD {
	my $self		= shift;
	my $env_path	= $ENV{'W3C_RDF_TESTS_PATH'};
	my $base		= (defined($env_path) and -d $env_path) ? $env_path : File::Spec->catfile( $Bin, 'data', 'rdf-tests' );
	my $path		= File::Spec->catfile( $base, 'sparql', 'sparql11' );
	$self->tests_dir($path);
	$self->enable_earl(filename => 'attean-sparql11-dbi-postgresql-planner.ttl', conf => { store => 'DBI/MySQL', 'eval' => 'QueryPlanner' });
}

my %args	= (use_idp_planner => 1);
while (defined(my $opt = shift)) {
	if ($opt eq '-v') {
		$args{debug}++;
		$args{results}++;
	} else {
		$args{pattern}	= $opt;
	}
}
run_me(\%args);

done_testing;

sub test_model {
	unless (all { exists $ENV{$_} } qw(ATTEAN_STORE_MYSQL_DATABASE ATTEAN_STORE_MYSQL_HOST ATTEAN_STORE_MYSQL_USER ATTEAN_STORE_MYSQL_PASSWORD)) {
		plan skip_all => "Set the MySQL environment variables to run these tests (ATTEAN_STORE_MYSQL_DATABASE, ATTEAN_STORE_MYSQL_HOST, ATTEAN_STORE_MYSQL_PORT, ATTEAN_STORE_MYSQL_USER, ATTEAN_STORE_MYSQL_PASSWORD)";
		exit(0);
	}

	my @args;
	if (my $port = $ENV{ATTEAN_STORE_MYSQL_PORT}) {
		push(@args, port => $port);
	}
	my @connect		= AtteanX::Store::DBI->dbi_connect_args(
		'mysql',
		database	=> $ENV{ATTEAN_STORE_MYSQL_DATABASE},
		host		=> $ENV{ATTEAN_STORE_MYSQL_HOST},
		user		=> $ENV{ATTEAN_STORE_MYSQL_USER},
		password	=> $ENV{ATTEAN_STORE_MYSQL_PASSWORD},
		@args
	);
	my $dbh			= DBI->connect(@connect);
	my $store		= Attean->get_store('DBI')->new( dbh => $dbh );
	foreach my $g ($store->get_graphs->elements) {
		$store->drop_graph($g);
	}
	my $model	= Attean::MutableQuadModel->new( store => $store );
	return $model;
}
