#!perl 

use Test::More qw(no_plan); #tests => 11;
use Test::Exception;
use DBIx::Changeset::Loader;
use DBIx::Changeset::Record;

use lib './t/lib';

BEGIN {
	use_ok( 'DBIx::Changeset::Loader::Pg' );
}

diag( "Testing DBIx::Changeset::Loader::Pg $DBIx::Changeset::Loader::Pg::VERSION, Perl $], $^X" );

my $loader = DBIx::Changeset::Loader->new('pg');

### testing starting transaction
lives_ok(sub { $loader->start_transaction() }, 'Can start transaction');

### test rollback transaction
lives_ok(sub { $loader->rollback_transaction() }, 'Can rollback transaction');

### test commit transaction
lives_ok(sub { $loader->commit_transaction() }, 'Can commit transaction');

### test applying_changeset
# throws first
throws_ok(sub { $loader->apply_changeset() }, 'DBIx::Changeset::Exception::LoaderException', 'Got LoaderException');
throws_ok(sub { $loader->apply_changeset() }, qr/Missing a DBIx::Changeset::Record/, 'Got LoaderException with correct message');

# valid record
my $record = DBIx::Changeset::Record->new('disk', { changeset_location => './t/data', uri => '320020505_blank_valid_pg.sql' } );

## missing db_user
throws_ok(sub { $loader->apply_changeset($record) }, 'DBIx::Changeset::Exception::LoaderException', 'throws for missing db_name');
throws_ok(sub { $loader->apply_changeset($record) }, qr/db_name/, 'throws for missing db_name');

SKIP: {
	skip 'Set $ENV{PG_TEST} to a true value to run all postgres tests through psql. DBD_PG_DBNAME, DBD_PG_USER and DBD_PG_PASSWD can be used to change the defult db of test', 1 unless defined $ENV{PG_TEST};
	my $db   = $ENV{DBD_PG_DBNAME} || 'test';
	my $user = $ENV{DBD_PG_USER}   || '';
	my $pass = $ENV{DBD_PG_PASSWD} || '';

	my $loader2 = DBIx::Changeset::Loader->new('pg', {db_user => $user, db_pass => $pass, db_name => $db });

	lives_ok(sub { $loader2->apply_changeset($record) }, 'can apply changeset');

	### ok try with some bogus sql
	my $naff_record = DBIx::Changeset::Record->new('disk', { changeset_location => './t/data', uri => '20010505_1.sql' } );
	throws_ok(sub { $loader2->apply_changeset($naff_record) }, 'DBIx::Changeset::Exception::LoaderException', 'Got Loader exception with naff sql');
	throws_ok(sub { $loader2->apply_changeset($naff_record) }, qr/INVALIDSQLCOMMAND OVER THERE/, 'Got Loader exception with naff sql');
};
