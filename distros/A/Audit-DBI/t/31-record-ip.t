#!perl -T

use strict;
use warnings;

use Audit::DBI;
use Config::Tiny;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;

use lib 't/';
use LocalTest;


# Verify that the largest IP can safely be stored.

my $dbh = LocalTest::ok_database_handle();

ok(
	my $audit = Audit::DBI->new(
		database_handle => $dbh,
	),
	'Create a new Audit::DBI object.',
);

ok(
	$ENV{'REMOTE_ADDR'} = '254.254.254.254',
	"Change IP address to 254.254.254.254.",
);

lives_ok(
	sub
	{
		$audit->record(
			event        => 'test_large_ip',
			subject_type => 'test_ip',
			subject_id   => 254,
		);
	},
	'Write audit event.',
);
