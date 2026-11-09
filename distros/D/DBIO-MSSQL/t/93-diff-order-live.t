use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::Core ();
use DBIO::MSSQL::Deploy;

# LIVE (karr k71, review blockers B1, B2, S4). An upgrade of a database whose
# target model carries foreign keys: the statements have to be in an order the
# server accepts (B1), the last foreign key of a table has to be dropped when
# it is removed (B2), and a unique constraint is added and dropped as a
# constraint, not as an index (S4, Msg 3723). Every scenario starts from a
# database built with plain SQL, upgrades it to a schema of classes, checks
# what the server holds, and a second diff must be empty. Each scenario has a
# database of its own, _dbio_k71o_<pid>_<n>, dropped at the end; nothing else
# is touched. t/92-diff-order.t pins the statements offline.

my @paths = grep { $_->[0] && defined $_->[1] } (
  [ @ENV{qw/DBIO_TEST_MSSQL_ODBC_DSN DBIO_TEST_MSSQL_ODBC_USER DBIO_TEST_MSSQL_ODBC_PASS/} ],
  [ @ENV{qw/DBIO_TEST_MSSQL_DSN      DBIO_TEST_MSSQL_USER      DBIO_TEST_MSSQL_PASS/}      ],
);
plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN} (or DBIO_TEST_MSSQL_DSN), _USER and _PASS to run this test'
  unless @paths;
my ($dsn, $user, $pass) = @{ $paths[0] };
my ($dbd) = $dsn =~ /^dbi:(\w+)/i;

my %conn = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);
my $admin = DBI->connect($dsn, $user, $pass, \%conn);

my $seq = 0;

# source: [ class, table, { col => \%info }, pk, { uniques, rels, idx } ]
sub build_schema {
  my ($tag, @sources) = @_;
  my $schema_class = "K71o::${tag}::Schema";
  eval "package $schema_class; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); 1"
    or die $@;
  my @after;
  for my $s (@sources) {
    my ($name, $table, $cols, $pk, $extra) = @$s;
    $extra ||= {};
    my $rc = "$schema_class\::Result::$name";
    eval "package $rc; use base 'DBIO::Core'; 1" or die $@;
    $rc->table($table);
    $rc->add_columns(map { ($_ => $cols->{$_}) } sort keys %$cols);
    $rc->set_primary_key($pk);
    $rc->add_unique_constraint($_ => $extra->{uniques}{$_}) for sort keys %{ $extra->{uniques} || {} };
    $rc->result_source_instance->add_index_declaration($_) for @{ $extra->{idx} || [] };
    push @after, [ $name, $rc, $extra->{rels} || [] ];
  }
  # relationships first (resolved lazily), then the registration: the schema
  # registers a copy of the source
  for my $a (@after) {
    my ($name, $rc, $rels) = @$a;
    $rc->belongs_to(@$_) for @$rels;
  }
  $schema_class->register_class($_->[0] => $_->[1]) for @after;
  return $schema_class;
}

sub scenario {
  my ($name, %arg) = @_;
  my $db = sprintf '_dbio_k71o_%d_%d', $$, ++$seq;
  my $dsn_db = $dsn;
  $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
    or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;

  $admin->do("CREATE DATABASE [$db]");
  my $ok = eval {
    my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);
    $dbh->do($_) for @{ $arg{before} || [] };

    my $schema_class = build_schema($name =~ s/\W/_/gr, @{ $arg{after} });
    my $schema = $schema_class->connect($dsn_db, $user, $pass, { %conn });
    my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);

    my $diff = $deploy->diff;
    ok $diff->has_changes, "$name: the diff sees the change";
    my $applied = eval { $deploy->apply($diff, allow_destructive => 1); 1 };
    ok $applied, "$name: the server accepts the upgrade" or diag $@ . "\n" . $diff->as_sql;

    $arg{check}->($dbh) if $applied;

    my $again = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
    ok !$again->has_changes, "$name: the second diff is empty"
      or diag $again->summary . "\n" . $again->as_sql;
    $schema->storage->disconnect;
    $dbh->disconnect;
    1;
  };
  my $err = $@;
  eval {
    $admin->do("IF DB_ID('$db') IS NOT NULL BEGIN ALTER DATABASE [$db] "
      . "SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db] END");
    1;
  } or diag "could not drop $db: $@";
  die $err unless $ok;
}

