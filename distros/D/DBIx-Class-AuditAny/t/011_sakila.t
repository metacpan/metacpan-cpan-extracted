# -*- perl -*-

use strict;
use warnings;
use Test::More;
use Test::Routine::Util;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestEnv;

my $db_file = TestEnv->vardir->file('sakila.db')->stringify;
my $db_audit_file = TestEnv->vardir->file('sakila-audit.db')->stringify;

run_tests(
	"Tracking on the 'Sakila' example db (MySQL)", 
	'Routine::Sakila::ToAutoDBIC' => {
		test_schema_dsn => 'dbi:SQLite:dbname=' . $db_file,
		sqlite_db => $db_audit_file
	}
);


done_testing;