#!perl -T

use Test::More qw(no_plan); #tests => 11;
use Test::Exception;

use lib './t/lib';

BEGIN {
	use_ok( 'DBIx::Changeset::Loader' );
}
use DBIx::Changeset::Record;

diag( "Testing DBIx::Changeset::Loader $DBIx::Changeset::Loader::VERSION, Perl $], $^X" );

my @registered_classes = DBIx::Changeset::Loader->get_registered_classes;
is( scalar @registered_classes, 2, 'Number of classes registered so far' );
is( $registered_classes[0], 'DBIx::Changeset::Loader::Mysql', 'Mysql class registered' );
is( $registered_classes[1], 'DBIx::Changeset::Loader::Pg', 'Pg class registered' );

my @registered_types = DBIx::Changeset::Loader->get_registered_types;
is( scalar @registered_types, 2, 'Number of types registered so far' );
is( $registered_types[0], 'mysql', 'Mysql type registered' );
is( $registered_types[1], 'pg', 'Pg type registered' );

### add a simple test factory so we can test the DBIx::Changeset::Record base func
DBIx::Changeset::Loader->add_factory_type( 'test' => FactoryLoaderTest );

my $loader = DBIx::Changeset::Loader->new('test');

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

# lives valid
my $record = DBIx::Changeset::Record->new('disk', { changeset_location => './t/data', uri => '20020505_blank_valid.sql' } );
lives_ok(sub { $loader->apply_changeset($record) }, 'can apply changeset');