my $int  = { data_type => 'int' };
my $nint = { data_type => 'int', is_nullable => 1 };
sub fk_names {
  my ($dbh) = @_;
  return join ',', sort map { $_->[0] } @{ $dbh->selectall_arrayref('SELECT name FROM sys.foreign_keys') };
}
sub tables {
  my ($dbh) = @_;
  return join ',', sort map { $_->[0] } @{ $dbh->selectall_arrayref('SELECT name FROM sys.tables') };
}
sub uniq {
  my ($dbh) = @_;
  # name:constraint|index
  return join ',', sort map { "$_->[0]:" . ($_->[1] ? 'constraint' : 'index') }
    @{ $dbh->selectall_arrayref(q{SELECT name, is_unique_constraint FROM sys.indexes
        WHERE is_unique = 1 AND is_primary_key = 0 AND object_id IN (SELECT object_id FROM sys.tables)}) };
}

# B1 (a): new child before its new parent in alphabetical order; a mutual pair
scenario('new tables, child sorts before parent',
  after => [
    [ AChild  => 'a_child',  { id => $int, parent_id => $int }, 'id',
      { rels => [ [ parent => 'K71o::new_tables__child_sorts_before_parent::Schema::Result::ZParent', 'parent_id' ] ] } ],
    [ ZParent => 'z_parent', { id => $int }, 'id' ],
    [ MA => 'm_a', { id => $int, b_id => $nint }, 'id',
      { rels => [ [ b => 'K71o::new_tables__child_sorts_before_parent::Schema::Result::MB', 'b_id' ] ] } ],
    [ MB => 'm_b', { id => $int, a_id => $nint }, 'id',
      { rels => [ [ a => 'K71o::new_tables__child_sorts_before_parent::Schema::Result::MA', 'a_id' ] ] } ],
  ],
  check => sub {
    is tables($_[0]), 'a_child,m_a,m_b,z_parent', 'the four tables exist';
    is fk_names($_[0]), 'FK_a_child_parent_id,FK_m_a_b_id,FK_m_b_a_id', 'all three foreign keys exist';
  });

# B1 (b): referenced table dropped; two dropped tables reference each other
scenario('dropped referenced tables',
  before => [
    'CREATE TABLE gone_p (id INT NOT NULL PRIMARY KEY)',
    'CREATE TABLE keep_t (id INT NOT NULL PRIMARY KEY, p_id INT NOT NULL)',
    'ALTER TABLE keep_t ADD CONSTRAINT FK_keep_t_p_id FOREIGN KEY (p_id) REFERENCES gone_p (id)',
    'CREATE TABLE dx (id INT NOT NULL PRIMARY KEY, y_id INT NULL)',
    'CREATE TABLE dy (id INT NOT NULL PRIMARY KEY, x_id INT NULL)',
    'ALTER TABLE dx ADD CONSTRAINT FK_dx_y_id FOREIGN KEY (y_id) REFERENCES dy (id)',
    'ALTER TABLE dy ADD CONSTRAINT FK_dy_x_id FOREIGN KEY (x_id) REFERENCES dx (id)',
  ],
  after => [ [ Keep => 'keep_t', { id => $int, p_id => $int }, 'id' ] ],
  check => sub {
    is tables($_[0]), 'keep_t', 'only the kept table is left';
    is fk_names($_[0]), '', 'no foreign key is left';
  });

# B1 (c): the column of a foreign key is dropped
scenario('dropped foreign key column',
  before => [
    'CREATE TABLE p3 (id INT NOT NULL PRIMARY KEY)',
    'CREATE TABLE c3 (id INT NOT NULL PRIMARY KEY, ref_id INT NOT NULL)',
    'ALTER TABLE c3 ADD CONSTRAINT FK_c3_ref_id FOREIGN KEY (ref_id) REFERENCES p3 (id)',
  ],
  after => [
    [ P => 'p3', { id => $int }, 'id' ],
    [ C => 'c3', { id => $int }, 'id' ],
  ],
  check => sub {
    is fk_names($_[0]), '', 'the foreign key is gone';
    my ($n) = $_[0]->selectrow_array(q{SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('c3') AND name = 'ref_id'});
    is $n, 0, 'the column is gone';
  });

