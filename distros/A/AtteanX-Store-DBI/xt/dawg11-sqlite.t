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
use File::Slurp;
use File::Temp qw(tempfile);
use DBIx::MultiStatementDo;
use Types::Standard qw(Str ArrayRef);
use Class::Method::Modifiers;
use Module::Load::Conditional qw(can_load);
use namespace::clean;

unless (can_load( modules => { 'DBD::sqlite' => 0 })) {
	plan skip_all => "DBD::sqlite not available.";
}

with 'Test::Attean::SPARQLSuite';

has 'test_files'	=> (is => 'rw', isa => ArrayRef, default => sub { [] });
has 'file'			=> (is => 'rw', isa => Str);

sub BUILD {
	my $self		= shift;
	my $env_path	= $ENV{'W3C_RDF_TESTS_PATH'};
	my $base		= (defined($env_path) and -d $env_path) ? $env_path : File::Spec->catfile( $Bin, 'data', 'rdf-tests' );
	my $path		= File::Spec->catfile( $base, 'sparql', 'sparql11' );
	$self->tests_dir($path);
	$self->enable_earl(filename => 'attean-sparql11-dbi-sqlite-planner.ttl', conf => { store => 'DBI/sqlite', 'eval' => 'QueryPlanner' });
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

around 'setup' => sub {
	my $orig	= shift;
	my $self	= shift;
	(undef, my $filename)	= tempfile();
# 	warn $filename;
	push(@{ $self->test_files }, $filename);
	$self->file($filename);

	my @connect		= AtteanX::Store::DBI->dbi_connect_args(
		'sqlite',
		database	=> $filename,
	);
	my $dbh		= DBI->connect(@connect);
	my $store	= Attean->get_store('DBI')->new( dbh => $dbh );
	eval {
		$store->init();
	};
	if ($@) {
		plan skip_all => "No schema files available for SQLite";
		exit(0);
	}

	return $orig->($self, @_);
};

after 'teardown' => sub {
	my $self	= shift;
	unlink($self->file);
};

run_me(\%args);

done_testing;

sub test_model {
	my $self	= shift;
	my @connect	= AtteanX::Store::DBI->dbi_connect_args('sqlite', database => $self->file);
	my $dbh		= DBI->connect(@connect);
	my $store	= Attean->get_store('DBI')->new( dbh => $dbh );
	foreach my $g ($store->get_graphs->elements) {
		$store->drop_graph($g);
	}
	my $model	= Attean::MutableQuadModel->new( store => $store );
	return $model;
}
