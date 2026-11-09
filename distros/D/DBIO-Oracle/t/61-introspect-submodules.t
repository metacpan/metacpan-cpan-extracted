use strict;
use warnings;

# Pin a DBD::Oracle version so Columns.pm's nchar_size_factor branch is
# deterministic offline (no real DBD::Oracle loaded).
BEGIN { $DBD::Oracle::VERSION = 1.80 }

use Test::More;

use DBIO::Oracle::Introspect::Tables;
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
  sub func {
    my ($self, $what) = @_;
    return $what eq 'ora_server_version' ? [ $self->{version} // 19, 0 ] : undef;
  }
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
  # DBD::Oracle reports column names in upper case, so a row fetched as a
  # hash has upper-case keys unless the caller asks for NAME_lc. The mock
  # does the same -- the fixtures below are written in lower case, and a
  # reader that forgets to ask gets keys it does not know, as it would from
  # a server (t/57-introspect-live.t is where that was found).
  sub fetchrow_hashref {
    my ($self, $name) = @_;
    my $row = shift @{ $self->{rows} } or return;
    return $row if ( $name // 'NAME' ) eq 'NAME_lc';
    return { map { uc($_) => $row->{$_} } keys %$row };
  }
  sub fetchrow_array   { my $r = shift @{ $_[0]{rows} }; return $r ? @$r : () }
  sub finish {}
}

my $SCHEMA = 'TESTUSER';
my $tables = { ORDERS => { table_name => 'ORDERS', kind => 'table', schema => $SCHEMA } };

# ---------------------------------------------------------------------------
# Tables: tables and views, each under its name.
# ---------------------------------------------------------------------------
{
  my $dbh = Mock::Dbh->new([
    { re => qr/all_tables/i, rows => sub {
        [
          { table_name => 'ORDERS',   kind => 'table' },
          { table_name => 'V_ORDERS', kind => 'view'  },
        ];
    } },
  ]);

  is_deeply(
    DBIO::Oracle::Introspect::Tables->fetch($dbh, $SCHEMA),
    {
      ORDERS   => { table_name => 'ORDERS',   kind => 'table', schema => $SCHEMA },
      V_ORDERS => { table_name => 'V_ORDERS', kind => 'view',  schema => $SCHEMA },
    },
    'tables and views keyed by name, with their kind',
  );
}

# ---------------------------------------------------------------------------
# Views: the definition of each view (karr k65), LONG read with room for it.
# ---------------------------------------------------------------------------
{
  use DBIO::Oracle::Introspect::Views;
  my %seen;
  my $dbh = Mock::Dbh->new([
    { re => qr/all_views/i, rows => sub {
        $seen{bind} = $_[0];
        [
          { view_name => 'V_ORDERS', text => 'SELECT "id" FROM "orders"' },
          { view_name => 'V_OTHER',  text => 'SELECT 1 FROM dual' },
          { view_name => 'ORDERS',   text => 'a table is no view' },
        ];
    } },
    { re => qr/all_tab_columns/i, rows => sub {
        $seen{col_bind} = $_[0];
        [
          { table_name => 'V_ORDERS', column_name => 'id' },
          { table_name => 'V_OTHER',  column_name => 'A' },
          { table_name => 'V_OTHER',  column_name => 'b' },
          { table_name => 'ORDERS',   column_name => 'not a view' },
        ];
    } },
    { re => qr/all_dependencies/i, rows => sub {
        $seen{dep_bind} = $_[0];
        [
          { name => 'V_OTHER', referenced_owner => $SCHEMA, referenced_name => 'V_ORDERS' },
          { name => 'V_OTHER', referenced_owner => 'OWNX',  referenced_name => 'V_FAR' },
        ];
    } },
  ]);
  my $tables = {
    ORDERS   => { table_name => 'ORDERS',   kind => 'table', schema => $SCHEMA },
    V_ORDERS => { table_name => 'V_ORDERS', kind => 'view',  schema => $SCHEMA },
    V_OTHER  => { table_name => 'V_OTHER',  kind => 'view',  schema => $SCHEMA },
  };
  $dbh->{LongReadLen} = 80;
  $dbh->{LongTruncOk} = 1;

  is_deeply(
    DBIO::Oracle::Introspect::Views->fetch($dbh, $SCHEMA, $tables),
    {
      V_ORDERS => { view_name => 'V_ORDERS', definition => 'SELECT "id" FROM "orders"',
                    columns => [ 'id' ], depends_on => [] },
      V_OTHER  => { view_name => 'V_OTHER',  definition => 'SELECT 1 FROM dual',
                    columns => [ 'A', 'b' ], depends_on => [ 'V_ORDERS', 'OWNX.V_FAR' ] },
    },
    'views keyed by name with their definition; only objects of kind view',
  );
  is_deeply($seen{bind}, [ $SCHEMA ], '... asked for the schema');
  is_deeply($seen{col_bind}, [ $SCHEMA ], '... for the names of their columns (a column list is not in the text)');
  is_deeply($seen{dep_bind}, [ $SCHEMA ], '... and for its view dependencies: bare in this schema, owner.view otherwise');
  is($dbh->{LongReadLen}, 80, 'the handle\'s LongReadLen is restored');
  is($dbh->{LongTruncOk}, 1, '... and its LongTruncOk');

  my $untouched = Mock::Dbh->new([ { re => qr/./, rows => sub { die 'asked' } } ]);
  is_deeply(
    DBIO::Oracle::Introspect::Views->fetch($untouched, $SCHEMA, { ORDERS => $tables->{ORDERS} }),
    {}, 'without a view the server is not asked',
  );
}

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
  ok(!defined $c[3]{default_value}, 'DEFAULT NULL is no default (karr k63)');

  is($c[0]{is_auto_increment}, 1, 'ID auto_increment from trigger');
  is($c[0]{sequence}, 'TESTUSER.ORDERS_SEQ', 'sequence parsed from trigger body');
  ok(!$c[1]{is_auto_increment}, 'STATUS not auto_increment');
}

