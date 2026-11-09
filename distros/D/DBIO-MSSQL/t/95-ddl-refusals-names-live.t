use strict;
use warnings;
use Test::More;
use DBI;

use lib 't/lib';
use K71Fixtures qw(schema_for rel @REFUSED @ALLOWED);

use DBIO::MSSQL::DDL;
use DBIO::MSSQL::Deploy;

# LIVE (karr k71, review round 2). The counterpart of t/94: what the driver
# refuses is what the server refuses, and what the driver lets through, the
# server accepts.
#
#  A. The cascade rule (Msg 1785). For every fixture of t/94 the DDL is made
#     WITHOUT the driver's check and run on the server: the refused ones have
#     to fail with the server's own message, the accepted ones have to run.
#     Then a table of raw statements that the fixtures do not reach (columns
#     that are referenced, mixed cycles), each with the verdict of the
#     driver's function and of the server, which have to be the same.
#  B. A unique constraint that core names <table>_<columns> when a table has
#     that name (Msg 2714 before), and a key and a constraint over 128
#     characters (Msg 103 before): deployed, and the second diff is empty.
#  C. The aliases of the character and binary types, deployed and read back.
#  D. A key over columns with a blank and a hyphen in their names.
#  E. A table with a dot in its name is refused and nothing is created.
#
# Every part has a database of its own, _dbio_k71p_<pid>_<n>, dropped at the
# end; nothing else is touched.

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

sub with_db {
  my ($code) = @_;
  my $db = sprintf '_dbio_k71p_%d_%d', $$, ++$seq;
  my $dsn_db = $dsn;
  $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
    or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;
  $admin->do("CREATE DATABASE [$db]");
  my $ok = eval { $code->($dsn_db); 1 };
  my $err = $@;
  eval {
    $admin->do("IF DB_ID('$db') IS NOT NULL BEGIN ALTER DATABASE [$db] "
      . "SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db] END");
    1;
  } or diag "could not drop $db: $@";
  die $err unless $ok;
}

sub empty_database {
  my ($dbh) = @_;
  for my $r (@{ $dbh->selectall_arrayref(
      'SELECT OBJECT_NAME(parent_object_id), name FROM sys.foreign_keys') }) {
    $dbh->do("ALTER TABLE [$r->[0]] DROP CONSTRAINT [$r->[1]]");
  }
  $dbh->do("DROP TABLE [$_->[0]]") for @{ $dbh->selectall_arrayref('SELECT name FROM sys.tables') };
}

sub statements { grep { /\S/ } split /\n\n+/, $_[0] }

sub run_ddl {
  my ($dbh, $ddl) = @_;
  my $ok = eval { $dbh->do($_) for statements($ddl); 1 };
  return $ok ? undef : $@;
}

