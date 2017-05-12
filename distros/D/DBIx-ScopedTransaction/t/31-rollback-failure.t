#!perl -T

=head1 PURPOSE

Test the failure of DBI's rollback() method on the underlying database handle
when trying to rollback a DBIx::ScopedTransaction object.

=cut

use strict;
use warnings;

use DBI;
use DBIx::ScopedTransaction;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;
use Test::Warn;

use lib 't/lib';
use LocalTest;


my $dbh = LocalTest::ok_database_handle();

my $transaction = DBIx::ScopedTransaction->new( $dbh );

ok(
	bless( $dbh, 'DBI::db::Test' ),
	'Override rollback() method of the underlying database handle.',
);

my $success;
warning_like(
	sub
	{
		$success = $transaction->rollback();
	},
	qr/\A\QFailed to rollback transaction\E/,
	'Detect warning to indicate a failure to rollback.',
);

is(
	$success,
	0,
	'The rollback method returned false to indicate a failure.',
);

ok(
	$transaction->commit(),
	'Commit the transaction.',
);


# Subclass DBI::db and override rollback() to make it fail.
package DBI::db::Test;

use base 'DBI::db';

sub rollback
{
	return 0;
}

1;
