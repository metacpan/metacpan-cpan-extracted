#!perl -T

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;


can_ok(
	'LocalTest',
	'get_database_type',
);

ok(
	defined(
		my $dbh = LocalTest::get_database_handle()
	),
	'Retrieve the database handle.',
);

dies_ok(
	sub
	{
		LocalTest::get_database_type();
	},
	'The first argument must be a database handle.',
);

my $database_type;
lives_ok(
	sub
	{
		$database_type = LocalTest::get_database_type( $dbh );
	},
	'Retrieve the database type.',
);

like(
	$database_type,
	qr/^(?:mysql|SQLite|Pg)$/,
	'Retrieved a supported database type.',
);

