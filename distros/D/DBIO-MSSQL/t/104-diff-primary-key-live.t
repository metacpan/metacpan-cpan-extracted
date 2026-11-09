use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::Core ();
use DBIO::MSSQL::Deploy;
use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Introspect;
use Storable qw(dclone);

# LIVE (karr k74). An upgrade of a database whose tables lack the primary key of
# the classes, or hold another one: the key is added with the deterministic
# name PK_<table>, in key order; a key that foreign keys reference, or whose
# column changes its type, goes around them. Every scenario starts from a
# database built with plain SQL, upgrades it to a schema of classes, checks
# what the server holds, and a second diff must be empty. Each scenario has a
# database of its own, _dbio_k74_<pid>_<n>, dropped at the end; nothing else
# is touched. t/103-diff-primary-key.t pins the statements offline.

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
  my $schema_class = "K74::${tag}::Schema";
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
    $rc->set_primary_key(ref $pk ? @$pk : $pk) if defined $pk;
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
  my $db = sprintf '_dbio_k74_%d_%d', $$, ++$seq;
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

    if ($arg{refuse}) {
      # Without Deploy and its temp database: the server would refuse the
      # desired schema itself (no key to reference), and its text would pass
      # for ours. The live model is read from the server; the target is the
      # same model with the change the classes declare, and the diff between
      # the two is DBIO::MSSQL::Diff's alone.
      my $live   = DBIO::MSSQL::Introspect->new(dbh => $dbh)->model;
      my $target = $arg{refuse_target}->(dclone($live));
      my $diff   = DBIO::MSSQL::Diff->new(source => $live, target => $target);
      my $err    = eval { $diff->as_sql; 1 } ? '' : "$@";
      ok length $err, "$name: the diff is refused";
      like $err, $arg{refuse},
        "$name: ... by the diff, with its own message naming table and foreign key";
      unlike $err, qr/\bMsg \d+|FreeTDS|DBD::/,
        "$name: ... and the message is not the server's";
      $arg{check}->($dbh);
      $schema->storage->disconnect;
      $dbh->disconnect;
      return 1;
    }
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
my $big  = { data_type => 'bigint' };
my $nint = { data_type => 'int', is_nullable => 1 };

# the primary key of a table: name:col1,col2 (key order)
sub pk {
  my ($dbh, $table) = @_;
  my $rows = $dbh->selectall_arrayref(q{
    SELECT kc.name, c.name FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE kc.type = 'PK' AND kc.parent_object_id = OBJECT_ID(?)
    ORDER BY ic.key_ordinal}, undef, $table);
  return @$rows ? "$rows->[0][0]:" . join(',', map { $_->[1] } @$rows) : 'none';
}
sub col_type {
  my ($dbh, $table, $col) = @_;
  return $dbh->selectrow_array(q{SELECT DATA_TYPE + '/' + IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = ? AND COLUMN_NAME = ?}, undef, $table, $col);
}

# 1. a table without a key; the key column is nullable and holds data
scenario('table without key, key column nullable',
  before => [ 'CREATE TABLE t1 (id INT NULL, x INT NOT NULL)', 'INSERT t1 VALUES (1, 1), (2, 2)' ],
  after  => [ [ T => 't1', { id => $int, x => $int }, 'id' ] ],
  check  => sub {
    is pk($_[0], 't1'), 'PK_t1:id', 'the key is there, named PK_t1';
    is col_type($_[0], 't1', 'id'), 'int/NO', '... and its column is NOT NULL now';
    is $_[0]->selectrow_array('SELECT COUNT(*) FROM t1'), 2, 'the rows are still there';
  });

# 2. the same columns in another order: the key is replaced, in the new order
scenario('composite key order changed',
  before => [ 'CREATE TABLE t2 (a INT NOT NULL, b INT NOT NULL, PRIMARY KEY (a, b))' ],
  after  => [ [ T => 't2', { a => $int, b => $int }, ['b', 'a'] ] ],
  check  => sub { is pk($_[0], 't2'), 'PK_t2:b,a', 'dropped under its server-made name, added as PK_t2 in key order' });

# 3. another column becomes the key
scenario('key moves to another column',
  before => [ 'CREATE TABLE t3 (id INT NOT NULL PRIMARY KEY, code INT NOT NULL)' ],
  after  => [ [ T => 't3', { id => $int, code => $int }, 'code' ] ],
  check  => sub { is pk($_[0], 't3'), 'PK_t3:code', 'the key is on code' });