# The trigger the install DDL writes (karr k42) names everything quoted:
# :new."ID" and "SEQ".NEXTVAL. It is auto-increment all the same.
{
  my $dbh = Mock::Dbh->new([
    { re => qr/all_tab_columns/i, rows => sub {
        [ { column_name => 'ID', data_type => 'NUMBER', data_length => 22,
            data_precision => 10, data_scale => 0, nullable => 'N',
            data_default => undef, column_id => 1 } ];
    } },
    { re => qr/all_triggers/i, rows => sub {
        [ [ qq{BEGIN\n  SELECT "orders_id_seq".NEXTVAL INTO :new."ID" FROM DUAL;\nEND;} ] ];
    } },
  ]);
  my $c = DBIO::Oracle::Introspect::Columns->fetch($dbh, $SCHEMA, $tables)->{ORDERS}[0];
  is($c->{is_auto_increment}, 1, 'a quoted :new."col" of the install trigger is auto_increment (karr k42)');
  is($c->{sequence}, "$SCHEMA.orders_id_seq", '... with its sequence, in the spelling the trigger quotes (karr k61)');
}

# The model spells names as the server has them (karr k61): a bare name is
# upper case, a quoted one is kept, also one with characters beyond \w, and
# the column of the trigger is matched by that spelling, not by lower case.
{
  my @cases = (
    [ q{SELECT my_seq.nextval INTO :new.id FROM dual;}, 'ID', "$SCHEMA.MY_SEQ", 'bare names are upper case' ],
    [ q{SELECT other.my_seq.nextval INTO :new."id" FROM dual;}, 'id', 'OTHER.MY_SEQ', 'a bare schema is upper case, a quoted column keeps its case' ],
    [ q{SELECT "Sch"."My Seq-1".NEXTVAL INTO :new."ID" FROM dual;}, 'ID', 'Sch.My Seq-1', 'a quoted name with characters beyond \w is read whole' ],
    [ q{SELECT "a""b".nextval INTO :new.id FROM dual;}, 'ID', qq{$SCHEMA.a"b}, 'a doubled quote is one quote' ],
  );
  for my $case (@cases) {
    my ($body, $col, $seq, $what) = @$case;
    my $dbh = Mock::Dbh->new([
      { re => qr/all_tab_columns/i, rows => sub {
          [ { column_name => $col, data_type => 'NUMBER', data_length => 22,
              data_precision => 10, data_scale => 0, nullable => 'N',
              data_default => undef, column_id => 1 } ];
      } },
      { re => qr/all_triggers/i, rows => sub { [ [ "BEGIN $body END;" ] ] } },
    ]);
    my $c = DBIO::Oracle::Introspect::Columns->fetch($dbh, $SCHEMA, $tables)->{ORDERS}[0];
    is($c->{sequence}, $seq, $what);
  }

  # a trigger on :new.id feeds ID, never a column "id" of its own
  my $dbh = Mock::Dbh->new([
    { re => qr/all_tab_columns/i, rows => sub {
        [ { column_name => 'id', data_type => 'NUMBER', data_length => 22,
            data_precision => 10, data_scale => 0, nullable => 'N',
            data_default => undef, column_id => 1 } ];
    } },
    { re => qr/all_triggers/i, rows => sub { [ [ q{BEGIN SELECT s.nextval INTO :new.id FROM dual; END;} ] ] } },
  ]);
  my $c = DBIO::Oracle::Introspect::Columns->fetch($dbh, $SCHEMA, $tables)->{ORDERS}[0];
  ok !$c->{is_auto_increment}, 'a bare :new.id is the column ID, not a column "id"';
}

# ---------------------------------------------------------------------------
# Columns: an IDENTITY column (karr k41) is auto-increment and carries no
# default (the ISEQ$$ expression is its generator). Before 12c the view has
# no identity_column: it is not selected and no column is touched.
# ---------------------------------------------------------------------------
{
  my @seen_sql;
  my $mk = sub {
    my ($version) = @_;
    my $d = Mock::Dbh->new([
      { re => qr/all_tab_columns/i, rows => sub {
          [
            { column_name => 'ID', data_type => 'NUMBER', data_length => 22,
              data_precision => undef, data_scale => 0, nullable => 'N',
              data_default => '"TESTUSER"."ISEQ$$_1234".nextval',
              column_id => 1, identity_column => 'YES' },
            { column_name => 'N', data_type => 'NUMBER', data_length => 22,
              data_precision => undef, data_scale => 0, nullable => 'Y',
              data_default => '"TESTUSER"."OTHER".nextval',
              column_id => 2, identity_column => 'NO' },
          ];
      } },
    ]);
    $d->{version} = $version;
    return $d;
  };

  my $c = DBIO::Oracle::Introspect::Columns->fetch($mk->(12), $SCHEMA, $tables)->{ORDERS};
  is($c->[0]{is_auto_increment}, 1, 'IDENTITY column is auto_increment');
  ok(!exists $c->[0]{default_value}, '... and has no default_value');
  ok(!$c->[1]{is_auto_increment}, 'a plain column with a nextval default is not');
  is(ref $c->[1]{default_value}, 'SCALAR', '... its default stays an expression');

  {
    no warnings 'redefine';
    my $orig = \&Mock::Dbh::prepare_cached;
    local *Mock::Dbh::prepare_cached = sub { push @seen_sql, $_[1]; $orig->(@_) };
    DBIO::Oracle::Introspect::Columns->fetch($mk->(11), $SCHEMA, $tables);
  }
  unlike($seen_sql[0], qr/data_default, column_id, identity_column/,
    'before 12c the identity_column is not selected from the view');
  like($seen_sql[0], qr/'NO' AS identity_column/, '... a constant stands in');
}

# ---------------------------------------------------------------------------
# Columns: a string default is read back as the value that was declared
# (karr k47). The DDL writes it with the apostrophe doubled; reading it back
# with the doubling still in place would make the declared default and the
# introspected one differ on every diff (ADR 0009, no phantom diff). An
# expression that merely starts and ends with a quote is not a literal.
# ---------------------------------------------------------------------------
{
  my @defaults = (
    [ APOS   => q{'it''s'},      q{it's} ],
    [ ONLYQ  => q{''''},         q{'}    ],
    [ EMPTY  => q{''},           q{}     ],
    [ NUM    => q{0},            q{0}    ],
    [ NEG    => q{-5},           q{-5}   ],
    [ CONCAT => q{'a'||'b'},     \q{'a'||'b'} ],
  );
  my $n = 0;
  my $dbh = Mock::Dbh->new([
    { re => qr/all_tab_columns/i, rows => sub {
        [ map {
            { column_name => $_->[0], data_type => 'VARCHAR2', data_length => 20,
              data_precision => undef, data_scale => undef, nullable => 'Y',
              data_default => $_->[1], column_id => ++$n }
          } @defaults ];
    } },
  ]);

  my $cols = DBIO::Oracle::Introspect::Columns->fetch($dbh, $SCHEMA, $tables);
  my %by = map { $_->{column_name} => $_ } @{ $cols->{ORDERS} };

  for my $d (@defaults) {
    my ($name, undef, $want) = @$d;
    is_deeply($by{$name}{default_value}, $want, "default $name read back");
  }
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
          { constraint_name => 'OI_ORDER_FK', from_table => 'ORDER_ITEM',
            from_column => 'ORDER_ID', from_pos => 1,
            to_table => 'ORDERS', to_column => 'ID', to_pos => 1,
            on_delete => 'CASCADE', is_deferrable => 1 },
          { constraint_name => 'OI_ORDER_FK', from_table => 'ORDER_ITEM',
            from_column => 'TENANT_ID', from_pos => 2,
            to_table => 'ORDERS', to_column => 'TENANT_ID', to_pos => 2,
            on_delete => 'CASCADE', is_deferrable => 1 },
        ];
    } },
  ]);
  my $fks = DBIO::Oracle::Introspect::ForeignKeys->fetch($dbh, $SCHEMA, $t);
  my $fk = $fks->{ORDER_ITEM}[0];
  is($fk->{constraint_name}, 'OI_ORDER_FK', 'fk name');
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
