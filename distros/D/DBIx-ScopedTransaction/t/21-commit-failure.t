#!perl -T

=head1 PURPOSE

Test the failure of DBI's commit() method on the underlying database handle
when trying to commit a DBIx::ScopedTransaction object.

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
	'Override commit() method of the underlying database handle.',
);

my $success;
warning_like(
	sub
	{
		$success = $transaction->commit();
	},
	qr/\A\QFailed to commit transaction\E/,
	'Detect warning to indicate a failure to commit.',
);

is(
	$success,
	0,
	'The commit method returned false to indicate a failure.',
);

ok(
	$transaction->rollback(),
	'Roll back the transaction.',
);


# Subclass DBI::db and override commit() to make it fail.
package DBI::db::Test;

use base 'DBI::db';

sub commit
{
	return 0;
}

1;
