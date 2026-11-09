use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::Core ();
use DBIO::MSSQL::Deploy;
use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Introspect;
use Storable qw(dclone);

# LIVE (karr k73, review finding). The columns of a foreign key follow the order
# of the key it references: a composite primary key (b, a) must be referenceable,
# by a fresh install and by an upgrade of an existing table, and the second diff
# is empty. Each scenario has a database of its own, _dbio_k73_<pid>_<n>, dropped
# at the end. t/105-ddl-fk-key-order.t pins the statements offline.

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
  my $schema_class = "K73::${tag}::Schema";
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
  my $db = sprintf '_dbio_k73_%d_%d', $$, ++$seq;
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


my $int = { data_type => 'int' };

# the foreign keys of the database: name:from(cols)->table(cols), in clause order
sub fks {
  my ($dbh) = @_;
  my $rows = $dbh->selectall_arrayref(q{
    SELECT fk.name, fc.constraint_column_id, pc.name, rt.name, rc.name
    FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = fk.object_id
    JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
    JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
    JOIN sys.tables rt ON rt.object_id = fc.referenced_object_id
    ORDER BY fk.name, fc.constraint_column_id});
  my (%by, @order);
  for my $r (@$rows) { push @order, $r->[0] unless $by{$r->[0]}; push @{ $by{$r->[0]} }, $r }
  return join ' ', map {
    my @c = @{ $by{$_} };
    "$_:(" . join(',', map { $_->[2] } @c) . ")->$c[0][3](" . join(',', map { $_->[4] } @c) . ')'
  } @order;
}

sub two {
  my ($tag, $pk, $uniques, $cond, $cols) = @_;
  (my $t = $tag) =~ s/\W/_/g;
  return (
    [ P => 'p', { a => $int, b => $int }, $pk, { uniques => $uniques } ],
    [ C => 'c', { id => $int, x => $int, y => $int }, 'id',
      { rels => [ [ p => "K73::${t}::Schema::Result::P", $cond ] ] } ],
  );
}
my $straight = { 'foreign.a' => 'self.x', 'foreign.b' => 'self.y' };
my $swap     = { 'foreign.a' => 'self.y', 'foreign.b' => 'self.x' };

# 1. a fresh install of a schema with PK (b, a) and a foreign key onto it
scenario('fresh install',
  before => [],
  after  => [ two('fresh install', ['b', 'a'], undef, $straight) ],
  check  => sub { is fks($_[0]), 'FK_c_y_x:(y,x)->p(b,a)', 'the key is created in the order of the primary key' });

# 2. the same with the pairs crossed
scenario('fresh install, crossed pairs',
  before => [],
  after  => [ two('fresh install, crossed pairs', ['b', 'a'], undef, $swap) ],
  check  => sub { is fks($_[0]), 'FK_c_x_y:(x,y)->p(b,a)', 'x pairs with b, y with a' });

# 3. an upgrade: both tables exist with the key (b, a), the foreign key is new
scenario('upgrade adds the key',
  before => [
    'CREATE TABLE p (b INT NOT NULL, a INT NOT NULL, CONSTRAINT PK_p PRIMARY KEY (b, a))',
    'CREATE TABLE c (id INT NOT NULL PRIMARY KEY, x INT NOT NULL, y INT NOT NULL)',
  ],
  after  => [ two('upgrade adds the key', ['b', 'a'], undef, $straight) ],
  check  => sub { is fks($_[0]), 'FK_c_y_x:(y,x)->p(b,a)', 'added to the existing tables in key order' });

# 4. an upgrade where the existing key is (a, b) and the classes want (b, a):
# the foreign key goes around the replaced key and comes back in the new order
scenario('key order changes under a foreign key',
  before => [
    'CREATE TABLE p (a INT NOT NULL, b INT NOT NULL, CONSTRAINT PK_p PRIMARY KEY (a, b))',
    'CREATE TABLE c (id INT NOT NULL PRIMARY KEY, x INT NOT NULL, y INT NOT NULL)',
    'ALTER TABLE c ADD CONSTRAINT FK_c_x_y FOREIGN KEY (x, y) REFERENCES p (a, b)',
  ],
  after  => [ two('key order changes under a foreign key', ['b', 'a'], undef, $straight) ],
  check  => sub { is fks($_[0]), 'FK_c_y_x:(y,x)->p(b,a)', 'the old key is gone, the new one follows the new key order' });

# 5. a unique constraint (b, a) is the referenced key
scenario('unique constraint as target',
  before => [],
  after  => [ two('unique constraint as target', ['a'], { p_ba => ['b', 'a'] }, $straight) ],
  check  => sub { is fks($_[0]), 'FK_c_y_x:(y,x)->p(b,a)', 'follows the unique constraint' });

done_testing;