# B2: the last foreign key of a table is removed, the column stays
scenario('last foreign key removed',
  before => [
    'CREATE TABLE p4 (id INT NOT NULL PRIMARY KEY)',
    'CREATE TABLE c4 (id INT NOT NULL PRIMARY KEY, ref_id INT NOT NULL)',
    'ALTER TABLE c4 ADD CONSTRAINT FK_c4_ref_id FOREIGN KEY (ref_id) REFERENCES p4 (id)',
  ],
  after => [
    [ P => 'p4', { id => $int }, 'id' ],
    [ C => 'c4', { id => $int, ref_id => $int }, 'id' ],
  ],
  check => sub { is fk_names($_[0]), '', 'the foreign key is dropped' });

# S4: unique constraints and unique indexes
scenario('unique constraints changed and removed',
  before => [
    'CREATE TABLE u5 (id INT NOT NULL PRIMARY KEY, a INT NOT NULL, b INT NOT NULL, c INT NOT NULL, w INT NOT NULL, '
      . 'CONSTRAINT uq_a_b UNIQUE (a, b), CONSTRAINT uq_c UNIQUE (c))',
    'CREATE UNIQUE INDEX ix_w ON u5 (w)',
  ],
  after => [
    [ U => 'u5', { id => $int, a => $int, b => $int, c => $int, w => $int }, 'id',
      { uniques => { uq_a_b => ['a'], uq_new_b => ['b'] },
        idx => [ { name => 'ix_new', columns => ['w'], unique => 1 } ] } ],
  ],
  check => sub {
    is uniq($_[0]), 'ix_new:index,uq_a_b:constraint,uq_new_b:constraint',
      'uq_a_b changed, uq_c and ix_w gone, a new constraint and a new unique index';
  });

# S4: a foreign key onto a unique constraint the diff creates
scenario('foreign key onto a new unique constraint',
  before => [
    'CREATE TABLE p6 (id INT NOT NULL PRIMARY KEY, code INT NOT NULL)',
    'CREATE TABLE c6 (id INT NOT NULL PRIMARY KEY, ref_code INT NOT NULL)',
  ],
  after => [
    [ P => 'p6', { id => $int, code => $int }, 'id', { uniques => { uq_code => ['code'] } } ],
    [ C => 'c6', { id => $int, ref_code => $int }, 'id',
      { rels => [ [ p => 'K71o::foreign_key_onto_a_new_unique_constraint::Schema::Result::P',
                    { 'foreign.code' => 'self.ref_code' } ] ] } ],
  ],
  check => sub {
    is uniq($_[0]), 'uq_code:constraint', 'the constraint exists';
    is fk_names($_[0]), 'FK_c6_ref_code', 'the foreign key onto it exists';
  });

# ALTER COLUMN on columns that a unique constraint / an index covers
# (measured 2026-10-20: the server refuses NULL -> NOT NULL and a type change
# there, "The object ... is dependent on column"; t/102 pins the statements)
scenario('nullability and type of columns in a unique constraint and indexes',
  before => [
    'CREATE TABLE u7 (id INT NOT NULL PRIMARY KEY, code INT NULL, tag INT NULL, ux INT NULL, big INT NOT NULL, '
      . 'CONSTRAINT uq_u7_code UNIQUE (code), CONSTRAINT uq_u7_big UNIQUE (big))',
    'CREATE INDEX ix_u7_tag ON u7 (tag)',
    'CREATE UNIQUE INDEX ux_u7 ON u7 (ux)',
    'INSERT INTO u7 (id, code, tag, ux, big) VALUES (1, 10, 20, 30, 40)',
  ],
  after => [
    [ U => 'u7', { id => $int, code => $int, tag => $int, ux => $int, big => { data_type => 'bigint' } }, 'id',
      { uniques => { uq_u7_code => ['code'], uq_u7_big => ['big'] },
        idx => [ { name => 'ix_u7_tag', columns => ['tag'] },
                 { name => 'ux_u7', columns => ['ux'], unique => 1 } ] } ],
  ],
  check => sub {
    is uniq($_[0]), 'uq_u7_big:constraint,uq_u7_code:constraint,ux_u7:index',
      'the unique constraints and the unique index are back';
    my ($n) = $_[0]->selectrow_array(q{SELECT COUNT(*) FROM sys.indexes WHERE name = 'ix_u7_tag'});
    is $n, 1, 'the nonclustered index is back';
    my @r = $_[0]->selectrow_array(q{SELECT code, tag, ux, big FROM u7 WHERE id = 1});
    is_deeply \@r, [10, 20, 30, 40], 'the data is untouched';
    my ($nn) = $_[0]->selectrow_array(q{SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('u7') AND is_nullable = 0});
    is $nn, 5, 'all five columns are NOT NULL';
  });