# 4. the key already equals the classes (named by the server): untouched
scenario('equal key is left alone',
  before => [ 'CREATE TABLE t4 (id INT NOT NULL PRIMARY KEY, y INT NULL)' ],
  after  => [ [ T => 't4', { id => $int, y => $nint, z => $nint }, 'id' ] ],
  check  => sub { like pk($_[0], 't4'), qr/^PK__t4__\w+:id$/, 'the key keeps the name the server gave it' });

# 5. a key column changes its type, a foreign key references it and the
# referencing column changes its type too
scenario('key column type change with a foreign key',
  before => [
    'CREATE TABLE par5 (id INT NOT NULL PRIMARY KEY)',
    'CREATE TABLE chi5 (id INT NOT NULL PRIMARY KEY, p INT NOT NULL)',
    'ALTER TABLE chi5 ADD CONSTRAINT FK_chi5_p FOREIGN KEY (p) REFERENCES par5 (id)',
    'INSERT par5 VALUES (1)', 'INSERT chi5 VALUES (1, 1)',
  ],
  after => [
    [ P => 'par5', { id => $big }, 'id' ],
    [ C => 'chi5', { id => $int, p => $big }, 'id',
      { rels => [ [ p => 'K74::key_column_type_change_with_a_foreign_key::Schema::Result::P', 'p' ] ] } ],
  ],
  check => sub {
    my ($dbh) = @_;
    is col_type($dbh, 'par5', 'id'), 'bigint/NO', 'the key column is bigint';
    is col_type($dbh, 'chi5', 'p'),  'bigint/NO', 'the referencing column is bigint';
    is pk($dbh, 'par5'), 'PK_par5:id', 'the key is back, as PK_par5';
    is $dbh->selectrow_array(q{SELECT name FROM sys.foreign_keys}), 'FK_chi5_p', 'the foreign key is back';
  });

# 6. the classes declare no key, the table has one: the key is dropped
scenario('key dropped, none declared',
  before => [ 'CREATE TABLE t6 (id INT NOT NULL PRIMARY KEY, x INT NOT NULL)', 'INSERT t6 VALUES (1, 1)' ],
  after  => [ [ T => 't6', { id => $int, x => $int }, undef ] ],
  check  => sub {
    is pk($_[0], 't6'), 'none', 'the table has no key any more';
    is $_[0]->selectrow_array('SELECT COUNT(*) FROM t6'), 1, 'the row is still there';
  });

# 7. the dropped key is referenced by a foreign key the classes do not declare:
# the foreign key goes too, then the key (the server refuses the key first)
scenario('key dropped, undeclared foreign key onto it',
  before => [
    'CREATE TABLE par7 (id INT NOT NULL PRIMARY KEY)',
    'CREATE TABLE chi7 (id INT NOT NULL PRIMARY KEY, p INT NOT NULL)',
    'ALTER TABLE chi7 ADD CONSTRAINT FK_chi7_p FOREIGN KEY (p) REFERENCES par7 (id)',
    'INSERT par7 VALUES (1)', 'INSERT chi7 VALUES (1, 1)',
  ],
  after => [
    [ P => 'par7', { id => $int }, undef ],
    [ C => 'chi7', { id => $int, p => $int }, 'id' ],
  ],
  check => sub {
    is pk($_[0], 'par7'), 'none', 'the parent has no key any more';
    like pk($_[0], 'chi7'), qr/^PK__chi7__\w+:id$/, 'the child keeps its key';
    is $_[0]->selectrow_array('SELECT COUNT(*) FROM sys.foreign_keys'), 0, 'the foreign key is gone';
  });

