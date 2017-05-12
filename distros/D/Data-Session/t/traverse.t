#!/usr/bin/env perl

use strict;
use warnings;
use lib 't';

use Config::Tiny;

use DBI;

use File::Temp;

use Test;
use Test::More;

use Try::Tiny;

# -----------------------------------------------

sub BEGIN { use_ok('Data::Session'); }

# -----------------------------------------------

sub run
{
	my($id, $serializer, $config, $test_count) = @_;

	my(@dsn, $directory, $type);
	my($tester);

	try
	{
		# WTF: You cannot use DBI -> parse_dsn(...) || die $msg;
		# even though that's what the docs say to do.
		# BAIL_OUT reports (e.g.): ... Error in type: Unexpected component 'sha1' ...

		@dsn = DBI -> parse_dsn($$config{dsn});

		if ($#dsn < 0)
		{
			die __PACKAGE__ . ". Can't parse dsn '$$config{dsn}'";
		}

		# The EXLOCK option is for BSD-based systems.

		$directory = File::Temp::newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
		$type      = "driver:$dsn[1];id:$id;serialize:$serializer";
		$tester    = Test -> new
		(
			directory => $directory,
			dsn       => $$config{dsn},
			dsn_attr  => $$config{attributes},
			password  => $$config{password},
			type      => $type,
			username  => $$config{username},
			verbose   => 1,
		);

		subtest $type => sub
		{
			$$test_count += $tester -> traverse;
		};
	}
	catch
	{
		# This extra call to done_testing just stops an extra error message.

		done_testing($$test_count);
		BAIL_OUT($_);
	};

} # End of run.

# -----------------------------------------------

sub report
{
	my($s) = @_;

	print STDERR "# $s\n";

} # End of report.

# -----------------------------------------------

sub string2hashref
{
	my($s)      = @_;
	$s          ||= '';
	my($result) = {};

	if ($s)
	{
		if ($s =~ m/^\{\s*([^}]*)\}$/)
		{
			my(@attr) = map{split(/\s*=>\s*/)} split(/\s*,\s*/, $1);

			if (@attr)
			{
				$result = {@attr};
			}
		}
		else
		{
			die "Invalid syntax for hashref: $s";
		}
	}

	return $result;

} # End of string2hashref.

# -----------------------------------------------

my($dsn_config) = Config::Tiny -> read('t/basic.ini');
my($test_count) = 1; # The use_ok in BEGIN counts as the first test.

my($config);
my($temp);

# We skip UUID16 since echoing such ids to the console can change the char set.

for my $id (qw/MD5/)
{
	for my $serializer (qw/DataDumper/)
	{
		for my $dsn_name (sort keys %$dsn_config)
		{
			$config              = $$dsn_config{$dsn_name};
			$$config{attributes} = string2hashref($$config{attributes});

			next if ( ($$config{active} == 0) || ($$config{use_for_testing} == 0) );

			$temp = Test -> new(dsn => $$config{dsn}, type => 'Fake');

			if ($temp -> check_sqlite_directory_exists == 0)
			{
				report("Skipping dsn '$$config{dsn}' because the SQLite directory does not exist");

				next;
			}

			report("DSN name: $dsn_name. DSN: $$config{dsn}. ID generator: $id. Serializer: $serializer");

			run($id, $serializer, $config, \$test_count);
		}
	}
}

done_testing($test_count);