# karr k73: foreign keys through the whole upgrade path, measured live
# 2026-10-20 (MSSQL 2022): the server takes every ON DELETE x ON UPDATE pair of
# NO ACTION, CASCADE, SET NULL, SET DEFAULT, so the driver writes them all.
# The database holds: a table without the key it should get (ca), a key with
# other actions than declared (cb), a key under the name the server made up
# (cc), a key the classes do not declare beside one they do (cd), and a key
# with ON UPDATE SET NULL that is declared as it is (ce). After the upgrade
# every key carries the deterministic name FK_<table>_<column> and the
# declared actions, nothing else is left, and the second diff is empty.
sub fk_rules {
  my ($dbh) = @_;
  return join ',', map { "$_->[0]=$_->[1]/$_->[2]" } @{ $dbh->selectall_arrayref(
    q{SELECT name, delete_referential_action_desc, update_referential_action_desc
        FROM sys.foreign_keys ORDER BY name}) };
}
{
  my $pk = 'K71o::foreign_keys_added_changed_renamed_dropped::Schema::Result::P';
  my $rel = sub { [ p => $pk, $_[0], { on_delete => $_[1], on_update => $_[2] } ] };
  scenario('foreign keys added changed renamed dropped',
    before => [
      'CREATE TABLE p9 (id INT NOT NULL PRIMARY KEY)',
      'CREATE TABLE ca (id INT NOT NULL PRIMARY KEY, p_id INT NULL)',
      'CREATE TABLE cb (id INT NOT NULL PRIMARY KEY, p_id INT NULL)',
      'ALTER TABLE cb ADD CONSTRAINT FK_cb_p_id FOREIGN KEY (p_id) REFERENCES p9 (id)',
      'CREATE TABLE cc (id INT NOT NULL PRIMARY KEY, p_id INT NULL FOREIGN KEY REFERENCES p9 (id))',
      'CREATE TABLE cd (id INT NOT NULL PRIMARY KEY, p_id INT NULL, q_id INT NULL)',
      'ALTER TABLE cd ADD CONSTRAINT FK_cd_p_id FOREIGN KEY (p_id) REFERENCES p9 (id)',
      'ALTER TABLE cd ADD CONSTRAINT FK_cd_q_id FOREIGN KEY (q_id) REFERENCES p9 (id)',
      'CREATE TABLE ce (id INT NOT NULL PRIMARY KEY, p_id INT NULL)',
      'ALTER TABLE ce ADD CONSTRAINT FK_ce_p_id FOREIGN KEY (p_id) REFERENCES p9 (id) ON DELETE CASCADE ON UPDATE SET NULL',
    ],
    after => [
      [ P  => 'p9', { id => $int }, 'id' ],
      [ CA => 'ca', { id => $int, p_id => $nint }, 'id', { rels => [ $rel->('p_id', 'cascade', 'cascade') ] } ],
      [ CB => 'cb', { id => $int, p_id => $nint }, 'id', { rels => [ $rel->('p_id', 'set null', 'no action') ] } ],
      [ CC => 'cc', { id => $int, p_id => $nint }, 'id', { rels => [ $rel->('p_id', undef, undef) ] } ],
      [ CD => 'cd', { id => $int, p_id => $nint, q_id => $nint }, 'id', { rels => [ $rel->('p_id', 'cascade', undef) ] } ],
      [ CE => 'ce', { id => $int, p_id => $nint }, 'id', { rels => [ $rel->('p_id', 'cascade', 'set null') ] } ],
    ],
    check => sub {
      is fk_rules($_[0]),
        join(',', 'FK_ca_p_id=CASCADE/CASCADE', 'FK_cb_p_id=SET_NULL/NO_ACTION',
          'FK_cc_p_id=NO_ACTION/NO_ACTION', 'FK_cd_p_id=CASCADE/NO_ACTION',
          'FK_ce_p_id=CASCADE/SET_NULL'),
        'the keys carry the deterministic names and the declared actions; the undeclared FK_cd_q_id and the server-named key are gone';
    });
}

$admin->disconnect;
done_testing;
