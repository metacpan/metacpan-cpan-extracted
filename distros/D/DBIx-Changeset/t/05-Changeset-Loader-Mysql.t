#!perl 

use Test::More qw(no_plan); #tests => 11;
use Test::Exception;
use DBIx::Changeset::Loader;
use DBIx::Changeset::Record;

use lib './t/lib';

BEGIN {
	use_ok( 'DBIx::Changeset::Loader::Mysql' );
}

diag( "Testing DBIx::Changeset::Loader::Mysql $DBIx::Changeset::Loader::Mysql::VERSION, Perl $], $^X" );

my $loader = DBIx::Changeset::Loader->new('mysql');

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
my $record = DBIx::Changeset::Record->new('disk', { changeset_location => './t/data', uri => '20020505_blank_valid.sql' } );

## missing db_user
throws_ok(sub { $loader->apply_changeset($record) }, 'DBIx::Changeset::Exception::LoaderException', 'throws for missing db_name');
throws_ok(sub { $loader->apply_changeset($record) }, qr/db_name/, 'throws for missing db_name');

SKIP: {
	skip 'Set $ENV{MYSQL_TEST} to a true value to run all mysql tests. DBD_MYSQL_DBNAME, DBD_MYSQL_USER and DBD_MYSQL_PASSWD can be used to change the defult db of test', 1 unless defined $ENV{MYSQL_TEST};
	my $db   = $ENV{DBD_MYSQL_DBNAME} || 'test';
	my $user = $ENV{DBD_MYSQL_USER}   || '';
	my $pass = $ENV{DBD_MYSQL_PASSWD} || '';

	my $loader2 = DBIx::Changeset::Loader->new('mysql', {db_user => $user, db_pass => $pass, db_name => $db });

	lives_ok(sub { $loader2->apply_changeset($record) }, 'can apply changeset');

	### ok try with some bogus sql
	my $naff_record = DBIx::Changeset::Record->new('disk', { changeset_location => './t/data', uri => '20010505_1.sql' } );
	throws_ok(sub { $loader2->apply_changeset($naff_record) }, 'DBIx::Changeset::Exception::LoaderException', 'Got Loader exception with naff sql');
	throws_ok(sub { $loader2->apply_changeset($naff_record) }, qr/INVALIDSQLCOMMAND OVER THERE/, 'Got Loader exception with naff sql');
};
