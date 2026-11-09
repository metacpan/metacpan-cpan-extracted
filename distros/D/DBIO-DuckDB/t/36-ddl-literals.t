use strict;
use warnings;
use Test::More;

# Found by the conformance DDL list (karr k49): a quote in a default string,
# an ENUM column, a reserved word as name, and a UNIQUE constraint written in
# CREATE TABLE. Each is checked against a real database, not only the text.

use DBIO::DuckDB::Test;

my $schema = DBIO::DuckDB::Test->init_schema(no_deploy => 1);
my $dbh    = $schema->storage->dbh;

{
  package T36::Schema;
  use base 'DBIO::Schema';
  package T36::Order;
  use base 'DBIO::Core';
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_nullable => 0 },
    group => { data_type => 'varchar', size => 20, is_nullable => 0,
               default_value => "it's" },
    kind  => { data_type => 'enum', extra => { list => [ "it's", 'plain' ] },
               is_nullable => 1 },
    a     => { data_type => 'integer', is_nullable => 1 },
    b     => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(order_ab => [ 'a', 'b' ]);
  T36::Schema->register_class(Order => 'T36::Order');
}

use DBIO::DuckDB::DDL;
use DBIO::DuckDB::Introspect;

my $ddl = DBIO::DuckDB::DDL->install_ddl('T36::Schema');
like $ddl, qr/DEFAULT 'it''s'/, 'a quote in a default string is doubled';
like $ddl, qr/ENUM\('it''s', 'plain'\)/, 'an ENUM column carries its values';
like $ddl, qr/CREATE TABLE "order"/, 'a reserved word is quoted';

$dbh->do($_) for grep { /\S/ } split /(?<=;)\n/, $ddl;
$dbh->do(q{INSERT INTO "order" (id, kind) VALUES (1, 'it''s')});
is $dbh->selectrow_array(q{SELECT "group" FROM "order" WHERE id = 1}), "it's",
  'the default string is read back whole';

my $intro = DBIO::DuckDB::Introspect->new(dbh => $dbh);
is_deeply [ map { $_->[1] } @{ $intro->table_uniq_info('order') } ], [ [ 'a', 'b' ] ],
  'a UNIQUE constraint of CREATE TABLE is a unique of the table';

done_testing;
