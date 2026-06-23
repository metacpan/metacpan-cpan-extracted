use strict;
use warnings;

# Pin a DBD::Oracle version so Columns.pm's nchar_size_factor branch is
# deterministic offline (no real DBD::Oracle loaded).
BEGIN { $DBD::Oracle::VERSION = 1.80 }

use Test::More;

use DBIO::Oracle::Introspect::Columns;
use DBIO::Oracle::Introspect::Indexes;
use DBIO::Oracle::Introspect::ForeignKeys;
use DBIO::Oracle::Introspect::Keys;

# ---------------------------------------------------------------------------
# Minimal mock dbh: dispatches each query to a fixture set by SQL regex.
# Each fixture is an arrayref of row-hashrefs (for fetchrow_hashref) or
# arrayrefs (for fetchrow_array). Rows are cloned per execute so repeated
# executes (e.g. per-table column queries) each get a fresh stream.
# ---------------------------------------------------------------------------
{
  package Mock::Dbh;
  sub new { bless { dispatch => $_[1] }, $_[0] }
  sub prepare        { Mock::Sth->new($_[0], $_[1]) }
  sub prepare_cached { Mock::Sth->new($_[0], $_[1]) }
  sub _rows_for {
    my ($self, $sql, $bind) = @_;
    for my $d (@{ $self->{dispatch} }) {
      return $d->{rows}->($bind) if $sql =~ $d->{re};
    }
    return [];
  }

  package Mock::Sth;
  sub new { bless { dbh => $_[1], sql => $_[2], rows => [] }, $_[0] }
  sub execute {
    my ($self, @bind) = @_;
    $self->{rows} = $self->{dbh}->_rows_for($self->{sql}, \@bind);
    return 1;
  }
  sub fetchrow_hashref { shift @{ $_[0]{rows} } }
  sub fetchrow_array   { my $r = shift @{ $_[0]{rows} }; return $r ? @$r : () }
  sub finish {}
}

my $SCHEMA = 'TESTUSER';
my $tables = { ORDERS => { table_name => 'ORDERS', kind => 'table', schema => $SCHEMA } };

# ---------------------------------------------------------------------------
# Columns: default-value parsing, sequence-from-trigger, not_null.
# ---------------------------------------------------------------------------
{
  my $dbh = Mock::Dbh->new([
    { re => qr/all_tab_columns/i, rows => sub {
        [
          { column_name => 'ID',      data_type => 'NUMBER',   data_length => 22,
            data_precision => 10, data_scale => 0, nullable => 'N',
            data_default => undef, column_id => 1 },
          { column_name => 'STATUS',  data_type => 'VARCHAR2', data_length => 20,
            data_precision => undef, data_scale => undef, nullable => 'Y',
            data_default => "'new'", column_id => 2 },
          { column_name => 'CREATED', data_type => 'DATE',     data_length => 7,
            data_precision => undef, data_scale => undef, nullable => 'N',
            data_default => 'sysdate', column_id => 3 },
          { column_name => 'NOTE',    data_type => 'VARCHAR2', data_length => 100,
            data_precision => undef, data_scale => undef, nullable => 'Y',
            data_default => 'NULL', column_id => 4 },
        ];
    } },
    { re => qr/all_triggers/i, rows => sub {
        [ [ q{BEGIN SELECT "TESTUSER"."ORDERS_SEQ".nextval INTO :new.id FROM dual; END;} ] ];
    } },
  ]);

  my $cols = DBIO::Oracle::Introspect::Columns->fetch($dbh, $SCHEMA, $tables);
  my @c = @{ $cols->{ORDERS} };
  is(scalar @c, 4, 'four columns in column_id order');
  is($c[0]{column_name}, 'ID', 'first col ID');

  is($c[0]{not_null}, 1, 'ID not null (nullable=N)');
  is($c[1]{not_null}, 0, 'STATUS nullable (nullable=Y)');

  is($c[1]{default_value}, 'new', 'quoted literal default unquoted');
  is(ref $c[2]{default_value}, 'SCALAR', 'sysdate default is an expression ref');
  is(${ $c[2]{default_value} }, 'current_timestamp', 'sysdate -> current_timestamp');
  is(ref $c[3]{default_value}, 'SCALAR', 'NULL default is a ref');
  is(${ $c[3]{default_value} }, 'null', 'NULL default value');

  is($c[0]{is_auto_increment}, 1, 'ID auto_increment from trigger');
  is($c[0]{sequence}, 'testuser.orders_seq', 'sequence parsed from trigger body');
  ok(!$c[1]{is_auto_increment}, 'STATUS not auto_increment');
}

