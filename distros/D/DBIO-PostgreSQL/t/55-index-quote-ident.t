use strict;
use warnings;

use Test::More;

use lib 'lib';
use DBIO::PostgreSQL::DDL;

# karr k60 -- index key and INCLUDE columns must quote identifiers like the
# rest of install_ddl, instead of interpolating them raw.
#
# WHY this test exists: a column name that is a reserved word or needs
# quoting (e.g. 'order') produced broken SQL in the pg_index rendering while
# every other identifier in the file went through the core _quote_ident. That
# one only quotes on shape, so the reserved word got a layer of its own here
# (_quote_pg_ident). Since karr k115 there is one rule for every name
# install_ddl writes, DBIO::PostgreSQL::Util::quote_ident -- t/89 holds it for
# the other sites; this file keeps holding it for the index. The point is not
# "order is interpolated" -- it is "a reserved-word key or INCLUDE column
# deploys as the double-quoted identifier PostgreSQL accepts".

{
  package QuoteDDL::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('auth');
}

{
  package QuoteDDL::Schema::Result::User;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_nullable => 0 },
    email => { data_type => 'text',    is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  # The reserved word as a plain key column ...
  __PACKAGE__->pg_index('idx_order' => {
    columns => ['order'],
  });

  # ... as an INCLUDE column ...
  __PACKAGE__->pg_index('idx_order_cover' => {
    columns => ['email'],
    include => ['order'],
  });

  # ... and as a key column with an operator class, which stays outside the
  # quotes.
  __PACKAGE__->pg_index('idx_order_opclass' => {
    columns   => ['order'],
    opclasses => { order => 'int4_ops' },
  });

  # Plain identifiers must stay bare -- the quoting is additive, not absolute.
  __PACKAGE__->pg_index('idx_plain' => {
    columns => ['email'],
    include => ['id'],
  });
}

QuoteDDL::Schema->register_class(
  User => 'QuoteDDL::Schema::Result::User',
);

my $sql = DBIO::PostgreSQL::DDL->install_ddl('QuoteDDL::Schema');

like(
  $sql,
  qr/\QCREATE INDEX idx_order ON auth.users ("order");\E/,
  'a reserved-word key column deploys double-quoted',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_order_cover ON auth.users (email) INCLUDE ("order");\E/,
  'a reserved-word INCLUDE column deploys double-quoted',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_order_opclass ON auth.users ("order" int4_ops);\E/,
  'the operator class suffix stays outside the quotes',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_plain ON auth.users (email) INCLUDE (id);\E/,
  'plain identifiers stay bare -- quoting is unchanged for simple names',
);

unlike($sql, qr/\(order\b/, 'no bare reserved word appears in an index key or INCLUDE list');

done_testing;
