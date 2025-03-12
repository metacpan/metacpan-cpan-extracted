use strict;
use warnings;

#https://estuary.dev/postgresql-triggers/

use Path::Tiny qw( cwd );

use lib cwd->child( qw( t lib ) )->stringify;

use Test::More import => [ qw( is note ok plan subtest ) ];
use Test::PgTAP import => [ qw( tables_are triggers_are ) ];
use Test::DatabaseRow qw( all_row_ok );

use DBI                     qw();
use DBI::Const::GetInfoType qw( %GetInfoType );

eval { require Test::PostgreSQL };
plan skip_all => 'Test::PostgreSQL required' unless $@ eq '';

my $pgsql = eval { Test::PostgreSQL->new } or do {
  no warnings 'once';
  plan skip_all => $Test::PostgreSQL::errstr;
};
note 'managed schema: ', my $managed_schema = 'myschema';
note 'dsn: ',            my $dsn            = $pgsql->dsn . ';options=--client_min_messages=WARNING';
local $Test::PgTAP::Dbh = DBI->connect( $dsn . ";options=--search_path=$managed_schema" );

plan tests => 9;

require DBIx::Migration::Pg;

my $m = DBIx::Migration::Pg->new(
  managed_schema => $managed_schema,
  dsn            => $dsn,
  dir            => cwd->child( qw( t sql trigger ) )
);
my $tracking_schema = $m->tracking_schema;

sub migrate_to_version_assertion {
  my ( $version ) = @_;
  plan tests => 2;

  ok $m->migrate( $version ), 'Migrate';
  is $m->version, $version, 'Check version';
}

my $target_version = 1;
subtest "Migrate to version $target_version" => \&migrate_to_version_assertion, $target_version;

tables_are $managed_schema, [ qw( products ) ], 'Check tables';
tables_are [ "$tracking_schema.dbix_migration", "$managed_schema.products" ];

$target_version = 2;
subtest "Migrate to version $target_version" => \&migrate_to_version_assertion, $target_version;
tables_are $managed_schema, [ qw( products product_price_changes ) ], 'Check tables';
tables_are [ "$tracking_schema.dbix_migration", map { "$managed_schema.$_" } qw( products product_price_changes ) ];
triggers_are $managed_schema, 'products', [ qw( price_changes ) ];
triggers_are 'products', [ "$managed_schema.price_changes" ];

subtest 'check that the trigger does work' => sub {
  plan tests => 3;

  my $sth = $Test::PgTAP::Dbh->prepare( "INSERT INTO $managed_schema.products (name, price) VALUES (?, ?);" );
  ok $sth->execute( 'Product 1', 10.0 ), 'insert a product';

  $sth = $Test::PgTAP::Dbh->prepare( "UPDATE $managed_schema.products SET price = ? WHERE id = ?;" );
  ok $sth->execute( 20.0, 1 ), 'update the previously inserted product';

  local $Test::DatabaseRow::dbh = $m->dbh;
  all_row_ok(
    sql         => "SELECT * FROM $managed_schema.product_price_changes;",
    tests       => [ id => 1, product_id => 1, old_price => 10.0, new_price => 20.0 ],
    description => 'check product changes row'
  );
};
