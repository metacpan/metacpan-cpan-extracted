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

my $database_handle;
lives_ok(
	sub
	{
		$database_handle = $transaction->get_database_handle();
	},
	'Retrieve the database handle tied to the transaction object.',
);

is(
	$dbh,
	$database_handle,
	'The database handle from the transaction object matches the one supplied to create the object.',
);

lives_ok
(
	sub
	{
		open( STDERR, '>', File::Spec->devnull() ) || die "could not open STDERR: $!";
	},
	'Redirect STDERR to destroy transaction object silently.',
);

lives_ok(
	sub
	{
		undef $transaction;
	},
	'Destroy transaction object.',
);

undef $dbh;
