#!perl -T

use strict;
use warnings;

use DBI;
use DBIx::ScopedTransaction;
use File::Spec;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;

use lib 't/lib';
use LocalTest;


my $dbh = LocalTest::ok_database_handle();

# If PrintError is not set to 0, Test::FailWarnings will catch the error thrown
# by begin_work() via set_err(), which is a false-positive in this case as it is
# a desired behavior but it's not the exception we will be looking for.
ok(
	defined(
		local $dbh->{PrintError} = 0
	),
	'Do not print DBI errors directly.',
);

my $transaction;
lives_ok(
	sub
	{
		$transaction = DBIx::ScopedTransaction->new( $dbh );
	},
	'Create a transaction object.',
);

lives_ok
(
	sub
	{
		open( STDERR, '>', File::Spec->devnull() ) || die "could not open STDERR: $!";
	},
	'Redirect STDERR to clean test output.',
);

throws_ok(
	sub
	{
		my $transaction2 = DBIx::ScopedTransaction->new( $dbh );
	},
	qr/DBD::([^:]+)::db begin_work failed: Already in a transaction/,
	'Fail to start two simultaneous transactions on the same database handle.',
);

lives_ok(
	sub
	{
		undef $transaction;
	},
	'Destroy transaction object.',
);
