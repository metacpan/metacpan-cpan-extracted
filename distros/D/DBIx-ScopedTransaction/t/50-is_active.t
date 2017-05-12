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

my $transaction;
lives_ok(
	sub
	{
		$transaction = DBIx::ScopedTransaction->new( $dbh );
	},
	'Create a transaction object.',
);

ok(
	$transaction->is_active(),
	'The transaction object is active.',
);

lives_ok
(
	sub
	{
		open( STDERR, '>', File::Spec->devnull() ) || die "could not open STDERR: $!";
	},
	'Redirect STDERR to destroy transaction object silently.',
);

lives_ok
(
	sub
	{
		$transaction->rollback() || die 'Failed to roll back transaction';
	},
	'Roll back transaction.',
);

ok(
	!$transaction->is_active(),
	'The transaction object is inactive.',
);