# ---- A. the cascade rule
with_db(sub {
  my ($dsn_db) = @_;
  my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);

  # the DDL as it would be without the check
  my $unchecked = sub {
    no warnings 'redefine';
    local *DBIO::MSSQL::DDL::_check_cascade_paths = sub { };
    DBIO::MSSQL::DDL->install_ddl($_[0]);
  };

  for my $c (@REFUSED) {
    my ($label, $tables) = @$c;
    my $ddl = $unchecked->(schema_for(@$tables));
    my $err = run_ddl($dbh, $ddl);
    like $err, qr/may cause cycles or multiple cascade paths/,
      "the server refuses it too: $label";
    empty_database($dbh);
  }
  for my $c (@ALLOWED) {
    my ($label, $tables) = @$c;
    my $ddl = $unchecked->(schema_for(@$tables));
    my $err = run_ddl($dbh, $ddl);
    is $err, undef, "the server accepts it too: $label";
    empty_database($dbh);
  }

  # raw statements: the verdict of the driver's function and of the server
  my $fk = sub {
    my ($table, $cols, $to, $to_cols, $del, $upd) = @_;
    +{ table => $table, label => "constraint of $table", from_cols => $cols, to_table => $to,
       to_cols => $to_cols, on_delete => $del || 'NO ACTION', on_update => $upd || 'NO ACTION' };
  };
  my @raw = (
    [ 'legs SET NULL on a column that two keys reference with ON UPDATE CASCADE',
      [ 'CREATE TABLE r (id int primary key)',
        'CREATE TABLE x (id int primary key, r int null unique)',
        'CREATE TABLE y (id int primary key, r int null unique)',
        'CREATE TABLE z (id int primary key, a int null, b int null)',
        'ALTER TABLE x ADD CONSTRAINT fx FOREIGN KEY (r) REFERENCES r(id) ON DELETE SET NULL',
        'ALTER TABLE y ADD CONSTRAINT fy FOREIGN KEY (r) REFERENCES r(id) ON DELETE SET NULL',
        'ALTER TABLE z ADD CONSTRAINT fza FOREIGN KEY (a) REFERENCES x(r) ON UPDATE CASCADE',
        'ALTER TABLE z ADD CONSTRAINT fzb FOREIGN KEY (b) REFERENCES y(r) ON UPDATE CASCADE' ],
      [ $fk->('x', ['r'], 'r', ['id'], 'SET NULL'), $fk->('y', ['r'], 'r', ['id'], 'SET NULL'),
        $fk->('z', ['a'], 'x', ['r'], undef, 'CASCADE'), $fk->('z', ['b'], 'y', ['r'], undef, 'CASCADE') ],
      1 ],
    [ 'the same, one of the two keys NO ACTION',
      [ 'CREATE TABLE r (id int primary key)',
        'CREATE TABLE x (id int primary key, r int null unique)',
        'CREATE TABLE y (id int primary key, r int null unique)',
        'CREATE TABLE z (id int primary key, a int null, b int null)',
        'ALTER TABLE x ADD CONSTRAINT fx FOREIGN KEY (r) REFERENCES r(id) ON DELETE SET NULL',
        'ALTER TABLE y ADD CONSTRAINT fy FOREIGN KEY (r) REFERENCES r(id) ON DELETE SET NULL',
        'ALTER TABLE z ADD CONSTRAINT fza FOREIGN KEY (a) REFERENCES x(r) ON UPDATE CASCADE',
        'ALTER TABLE z ADD CONSTRAINT fzb FOREIGN KEY (b) REFERENCES y(r)' ],
      [ $fk->('x', ['r'], 'r', ['id'], 'SET NULL'), $fk->('y', ['r'], 'r', ['id'], 'SET NULL'),
        $fk->('z', ['a'], 'x', ['r'], undef, 'CASCADE'), $fk->('z', ['b'], 'y', ['r']) ],
      0 ],
    [ 'ON UPDATE CASCADE legs onto columns that are not referenced',
      [ 'CREATE TABLE r (id int primary key)',
        'CREATE TABLE x (id int primary key, r int)',
        'CREATE TABLE y (id int primary key, r int)',
        'CREATE TABLE z (id int primary key, a int, b int)',
        'ALTER TABLE x ADD CONSTRAINT fx FOREIGN KEY (r) REFERENCES r(id) ON UPDATE CASCADE',
        'ALTER TABLE y ADD CONSTRAINT fy FOREIGN KEY (r) REFERENCES r(id) ON UPDATE CASCADE',
        'ALTER TABLE z ADD CONSTRAINT fza FOREIGN KEY (a) REFERENCES x(id) ON DELETE CASCADE',
        'ALTER TABLE z ADD CONSTRAINT fzb FOREIGN KEY (b) REFERENCES y(id) ON DELETE CASCADE' ],
      [ $fk->('x', ['r'], 'r', ['id'], undef, 'CASCADE'), $fk->('y', ['r'], 'r', ['id'], undef, 'CASCADE'),
        $fk->('z', ['a'], 'x', ['id'], 'CASCADE'), $fk->('z', ['b'], 'y', ['id'], 'CASCADE') ],
      0 ],
    [ 'a cycle: CASCADE one way, SET NULL back',
      [ 'CREATE TABLE a (id int primary key, b int null)',
        'CREATE TABLE b (id int primary key, a int null)',
        'ALTER TABLE a ADD CONSTRAINT fa FOREIGN KEY (b) REFERENCES b(id) ON DELETE CASCADE',
        'ALTER TABLE b ADD CONSTRAINT fb FOREIGN KEY (a) REFERENCES a(id) ON DELETE SET NULL' ],
      [ $fk->('a', ['b'], 'b', ['id'], 'CASCADE'), $fk->('b', ['a'], 'a', ['id'], 'SET NULL') ],
      1 ],
    [ 'a cycle: ON DELETE CASCADE one way, ON UPDATE CASCADE back',
      [ 'CREATE TABLE a (id int primary key, b int null)',
        'CREATE TABLE b (id int primary key, a int null)',
        'ALTER TABLE a ADD CONSTRAINT fa FOREIGN KEY (b) REFERENCES b(id) ON DELETE CASCADE',
        'ALTER TABLE b ADD CONSTRAINT fb FOREIGN KEY (a) REFERENCES a(id) ON UPDATE CASCADE' ],
      [ $fk->('a', ['b'], 'b', ['id'], 'CASCADE'), $fk->('b', ['a'], 'a', ['id'], undef, 'CASCADE') ],
      0 ],
    [ 'a cycle: ON DELETE SET NULL both ways',
      [ 'CREATE TABLE a (id int primary key, b int null)',
        'CREATE TABLE b (id int primary key, a int null)',
        'ALTER TABLE a ADD CONSTRAINT fa FOREIGN KEY (b) REFERENCES b(id) ON DELETE SET NULL',
        'ALTER TABLE b ADD CONSTRAINT fb FOREIGN KEY (a) REFERENCES a(id) ON DELETE SET NULL' ],
      [ $fk->('a', ['b'], 'b', ['id'], 'SET NULL'), $fk->('b', ['a'], 'a', ['id'], 'SET NULL') ],
      0 ],
  );
  for my $r (@raw) {
    my ($label, $sql, $entries, $expect_refused) = @$r;
    my $err = run_ddl($dbh, join "\n\n", @$sql);
    empty_database($dbh);
    my $server = defined $err ? 1 : 0;
    my $driver = eval { DBIO::MSSQL::DDL::_check_cascade_paths($entries); 0 } // 1;
    $expect_refused //= $server;   # the mixed cycle: whatever the server says, the driver agrees
    is $server, $expect_refused, "server: $label (" . ($server ? 'refused' : 'accepted') . ')'
      or diag $err;
    is $driver, $server, "driver and server agree: $label";
  }
  $dbh->disconnect;
});

