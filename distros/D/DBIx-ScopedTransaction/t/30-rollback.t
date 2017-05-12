#!perl -T

use strict;
use warnings;

use DBI;
use DBIx::ScopedTransaction;
use File::Spec;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 7;
use Test::Warn;

use lib 't/lib';
use LocalTest;


my $dbh = LocalTest::ok_database_handle();

lives_ok
(
	sub
	{
		$dbh->do(
			q|
				CREATE TABLE test_rollback(
					name VARCHAR(16)
				);
			|
		);
	},
	'Create test table.',
);

my $transaction = DBIx::ScopedTransaction->new( $dbh );

lives_ok
(
	sub
	{
		$dbh->do(
			sprintf(
				q|
					INSERT INTO test_rollback( %s )
					VALUES( %s );
				|,
				$dbh->quote_identifier( 'name' ),
				$dbh->quote( 'test1' ),
			)
		);
	},
	'Insert row.'
);

lives_ok
(
	sub
	{
		$transaction->rollback() || die 'Failed to roll back transaction';
	},
	'Roll back transaction.',
);

my $rows_found;
lives_ok(
	sub
	{
		my $result = $dbh->selectrow_arrayref(
			q|
				SELECT COUNT(*)
				FROM test_rollback
			|
		);

		$rows_found = $result->[0]
			if defined( $result ) && scalar( @$result ) != 0;
	},
	'Retrieve rows count.',
);

is(
	$rows_found,
	0,
	'Found 0 rows in the table, rollback successful.',
);

# Rolling back a now-inactive transaction should fail.
subtest(
	'Prevent rolling back twice.',
	sub
	{
		plan( tests => 2 );

		my $double_rollback_return;
		warning_like(
			sub
			{
				$double_rollback_return = $transaction->rollback();
			},
			qr/\QLogic error: inactive transaction object committed again\E/,
			'Rolling back twice throws a warning.',
		);

		is(
			$double_rollback_return,
			0,
			'Rolling back twice returned a failure.',
		);
	},
);

undef $dbh;
