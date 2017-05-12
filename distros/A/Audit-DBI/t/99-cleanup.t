#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;


SKIP:
{
	skip( 'Temporary database file does not exist.', 1 )
		if ! -e 't/test_database';

	ok(
		unlink( 't/test_database' ),
		'Remove temporary database file',
	);
}

SKIP:
{
	my $DATA_FILE = 'audit_test_data.tmp';

	skip( 'Temporary file does not exist.', 1 )
		if ! -e $DATA_FILE;

	ok(
		unlink( $DATA_FILE ),
		'Delete the test data file.',
	);
}
