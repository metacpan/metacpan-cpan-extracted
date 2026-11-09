use strict;
use warnings;
use Test::More;
use Test::Exception;

# t/52-view-order.t -- views are written in the order of what they read (karr
# k43). Offline: no DBD, no DSN, no server; the live half is
# t/52-view-order-live.t.
#
# WHY IT MATTERS. Views were created in name order. ClickHouse resolves the
# tables of a view's SELECT when the view is created: a view over a view that
# does not exist yet is UNKNOWN_TABLE (measured, 25.3). So `a_top` over
# `z_base` failed the install, the scratch deploy and the upgrade alike. And
# `system.tables.dependencies_table` records nothing for plain views (measured:
# empty), so the only source of the order is the SELECT text, read against the
# names of the declared views.
#
# Claims:
#   1. install_ddl creates a view after the views its SELECT reads from
#      (FROM / JOIN, backticked or database-qualified), whatever their names;
#   2. a cycle ends install_ddl before any statement, naming every view in it;
#   3. a column, a string, a comment or an alias that happens to spell the
#      name of a view is not a read (no false cycle, no false order);
#   4. the Diff creates and replaces in that order and drops in the reverse
#      one (a reader goes before what it reads), drops still before the
#      table operations;
#   5. a cycle among the declared views ends the Diff while its operation list
#      is built, before any statement.

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::ClickHouse::DDL;
use DBIO::ClickHouse::Diff;

my $n = 0;
# (name => [ view_name, select ] | table_name ...) in registration order
sub schema_of {
  my (%spec) = @_;
  my $schema = 'My::CH::ViewOrder' . ++$n;
  { no strict 'refs'; @{"${schema}::ISA"} = ('DBIO::Schema'); }
  for my $name (sort keys %spec) {
    my $class = "${schema}::Result::$name";
    { no strict 'refs'; @{"${class}::ISA"} = ('DBIO::Core'); }
    my $s = $spec{$name};
    if (ref $s) {
      $class->table_class('DBIO::ResultSource::View');
      $class->table($s->[0]);
      $class->result_source_instance->view_definition($s->[1]);
      $class->result_source_instance->is_virtual(0);
      $class->add_columns(id => { data_type => 'integer', is_nullable => 0 });
    }
    else {
      $class->table($s);
      $class->add_columns(id => { data_type => 'integer', is_nullable => 0 });
      $class->set_primary_key('id');
    }
    $schema->register_class($name => $class);
  }
  return $schema;
}
sub created_views {
  my ($ddl) = @_;
  return [ $ddl =~ /CREATE VIEW `([^`]+)`/g ];
}

# --- 1. the order of the install ---------------------------------------------
{
  my $ddl = DBIO::ClickHouse::DDL->install_ddl(schema_of(
    Base => 'base',
    A    => [ a_top => 'SELECT id FROM z_mid' ],
    M    => [ z_mid => 'SELECT id FROM m_low JOIN base USING (id)' ],
    L    => [ m_low => 'SELECT id FROM base' ],
    Free => [ b_free => 'SELECT id FROM base' ],
  ));
  is_deeply created_views($ddl), [qw(m_low z_mid a_top b_free)],
    'a view comes after the views it reads; otherwise name order';
  like $ddl, qr/\ACREATE TABLE `base`/, '... and the tables still come first';
}
{
  my $ddl = DBIO::ClickHouse::DDL->install_ddl(schema_of(
    Base => 'base',
    A    => [ a_top => 'SELECT id FROM `db`.`z_mid` AS m' ],
    M    => [ z_mid => "SELECT id FROM\n  `y_low`\n" ],
    L    => [ y_low => 'select id from base' ],
  ));
  is_deeply created_views($ddl), [qw(y_low z_mid a_top)],
    'the read is found through a database qualifier, backticks and white space';
}

# --- 2. a cycle ---------------------------------------------------------------
{
  my $schema = schema_of(
    Base => 'base',
    A    => [ a => 'SELECT id FROM b' ],
    B    => [ b => 'SELECT id FROM c' ],
    C    => [ c => 'SELECT id FROM a' ],
    D    => [ d => 'SELECT id FROM base' ],
  );
  throws_ok { DBIO::ClickHouse::DDL->install_ddl($schema) }
    qr/refus.*cycle.*`a`.*`b`.*`c`/is, 'a cycle of views is refused, naming every view in it';
  throws_ok { DBIO::ClickHouse::DDL->install_ddl($schema) } qr/\A(?:(?!`d`).)*\z/s,
    '... and only those, not a view beside it';
}

# --- 3. what is not a read ----------------------------------------------------
{
  my $ddl = DBIO::ClickHouse::DDL->install_ddl(schema_of(
    Base => 'base',
    A    => [ a => 'SELECT b AS x, id FROM base' ],      # column b
    B    => [ b => "SELECT 'from a' AS s, id FROM base" ], # string
    C    => [ c => "SELECT id FROM base -- from a\n" ],   # comment
    D    => [ d => 'SELECT id FROM base AS a' ],          # alias a
    E    => [ e => 'SELECT id FROM abc' ],                # longer name
    F    => [ abc => 'SELECT id FROM base' ],
  ));
  is_deeply created_views($ddl), [qw(a abc b c d e)],
    'a column, a string, a comment, an alias do not make a read; a longer name is not the shorter';
}

# --- 4. the Diff --------------------------------------------------------------
sub table_info {
  my (%a) = @_;
  return {
    table_name => $a{name}, kind => $a{kind} // 'table',
    engine => $a{engine} // 'MergeTree', engine_expression => $a{engine} // 'MergeTree',
    database => 'live', sorting_key => 'id', sorting_key_entries => ['id'],
    primary_key => 'id', primary_key_entries => ['id'], primary_key_columns => ['id'],
    partition_key => '', partition_key_entries => [],
    (exists $a{definition} ? (definition => $a{definition}) : ()),
  };
}
sub model {
  my (%views) = @_;
  return {
    tables => { base => table_info(name => 'base'),
      map { $_ => table_info(name => $_, kind => 'view', engine => 'View', definition => $views{$_}) } keys %views },
    columns => { base => [ { column_name => 'id', data_type => 'Int32' } ] },
    data_skipping_indexes => {}, indexes => {}, foreign_keys => {},
  };
}
sub sql_of { [ map { split /(?<=;)\n/ } DBIO::ClickHouse::Diff->new(@_)->as_sql ] }
sub names_in { my ($sql, $verb) = @_; [ map { /\Q$verb\E VIEW (?:IF (?:NOT )?EXISTS )?`([^`]+)`/ ? $1 : () } @$sql ] }

