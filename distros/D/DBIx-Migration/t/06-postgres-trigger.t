use strict;
use warnings;

#https://estuary.dev/postgresql-triggers/

use File::Spec::Functions qw( catdir curdir );

use lib catdir( curdir, qw( t lib ) );

use Test::More import => [ qw( is note ok plan subtest ) ];
use Test::PgTAP import => [ qw( tables_are ) ];
use Test::DatabaseRow qw( all_row_ok );

use DBI                     qw();
use DBI::Const::GetInfoType qw( %GetInfoType );

eval { require Test::PostgreSQL };
plan skip_all => 'Test::PostgresSQL required' unless $@ eq '';

my $pgsql = eval { Test::PostgreSQL->new } or do {
  no warnings 'once';
  plan skip_all => $Test::PostgreSQL::errstr;
};
note 'dsn: ', $pgsql->dsn;
local $Test::PgTAP::Dbh = DBI->connect( $pgsql->dsn );

plan tests => 6;

require DBIx::Migration;

my $m = DBIx::Migration->new( dsn => $pgsql->dsn, dir => catdir( curdir, qw( t sql trigger ) ) );

sub migrate_to_version_assertion {
  my ( $version ) = @_;
  plan tests => 2;

  ok $m->migrate( $version ), 'Migrate';
  is $m->version, $version, 'Check version';
}

my $target_version = 1;
subtest "Migrate to version $target_version" => \&migrate_to_version_assertion, $target_version;

# these are the same assertions that should test tables_are
tables_are 'public', [ qw( dbix_migration products ) ], 'Check tables';
tables_are [ qw( dbix_migration products ) ];

$target_version = 2;
subtest "Migrate to version $target_version" => \&migrate_to_version_assertion, $target_version;
tables_are [ qw( dbix_migration products product_price_changes ) ];

subtest 'check that the trigger does work' => sub {
  plan tests => 3;

  my $sth = $m->dbh->prepare( 'INSERT INTO products (name, price) VALUES (?, ?);' );
  ok $sth->execute( 'Product 1', 10.0 ), 'insert a product';

  $sth = $m->dbh->prepare( 'UPDATE products SET price = ? WHERE id = ?' );
  ok $sth->execute( 20.0, 1 ), 'update the previously inserted product';

  local $Test::DatabaseRow::dbh = $m->dbh;
  all_row_ok(
    sql         => 'SELECT * FROM product_price_changes',
    tests       => [ id => 1, product_id => 1, old_price => 10.0, new_price => 20.0 ],
    description => 'check product changes row'
  );
};