# 8. the foreign key is declared but the key it references is not: refused,
# nothing is changed. Through Deploy the refusal would be the server's, when
# the desired schema is built in the temp database (it cannot create the
# foreign key: no primary or candidate key). So this scenario does not go
# through Deploy: it diffs the live model (read from the server) against that
# model with the key removed, and only the diff's own exception passes.
scenario('key dropped, declared foreign key onto it',
  before => [
    'CREATE TABLE par8 (id INT NOT NULL PRIMARY KEY)',
    'CREATE TABLE chi8 (id INT NOT NULL PRIMARY KEY, p INT NOT NULL)',
    'ALTER TABLE chi8 ADD CONSTRAINT FK_chi8_p FOREIGN KEY (p) REFERENCES par8 (id)',
  ],
  after => [
    [ P => 'par8', { id => $int }, undef ],
    [ C => 'chi8', { id => $int, p => $int }, 'id',
      { rels => [ [ p => 'K74::key_dropped__declared_foreign_key_onto_it::Schema::Result::P', { 'foreign.id' => 'self.p' } ] ] } ],
  ],
  refuse_target => sub {
    my ($m) = @_;
    $_->{is_pk} = 0, $_->{pk_position} = 0 for @{ $m->{columns}{par8} };
    return $m;
  },
  refuse => qr/key of table 'par8' .*declare no primary key or unique key.*'FK_chi8_p' of table 'chi8'/s,
  check  => sub {
    like pk($_[0], 'par8'), qr/^PK__par8__\w+:id$/, 'the key is still there';
    is $_[0]->selectrow_array('SELECT COUNT(*) FROM sys.foreign_keys'), 1, 'the foreign key is still there';
  });

# 9. a foreign-key-bound primary key only gets wider (nvarchar(10) -> (20)) on
# the parent and the child column. The server refuses ALTER COLUMN of either
# column while the foreign key stands, widths included (measured 2026-10-21):
# the foreign key goes around the column phase, the key itself stays.
scenario('width change of a foreign key column',
  before => [
    'CREATE TABLE par9 (c NVARCHAR(10) NOT NULL PRIMARY KEY)',
    'CREATE TABLE chi9 (id INT NOT NULL PRIMARY KEY, pc NVARCHAR(10) NOT NULL)',
    'ALTER TABLE chi9 ADD CONSTRAINT FK_chi9_pc FOREIGN KEY (pc) REFERENCES par9 (c)',
    q{INSERT par9 VALUES ('a')}, q{INSERT chi9 VALUES (1, 'a')},
  ],
  after => [
    [ P => 'par9', { c => { data_type => 'nvarchar', size => 20 } }, 'c' ],
    [ C => 'chi9', { id => $int, pc => { data_type => 'nvarchar', size => 20 } }, 'id',
      { rels => [ [ pc => 'K74::width_change_of_a_foreign_key_column::Schema::Result::P', { 'foreign.c' => 'self.pc' } ] ] } ],
  ],
  check => sub {
    my ($dbh) = @_;
    is $dbh->selectrow_array(q{SELECT CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'par9'}), 20,
      'the key column is nvarchar(20)';
    is $dbh->selectrow_array(q{SELECT CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'chi9' AND COLUMN_NAME = 'pc'}), 20,
      'the referencing column is nvarchar(20)';
    like pk($dbh, 'par9'), qr/^PK__par9__\w+:c$/, 'the key was not touched';
    is $dbh->selectrow_array(q{SELECT name FROM sys.foreign_keys}), 'FK_chi9_pc', 'the foreign key is back';
    is $dbh->selectrow_array('SELECT COUNT(*) FROM chi9'), 1, 'the row is still there';
  });

# 10. a unique constraint a foreign key references, and both columns change
# their type: foreign key and unique constraint go, the columns change, the
# unique constraint and then the foreign key come back (one mechanism for
# every key a foreign key references)
scenario('unique key type change with a foreign key',
  before => [
    'CREATE TABLE t10 (id INT NOT NULL PRIMARY KEY, code INT NOT NULL, CONSTRAINT UQ_t10_code UNIQUE (code))',
    'CREATE TABLE c10 (id INT NOT NULL PRIMARY KEY, cc INT NOT NULL)',
    'ALTER TABLE c10 ADD CONSTRAINT FK_c10_cc FOREIGN KEY (cc) REFERENCES t10 (code)',
    'INSERT t10 VALUES (1, 7)', 'INSERT c10 VALUES (1, 7)',
  ],
  after => [
    [ T => 't10', { id => $int, code => $big }, 'id', { uniques => { UQ_t10_code => ['code'] } } ],
    [ C => 'c10', { id => $int, cc => $big }, 'id',
      { rels => [ [ cc => 'K74::unique_key_type_change_with_a_foreign_key::Schema::Result::T', { 'foreign.code' => 'self.cc' } ] ] } ],
  ],
  check => sub {
    my ($dbh) = @_;
    is col_type($dbh, 't10', 'code'), 'bigint/NO', 'the unique column is bigint';
    is col_type($dbh, 'c10', 'cc'),   'bigint/NO', 'the referencing column is bigint';
    is $dbh->selectrow_array(q{SELECT name FROM sys.key_constraints WHERE type = 'UQ'}), 'UQ_t10_code', 'the unique constraint is back';
    is $dbh->selectrow_array(q{SELECT name FROM sys.foreign_keys}), 'FK_c10_cc', 'the foreign key is back';
  });