{
  my $sql = sql_of(
    source => model(), target => model(),
    declared_views => {
      a_top  => 'SELECT id FROM z_mid',
      z_mid  => 'SELECT id FROM m_low',
      m_low  => 'SELECT id FROM live.base',
    },
  );
  is_deeply names_in($sql, 'CREATE'), [qw(m_low z_mid a_top)], 'the views to create come after what they read';
}
{
  my $sql = sql_of(
    source => model(a_top => 'SELECT id FROM live.z_mid', z_mid => 'SELECT id FROM live.m_low',
                    m_low => 'SELECT id FROM live.base'),
    target => model(),
    declared_views => {},
  );
  is_deeply names_in($sql, 'DROP'), [qw(a_top z_mid m_low)],
    'the views to drop go before what they read (the reverse order)';
}
{
  my $sql = sql_of(
    source => model(a_top => 'SELECT 3 AS id', z_mid => 'SELECT 1 AS id', m_low => 'SELECT 2 AS id'),
    target => model(),
    declared_views => {
      a_top  => 'SELECT id FROM z_mid',
      z_mid  => 'SELECT id FROM m_low',
      m_low  => 'SELECT id FROM live.base',
    },
  );
  is_deeply names_in($sql, 'CREATE OR REPLACE'), [qw(m_low z_mid a_top)],
    'the views to replace come in the same order';
}

# --- 5. a cycle in the Diff ---------------------------------------------------
throws_ok {
  DBIO::ClickHouse::Diff->new(source => model(), target => model(),
    declared_views => { x => 'SELECT id FROM y', y => 'SELECT id FROM x', other => 'SELECT 1 AS id' })->as_sql;
} qr/refus.*cycle.*`x`.*`y`/is, 'a cycle among the declared views ends the diff, naming the views';

done_testing;
