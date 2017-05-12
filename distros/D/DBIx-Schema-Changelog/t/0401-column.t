use Test::Requires qw(DBI DBD::SQLite);
use Test::More tests => 10;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );
use strict;
use warnings;
use DBI;
use DBIx::Schema::Changelog::Driver::SQLite;
my $driver = new_ok('DBIx::Schema::Changelog::Driver::SQLite')
  or plan skip_all => 'Could not initiate driver!';

require_ok('DBI');
use_ok 'DBI';

require_ok('DBIx::Schema::Changelog::Action::Columns');
use_ok 'DBIx::Schema::Changelog::Action::Columns';

my $dbh = DBI->connect("dbi:SQLite:database=.tmp.sqlite")
  or plan skip_all => $DBI::errstr;
my $object = DBIx::Schema::Changelog::Action::Columns->new(
    driver => $driver,
    dbh    => $dbh
);

can_ok( 'DBIx::Schema::Changelog::Action::Columns',
    @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'DBIx::Schema::Changelog::Action::Columns' );

is(
    $object->add(
        { table => '"user"', name => 'drop_test', type => 'integer' }, ''
    ),
    'ADD COLUMN drop_test INTEGER  ',
    'Add column test.'
);
is(
    $object->alter(
        {
            table  => '"user"',
            name   => 'drop_test',
            type   => 'varchar',
            lenght => 255
        }
    ),
    undef,
    'Alter column test.'
);
is( $object->drop( { table => '"user"', name => 'drop_test' } ),
    undef, 'Drop column test.' );
$dbh->disconnect();
