use Test::Requires qw(DBI DBD::SQLite);
use Test::More tests => 11;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );
use strict;
use warnings;
use DBI;
use DBIx::Schema::Changelog::Driver::SQLite;

require_ok('DBI');
use_ok 'DBI';

require_ok('DBIx::Schema::Changelog::Driver::SQLite');
use_ok 'DBIx::Schema::Changelog::Driver::SQLite';

require_ok('DBIx::Schema::Changelog::Action::Views');
use_ok 'DBIx::Schema::Changelog::Action::Views';

my $dbh = DBI->connect("dbi:SQLite:database=.tmp.sqlite")
  or plan skip_all => $DBI::errstr;
my $driver = DBIx::Schema::Changelog::Driver::SQLite->new();
my $object =
  DBIx::Schema::Changelog::Action::Views->new( driver => $driver, dbh => $dbh );

can_ok( 'DBIx::Schema::Changelog::Action::Views',
    @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'DBIx::Schema::Changelog::Action::Views' );

is(
    $object->add(
        {
            name => 'view_test',
            as =>
'SELECT "user".pass, "user".salt, "user".locale, "user".last_login FROM client, company, "user" WHERE client.id = company.id AND company.id = "user".id AND "user".id = client.id'
        }
    ),
    '0E0',
    'Creating view failed'
);
is(
    $object->alter(
        {
            name => 'view_test',
            as =>
'SELECT "user".active, "user".name, company.name AS company, client.id FROM client, company, "user" WHERE client.id = company.id AND company.id = "user".id AND "user".id = client.id'
        }
    ),
    '0E0',
    'Creating view failed'
);
is( $object->drop( { name => 'view_test' } ), '0E0', 'Drop view failed' );
$dbh->disconnect();
