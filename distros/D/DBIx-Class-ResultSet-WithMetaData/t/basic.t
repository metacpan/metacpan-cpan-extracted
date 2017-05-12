#!perl

use Test::More tests => 2;
use lib qw(t/lib);
use DBICTest;
use Data::Dumper;

# set up and populate schema
ok(my $schema = DBICTest->init_schema(), 'got schema');

my $producer_rs = $schema->resultset('Producer')->display();

is_deeply([sort { $a->{producerid} <=> $b->{producerid} } @{$producer_rs}], [
	{
		'name' => 'Matt S Trout',
		'producerid' => '1'
	},
	{
		'name' => 'Bob The Builder',
		'producerid' => '2'
	},
	{
		'name' => 'Fred The Phenotype',
		'producerid' => '3'
	}
], 'display returned as expected');