# ---- B. constraint names
with_db(sub {
  my ($dsn_db) = @_;
  my $lt = 'lt' x 50;     # a table name of 100 characters
  my $lc = 'lc' x 20;
  my $class = schema_for(
    ['user', undef, { email => { data_type => 'varchar', size => 50 } },
      sub { $_[0]->add_unique_constraint([qw(email)]) }],
    ['user_email'],
    ['parent'],
    [$lt, [ rel(p => 'parent', $lc, on_delete => 'cascade') ], undef,
      sub { $_[0]->add_unique_constraint([$lc]) }],
  );
  my $schema = $class->connect($dsn_db, $user, $pass, { %conn });
  my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
  my $diff = $deploy->diff;
  ok eval { $deploy->apply($diff); 1 }, 'the server accepts the schema (user, user_email, 100-character names)'
    or diag $@ . "\n" . $diff->as_sql;
  my $dbh = $schema->storage->dbh;
  my @uq = map { $_->[0] } @{ $dbh->selectall_arrayref(
    q{SELECT name FROM sys.key_constraints WHERE type = 'UQ' ORDER BY name}) };
  ok scalar(grep { $_ eq 'UQ_user_email' } @uq), 'the constraint of user(email) is UQ_user_email';
  my @fk = map { $_->[0] } @{ $dbh->selectall_arrayref('SELECT name FROM sys.foreign_keys') };
  is scalar(@fk), 1, 'one key';
  is length $fk[0], 128, 'its name is 128 characters long' or diag $fk[0];
  is $fk[0], DBIO::MSSQL::DDL::_constraint_name('FK', $lt, $lc), '... the one the function makes';
  ok scalar(grep { length($_) == 128 } @uq), 'the long unique constraint is cut to 128 too';
  my $again = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
  ok !$again->has_changes, 'the second diff is empty' or diag $again->summary . "\n" . $again->as_sql;
  $schema->storage->disconnect;
});

