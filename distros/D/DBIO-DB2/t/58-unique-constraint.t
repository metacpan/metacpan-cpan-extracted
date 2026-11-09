use strict;
use warnings;

use Test::More;
use Test::Exception;

# OFFLINE (karr k39, ADR 0009). A source's unique_constraints reach the server
# as named UNIQUE constraints, and the diff knows them.
#
# Before: install_ddl never read unique_constraints, so an add_unique_constraint
# in a result class was silently not deployed. Db2 backs every UNIQUE constraint
# with an index of the same name (SYSCAT.INDEXES, system_required 1); the
# introspector saw that index as an ordinary unique index and the diff wanted to
# DROP it. Measured live (Db2 12.1.5): CONSTRAINT "uq_ab" UNIQUE ("b","a") gives
# SYSCAT.TABCONST type U, KEYCOLUSE colseq 1 = b, 2 = a, and an index "uq_ab".
#
# The model carries constraints as the DBIO::Introspect::Base contract says:
#   unique_constraints => { $table => [ [ $name, \@columns ], ... ] }
# The mock models below are in the catalog shape (not_null, not is_nullable).

use DBIO::DB2::DDL;
use DBIO::DB2::Diff;
use DBIO::DB2::Diff::Table;
use DBIO::DB2::Diff::UniqueConstraint;
use DBIO::DB2::Introspect;
use DBIO::DB2::Introspect::UniqueConstraints;
use DBIO::DB2::Introspect::Indexes;

{
  package My::K39::Schema::Item;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    sku  => { data_type => 'varchar', size => 20 },          # no is_nullable: NOT NULL
    shop => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(item_shop_sku => [qw(shop sku)]);
  __PACKAGE__->add_unique_constraint(item_sku      => ['sku']);
}
{
  package My::K39::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Item => 'My::K39::Schema::Item');
}
{
  package My::K39::Null::Item;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('maybe');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    email => { data_type => 'varchar', size => 50, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(maybe_email => ['email']);
}
{
  package My::K39::Null::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Item => 'My::K39::Null::Item');
}

# --- install_ddl ----------------------------------------------------------------

my $ddl = DBIO::DB2::DDL->install_ddl('My::K39::Schema');
like $ddl, qr/^  CONSTRAINT "item_shop_sku" UNIQUE \("shop", "sku"\)/m,
  'a multi-column constraint: named, quoted, in the order of the source';
like $ddl, qr/^  CONSTRAINT "item_sku" UNIQUE \("sku"\)/m, '... and a single-column one';
unlike $ddl, qr/CONSTRAINT "primary"/i, 'the primary constraint is not emitted as UNIQUE';
like $ddl, qr/PRIMARY KEY \("id"\),\n  CONSTRAINT "item_shop_sku".*,\n  CONSTRAINT "item_sku" UNIQUE \("sku"\)\n\);/s,
  '... inside CREATE TABLE, after the primary key, in name order, no standalone statement';
unlike $ddl, qr/CREATE\s+UNIQUE\s+INDEX/i, 'no CREATE UNIQUE INDEX for them';

# --- a nullable column is refused -----------------------------------------------

throws_ok { DBIO::DB2::DDL->install_ddl('My::K39::Null::Schema') }
  qr/"maybe_email".*"maybe".*"email".*SQL0542N|"maybe".*"email".*nullable/s,
  'a UNIQUE constraint over a nullable column is refused, naming table and column';

# --- Diff::Table create renders the same constraint -----------------------------

my @cols = (
  { column_name => 'id',   catalog_type => 'INTEGER', catalog_size => 4,  not_null => 1, is_pk => 1, is_auto_increment => 1 },
  { column_name => 'shop', catalog_type => 'INTEGER', catalog_size => 4,  not_null => 1 },
  { column_name => 'sku',  catalog_type => 'VARCHAR', catalog_size => 20, not_null => 1 },
);
my ($create) = DBIO::DB2::Diff::Table->diff(
  {}, { item => { table_name => 'item', kind => 'table' } },
  { item => \@cols }, {},
  { item => [ [ item_shop_sku => [qw(shop sku)] ], [ item_sku => ['sku'] ] ] },
);
like $create->as_sql, qr/^  CONSTRAINT "item_shop_sku" UNIQUE \("shop", "sku"\),\n  CONSTRAINT "item_sku" UNIQUE \("sku"\)\n\);/m,
  'Diff::Table create: the same clause, inline';

{
  my @nullable = (@cols[0,1], { %{ $cols[2] }, not_null => 0 });
  my ($op) = DBIO::DB2::Diff::Table->diff(
    {}, { item => { table_name => 'item', kind => 'table' } },
    { item => \@nullable }, {}, { item => [ [ item_sku => ['sku'] ] ] },
  );
  throws_ok { $op->as_sql } qr/"item_sku".*"item".*"sku"|"item".*"sku".*nullable/s,
    'Diff::Table create: a nullable column is refused here too';
}

# --- Diff::UniqueConstraint ------------------------------------------------------