# 11. CLUSTERED or NONCLUSTERED counts (measured 2026-10-21: the server cannot
# change it in place; the classes create the key clustered). A live key that
# is nonclustered, over the same column, is replaced by a clustered one, and
# the second diff is empty.
sub pk_kind {
  my ($dbh, $table) = @_;
  return $dbh->selectrow_array(q{SELECT type_desc FROM sys.indexes
    WHERE is_primary_key = 1 AND object_id = OBJECT_ID(?)}, undef, $table);
}
scenario('nonclustered key',
  before => [
    'CREATE TABLE t11 (id INT NOT NULL, x INT NOT NULL, CONSTRAINT PK_live11 PRIMARY KEY NONCLUSTERED (id))',
    'INSERT t11 VALUES (1, 1)',
  ],
  after => [ [ T => 't11', { id => $int, x => $int }, 'id' ] ],
  check => sub {
    is pk_kind($_[0], 't11'), 'CLUSTERED', 'the key is clustered now';
    is pk($_[0], 't11'), 'PK_t11:id', '... named PK_t11';
    is $_[0]->selectrow_array('SELECT COUNT(*) FROM t11'), 1, 'the row is still there';
  });

# 12. the same, and a foreign key references the nonclustered key
scenario('nonclustered key with a foreign key',
  before => [
    'CREATE TABLE par12 (id INT NOT NULL, CONSTRAINT PK_live12 PRIMARY KEY NONCLUSTERED (id))',
    'CREATE TABLE chi12 (id INT NOT NULL PRIMARY KEY, p INT NOT NULL)',
    'ALTER TABLE chi12 ADD CONSTRAINT FK_chi12_p FOREIGN KEY (p) REFERENCES par12 (id)',
    'INSERT par12 VALUES (1)', 'INSERT chi12 VALUES (1, 1)',
  ],
  after => [
    [ P => 'par12', { id => $int }, 'id' ],
    [ C => 'chi12', { id => $int, p => $int }, 'id',
      { rels => [ [ p => 'K74::nonclustered_key_with_a_foreign_key::Schema::Result::P', { 'foreign.id' => 'self.p' } ] ] } ],
  ],
  check => sub {
    my ($dbh) = @_;
    is pk_kind($dbh, 'par12'), 'CLUSTERED', 'the referenced key is clustered now';
    is $dbh->selectrow_array(q{SELECT name FROM sys.foreign_keys}), 'FK_chi12_p', 'the foreign key is back';
    is $dbh->selectrow_array('SELECT COUNT(*) FROM chi12'), 1, 'the row is still there';
  });

# 13. a nonclustered key beside a clustered index. The classes cannot declare
# both (Msg 1902, t/96, t/98): they declare the index nonclustered. ADD PRIMARY
# KEY while a clustered index stands makes the key nonclustered, silently
# (measured), so the index goes first and comes back nonclustered after the key.
scenario('nonclustered key beside a clustered index',
  before => [
    'CREATE TABLE t13 (id INT NOT NULL, x INT NOT NULL, CONSTRAINT PK_live13 PRIMARY KEY NONCLUSTERED (id))',
    'CREATE CLUSTERED INDEX ix_t13_x ON t13 (x)',
  ],
  after => [ [ T => 't13', { id => $int, x => $int }, 'id',
    { idx => [ { name => 'ix_t13_x', columns => ['x'],
                 driver => { mssql => { kind => 'nonclustered' } } } ] } ] ],
  check => sub {
    my ($dbh) = @_;
    is pk_kind($dbh, 't13'), 'CLUSTERED', 'the key is clustered';
    is $dbh->selectrow_array(q{SELECT type_desc FROM sys.indexes WHERE name = 'ix_t13_x'}),
      'NONCLUSTERED', 'the index is nonclustered, as declared';
  });

$admin->disconnect;
done_testing;