# ---- C. the type aliases
with_db(sub {
  my ($dsn_db) = @_;
  my %alias = (
    cv  => ['char varying', 10],            nv  => ['nchar varying', 11],
    ncv => ['national character varying', 12], nsv => ['national char varying', 13],
    nc  => ['national character', 14],      bv  => ['binary varying', 15],
    ch  => ['character', 16],               cvu => ['CHARACTER VARYING', 17],
  );
  my $class = schema_for(['alias', undef,
    { map { $_ => { data_type => $alias{$_}[0], size => $alias{$_}[1], is_nullable => 1 } } keys %alias }]);
  my $schema = $class->connect($dsn_db, $user, $pass, { %conn });
  my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
  my $diff = $deploy->diff;
  ok eval { $deploy->apply($diff); 1 }, 'the server accepts the aliases' or diag $@ . "\n" . $diff->as_sql;
  my $dbh = $schema->storage->dbh;
  my %len = map { $_->[0] => $_->[1] } @{ $dbh->selectall_arrayref(
    q{SELECT column_name, character_maximum_length FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'alias'}) };
  for my $col (sort keys %alias) {
    is $len{$col}, $alias{$col}[1], "'$alias{$col}[0]' keeps its length $alias{$col}[1] on the server";
  }
  my $again = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
  ok !$again->has_changes, 'the second diff is empty' or diag $again->summary . "\n" . $again->as_sql;
  $schema->storage->disconnect;

  for my $bad (['bit', 8], ['BIT(8)'], ['boolean', 8], ['ENUM'], ['enum(a,b)']) {
    my $c = schema_for(['bad', undef, { v => { data_type => $bad->[0], (defined $bad->[1] ? (size => $bad->[1]) : ()) } }]);
    eval { DBIO::MSSQL::DDL->install_ddl($c) };
    like $@, qr/refus/, "'$bad->[0]' is refused before the server";
  }
});

# ---- D. columns with a blank and a hyphen
with_db(sub {
  my ($dsn_db) = @_;
  local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /illegal accessor/ };
  my $c = 'K95::D';
  eval "package $c; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL');
        package $c\::Result::Par; use base 'DBIO::Core'; __PACKAGE__->table('par');
        __PACKAGE__->add_columns('par id' => { data_type => 'integer' });
        __PACKAGE__->set_primary_key('par id');
        package $c\::Result::Kid; use base 'DBIO::Core'; __PACKAGE__->table('kid');
        __PACKAGE__->add_columns(id => { data_type => 'integer' }, 'my-par' => { data_type => 'integer' });
        __PACKAGE__->set_primary_key('id');
        __PACKAGE__->belongs_to(par => '$c\::Result::Par', { 'foreign.par id' => 'self.my-par' });
        1" or die $@;
  $c->register_class(Par => "$c\::Result::Par");
  $c->register_class(Kid => "$c\::Result::Kid");
  my $schema = $c->connect($dsn_db, $user, $pass, { %conn });
  my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
  my $diff = $deploy->diff;
  ok eval { $deploy->apply($diff); 1 }, 'the server accepts the schema' or diag $@ . "\n" . $diff->as_sql;
  my $dbh = $schema->storage->dbh;
  my ($n) = $dbh->selectrow_array('SELECT COUNT(*) FROM sys.foreign_keys');
  is $n, 1, 'the key over the columns with a blank and a hyphen exists';
  my $again = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
  ok !$again->has_changes, 'the second diff is empty' or diag $again->summary . "\n" . $again->as_sql;
  $schema->storage->disconnect;
});

# ---- E. a dot in a table name
# was: the diff (and so deploy) refused the table "other.t" ("karr k72") and
# created nothing. Since the decision of 2026-10-25 the table is made in the
# schema "other", which is created (t/112 holds the schema support in full);
# what is refused is a name with two dots.
with_db(sub {
  my ($dsn_db) = @_;
  my $c = 'K95::E';
  eval "package $c; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL');
        package $c\::Result::T; use base 'DBIO::Core'; __PACKAGE__->table('other.t');
        __PACKAGE__->add_columns(id => { data_type => 'integer' });
        __PACKAGE__->set_primary_key('id'); 1" or die $@;
  $c->register_class(T => "$c\::Result::T");
  my $schema = $c->connect($dsn_db, $user, $pass, { %conn });
  my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
  my $diff = eval { $deploy->diff };
  ok $diff, 'the diff is made' or diag $@;
  ok eval { $deploy->apply($diff); 1 }, 'and applied' or diag $@;
  my ($n) = $schema->storage->dbh->selectrow_array(
    q{SELECT COUNT(*) FROM sys.tables WHERE name = 't' AND SCHEMA_NAME(schema_id) = 'other'});
  is $n, 1, 'the table t is in the schema other';
  ($n) = $schema->storage->dbh->selectrow_array(q{SELECT COUNT(*) FROM sys.tables WHERE name = 'other.t'});
  is $n, 0, 'there is no table called other.t in dbo';
  $schema->storage->disconnect;
});

$admin->disconnect;
done_testing;
