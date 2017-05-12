#!perl -T

use strict;
use warnings;

use DBI;
use DBIx::ScopedTransaction;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 8;

use lib 't/lib';
use LocalTest;


my $dbh = LocalTest::ok_database_handle();

ok(
	bless( $dbh, 'DBI::db::Test' ),
	'Override rollback() method of the underlying database handle.',
);

my $destroy_logs = [];
ok(
	local $DBIx::ScopedTransaction::DESTROY_LOGGER = sub
	{
		my ( $messages ) = @_;
		push( @$destroy_logs, @$messages );
	},
	'Set up capture of messages from DBIx::ScopedTransaction::DESTROY.',
);

{
	my $transaction;
	lives_ok(
		sub
		{
			$transaction = DBIx::ScopedTransaction->new( $dbh );
		},
		'Create a transaction object.',
	);
}
note('Transaction object should have gone out of scope now.');

isnt(
	scalar( @$destroy_logs ),
	0,
	'Detected issues when transaction object was destroyed.',
) || diag( explain( $destroy_logs ) );

is(
	scalar(
		grep { $_ =~ /\ATransaction object created at .*? is going out of scope, but the transaction has not been committed or rolled back; check logic\.\Z/ }
		@$destroy_logs
	),
	1,
	'Found warning explaining where the transaction was started and that is was not completed properly.',
) || diag( explain( $destroy_logs ) );

is(
	scalar( grep { $_ eq 'Could not roll back transaction to resolve the issue.' } @$destroy_logs ),
	1,
	'Found warning to explain the rollback initiated by the object failed.',
) || diag( explain( $destroy_logs ) );

is(
	scalar( @$destroy_logs ),
	2,
	'No unexpected issues reported.',
) || diag( explain( $destroy_logs ) );


# Subclass DBI::db and override rollback() to make it fail.
package DBI::db::Test;

use base 'DBI::db';

sub rollback
{
	return 0;
}

1;