# ---------------------------------------------------------------------------
# Keys: multi-column PK ordering + unique constraint grouping/sorting.
# ---------------------------------------------------------------------------
{
  my $t = {
    ORDER_ITEM => { table_name => 'ORDER_ITEM', kind => 'table', schema => $SCHEMA },
  };
  # The real fetch relies on the SQL ORDER BY position; the mock preserves the
  # row order it is given, so feed rows already in position order to mirror
  # what Oracle returns.
  my $dbh = Mock::Dbh->new([
    { re => qr/all_constraints/i, rows => sub {
        [
          { constraint_name => 'OI_PK', constraint_type => 'P',
            table_name => 'ORDER_ITEM', column_name => 'ORDER_ID', position => 1 },
          { constraint_name => 'OI_PK', constraint_type => 'P',
            table_name => 'ORDER_ITEM', column_name => 'ITEM_ID',  position => 2 },
          { constraint_name => 'OI_SKU_UK', constraint_type => 'U',
            table_name => 'ORDER_ITEM', column_name => 'SKU', position => 1 },
        ];
    } },
  ]);

  my $keys = DBIO::Oracle::Introspect::Keys->fetch($dbh, $SCHEMA, $t);
  is_deeply($keys->{primary}{ORDER_ITEM}, ['ORDER_ID', 'ITEM_ID'],
    'composite PK columns in position order');
  is_deeply($keys->{unique}{ORDER_ITEM}, [ [ 'OI_SKU_UK' => ['SKU'] ] ],
    'unique constraint grouped under its name');
}

# ---------------------------------------------------------------------------
# ForeignKeys: multi-column FK ordering, on_delete, deferrable.
# ---------------------------------------------------------------------------
{
  my $t = {
    ORDER_ITEM => { table_name => 'ORDER_ITEM', kind => 'table', schema => $SCHEMA },
  };
  my $dbh = Mock::Dbh->new([
    { re => qr/all_constraints/i, rows => sub {
        [
          { fk_name => 'OI_ORDER_FK', from_table => 'ORDER_ITEM',
            from_column => 'ORDER_ID', from_pos => 1,
            to_table => 'ORDERS', to_column => 'ID', to_pos => 1,
            on_delete => 'CASCADE', is_deferrable => 1 },
          { fk_name => 'OI_ORDER_FK', from_table => 'ORDER_ITEM',
            from_column => 'TENANT_ID', from_pos => 2,
            to_table => 'ORDERS', to_column => 'TENANT_ID', to_pos => 2,
            on_delete => 'CASCADE', is_deferrable => 1 },
        ];
    } },
  ]);
  my $fks = DBIO::Oracle::Introspect::ForeignKeys->fetch($dbh, $SCHEMA, $t);
  my $fk = $fks->{ORDER_ITEM}[0];
  is($fk->{fk_name}, 'OI_ORDER_FK', 'fk name');
  is_deeply($fk->{from_columns}, ['ORDER_ID', 'TENANT_ID'], 'fk from columns in position order');
  is_deeply($fk->{to_columns},   ['ID', 'TENANT_ID'],       'fk to columns in position order');
  is($fk->{to_table}, 'ORDERS', 'fk target table');
  is($fk->{on_delete}, 'CASCADE', 'fk on_delete');
  is($fk->{is_deferrable}, 1, 'fk deferrable');
}

# ---------------------------------------------------------------------------
# Indexes: multi-column ordering + uniqueness mapping.
# ---------------------------------------------------------------------------
{
  my $t = {
    ORDERS => { table_name => 'ORDERS', kind => 'table', schema => $SCHEMA },
  };
  my $dbh = Mock::Dbh->new([
    { re => qr/all_indexes/i, rows => sub {
        [
          { index_name => 'IX_ORDERS_CUST', uniqueness => 'NONUNIQUE',
            index_type => 'NORMAL', table_name => 'ORDERS',
            column_name => 'CUSTOMER_ID', column_position => 1 },
          { index_name => 'IX_ORDERS_CUST', uniqueness => 'NONUNIQUE',
            index_type => 'NORMAL', table_name => 'ORDERS',
            column_name => 'CREATED', column_position => 2 },
          { index_name => 'UX_ORDERS_NUM', uniqueness => 'UNIQUE',
            index_type => 'NORMAL', table_name => 'ORDERS',
            column_name => 'ORDER_NUM', column_position => 1 },
        ];
    } },
  ]);
  my $idx = DBIO::Oracle::Introspect::Indexes->fetch($dbh, $SCHEMA, $t);
  is_deeply($idx->{ORDERS}{IX_ORDERS_CUST}{columns}, ['CUSTOMER_ID', 'CREATED'],
    'composite index columns in position order');
  is($idx->{ORDERS}{IX_ORDERS_CUST}{is_unique}, 0, 'nonunique index');
  is($idx->{ORDERS}{UX_ORDERS_NUM}{is_unique}, 1, 'unique index');
}

done_testing;
