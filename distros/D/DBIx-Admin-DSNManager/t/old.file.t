#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Temp;

use Test::More;

use Try::Tiny;

# Start at 1 since $test_count++ in BEGIN() does not work :-).

our $test_count = 1;

# -----------------------------------------------

sub BEGIN { use_ok('DBIx::Admin::DSNManager'); }

# -----------------------------------------------

my($dsn)       = 'dbi:Pg:dbname=prod';
my($attr)      = {AutoCommit => 1, PrintError => 1, RaiseError => 1};
my($file_name) = File::Spec -> catdir('t', 'dsn.ini');
my($section)   = 'Pg.2';
my($use_it)    = 1;

try
{
	my($manager)   = DBIx::Admin::DSNManager -> new
	(
		file_name => $file_name,
		verbose   => 1,
	);

	isa_ok($manager, 'DBIx::Admin::DSNManager', 'Class of object');

	$test_count++;

	my($config) = $manager -> config;

	ok($$config{$section}{dsn} eq $dsn, 'Recovered dsn from file');

	$test_count++;

	is_deeply($$config{$section}{attributes}, $attr, 'Recovered attributes hashref from file');

	$test_count++;

	ok($$config{$section}{use_for_testing} eq $use_it, 'Recovered use_for_testing from file');

	$test_count++;
}
catch
{
	BAIL_OUT($_);
};

done_testing($test_count);