my $T = { item => { table_name => 'item', kind => 'table' } };
{
  my @ops = DBIO::DB2::Diff::UniqueConstraint->diff(
    { item => [] }, { item => [ [ item_sku => ['sku'] ] ] }, $T, $T);
  is scalar(@ops), 1, 'a new constraint on an existing table: one operation';
  is $ops[0]->as_sql, 'ALTER TABLE "item" ADD CONSTRAINT "item_sku" UNIQUE ("sku");', '... ADD CONSTRAINT';
}
{
  my @ops = DBIO::DB2::Diff::UniqueConstraint->diff(
    { item => [ [ item_sku => ['sku'] ] ] }, { item => [] }, $T, $T);
  is scalar(@ops), 1, 'a constraint gone from the target: one operation';
  is $ops[0]->as_sql, 'ALTER TABLE "item" DROP UNIQUE "item_sku";', '... DROP UNIQUE';
}
{
  my @ops = DBIO::DB2::Diff::UniqueConstraint->diff(
    { item => [ [ item_sku => ['sku'] ] ] }, { item => [ [ item_sku => [qw(shop sku)] ] ] }, $T, $T);
  is_deeply [ map { $_->action } @ops ], [qw(drop add)], 'changed columns: drop, then add';
}
{
  my @ops = DBIO::DB2::Diff::UniqueConstraint->diff(
    { item => [ [ item_sku => ['sku'] ] ] }, {}, $T, $T);
  is scalar(@ops), 1, 'a table without an entry in the target still drops its constraint';
}
{
  my @ops = DBIO::DB2::Diff::UniqueConstraint->diff(
    { item => [ [ item_sku => ['sku'] ] ] }, { item => [ [ item_sku => ['sku'] ] ] }, $T, $T);
  is scalar(@ops), 0, 'the same constraint on both sides: nothing';
}
{
  my @ops = DBIO::DB2::Diff::UniqueConstraint->diff(
    { item => [ [ item_sku => ['sku'] ] ] }, {}, $T, {});
  is scalar(@ops), 0, 'a dropped table takes its constraint with it: nothing';
}

# --- the orchestrator -------------------------------------------------------------

{
  my $model = sub {
    my ($uc) = @_;
    return {
      tables  => $T, columns => { item => \@cols }, foreign_keys => {},
      indexes => {}, unique_constraints => $uc,
    };
  };
  my $same = DBIO::DB2::Diff->new(
    source => $model->({ item => [ [ item_sku => ['sku'] ] ] }),
    target => $model->({ item => [ [ item_sku => ['sku'] ] ] }),
  );
  ok !$same->has_changes, 'equal models with a constraint: no changes';

  my $diff = DBIO::DB2::Diff->new(
    source => $model->({ item => [] }), target => $model->({ item => [ [ item_sku => ['sku'] ] ] }));
  like $diff->as_sql, qr/ADD CONSTRAINT "item_sku" UNIQUE/, 'a new constraint reaches as_sql';

  # models from before the section existed
  my $old = $model->(undef); delete $old->{unique_constraints};
  lives_ok { DBIO::DB2::Diff->new(source => $old, target => $old)->operations }
    'a model without the section is not an error';
}

# --- Introspect::UniqueConstraints / Indexes (rows replayed from a mock handle) ----

{
  package Mock::K39::DBH;
  sub new { bless { rows => $_[1], sql => [] }, $_[0] }
  sub prepare { my ($s, $sql) = @_; push @{ $s->{sql} }, $sql; bless { rows => $s->{rows} }, 'Mock::K39::STH' }
  package Mock::K39::STH;
  sub execute { $_[0]{i} = 0; 1 }
  sub fetchrow_hashref { $_[0]{rows}[ $_[0]{i}++ ] }
}
{
  # KEYCOLUSE order: by constname, colseq
  my $dbh = Mock::K39::DBH->new([
    { tabname => 'item',  constname => 'a_uq', colname => 'b', colseq => 1 },
    { tabname => 'item',  constname => 'a_uq', colname => 'a', colseq => 2 },
    { tabname => 'item',  constname => 'z_uq', colname => 'c', colseq => 1 },
    { tabname => 'other', constname => 'o_uq', colname => 'x', colseq => 1 },
  ]);
  my $uc = DBIO::DB2::Introspect::UniqueConstraints->fetch($dbh, 'DB2INST1',
    { item => {}, other => {}, empty => {} });
  is_deeply $uc, {
    item  => [ [ a_uq => [qw(b a)] ], [ z_uq => ['c'] ] ],
    other => [ [ o_uq => ['x'] ] ],
    empty => [],
  }, 'constraints per table, columns in COLSEQ order, every table has an entry';
  like $dbh->{sql}[0], qr/type\s*=\s*'U'/i, 'read from SYSCAT.TABCONST type U';
}
{
  my $dbh = Mock::K39::DBH->new([]);
  DBIO::DB2::Introspect::Indexes->fetch($dbh, 'DB2INST1', {});
  like $dbh->{sql}[0], qr/syscat\.tabconst.*type\s*=\s*'U'/si,
    'Indexes: the index behind a UNIQUE constraint is left out (it is the constraint)';
}

# --- table_uniq_info keeps both -----------------------------------------------------

{
  my $intro = DBIO::DB2::Introspect->new(model => {
    tables  => $T, columns => {},
    indexes => { item => { by_name => { index_name => 'by_name', is_unique => 1, columns => ['name'] },
                           plain   => { index_name => 'plain',   is_unique => 0, columns => ['x'] } } },
    foreign_keys => {},
    unique_constraints => { item => [ [ item_sku => ['sku'] ] ] },
  });
  is_deeply $intro->table_uniq_info('item'),
    [ [ item_sku => ['sku'] ], [ by_name => ['name'] ] ],
    'table_uniq_info: the constraints and the unique indexes (db2_indexes), not only the section';
}

done_testing;
