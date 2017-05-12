#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp;

use Test::More;

use Try::Tiny;

# Start at 1 since $test_count++ in BEGIN() does not work :-).

our $test_count = 1;

# -----------------------------------------------

sub BEGIN { use_ok('DBIx::Admin::DSNManager'); }

# -----------------------------------------------

my(%data) =
(
	active          => 1,
	dsn             => 'dbi:Pg:dbname=test',
	section         => 'Pg',
	use_for_testing => 1,
	username        => 'a_user',
);

try
{
	my($man1) = DBIx::Admin::DSNManager -> new
	(
		config  =>
		{
			$data{section} =>
			{
				active          => $data{active},
				dsn             => $data{dsn},
				use_for_testing => $data{use_for_testing},
				username        => $data{username},
			}
		},
		verbose => 1,
	);

	isa_ok($man1, 'DBIx::Admin::DSNManager', 'Class of first object');

	$test_count++;

	my($temp_file_handle, $temp_file_name) = File::Temp::tempfile
	(
		DIR      => File::Spec -> tmpdir,
		EXLOCK   => 0,
		SUFFIX   => '.dsn.ini',
		TEMPLATE => 'XXXX',
		UNLINK   => 1,
	);

	$man1 -> write($temp_file_name);

	my($man2) = DBIx::Admin::DSNManager -> new
	(
		file_name => $temp_file_name,
		verbose   => 1,
	);

	isa_ok($man1, 'DBIx::Admin::DSNManager', 'Class of second object');

	$test_count++;

	my($config) = $man2 -> config;

	for my $key (qw/dsn username active use_for_testing/)
	{
		ok($$config{$data{section} }{$key} eq $data{$key}, "Recovered $key from file");

		$test_count++;
	}
}
catch
{
	BAIL_OUT($_);
};

done_testing($test_count);
