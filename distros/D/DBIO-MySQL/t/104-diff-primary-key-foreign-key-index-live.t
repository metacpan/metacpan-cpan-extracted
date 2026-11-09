use strict;
use warnings;
use Test::More;

# LIVE half of karr k106/k107 (t/103 has the offline half): what an upgrade
# does with the index of a foreign key and with an AUTO_INCREMENT column when a
# primary key changes -- asked of the servers, MySQL and MariaDB each for
# itself. Every case installs version 1 of the schema with install (NOT with
# upgrade: an upgrade from an empty database writes the indexes the server
# would make for a constraint itself, which hides what the next diff makes of
# them), puts rows in, upgrades to version 2 and asks the server and the diff:
#   B2. the server names the index it makes for a foreign key after the
#       constraint (<table>_<columns>_fk) and uses an index that is there
#       already, so the fixed constraint name of install and upgrade makes a
#       constraint the diff re-creates find "its" index again. After the
#       upgrade the second diff is EMPTY (no CREATE INDEX / DROP INDEX of the
#       index the server made): the key of a parent changes under a foreign key
#       (t/100 h), a self reference loses its key, the action of a foreign key
#       changes (unset -> cascade and back), and a constraint the server named
#       <table>_ibfk_1 is renamed by the upgrade and keeps one index;
#   S4. a key that grows, or a UNIQUE key that becomes the primary key, under a
#       foreign key that needed the index the diff drops: valid upgrades the
#       diff refused, or that the server refused with 1553;
#   S5. AUTO_INCREMENT leaves the key or is not first in the new one: 1075 in
#       the middle of the upgrade before the UNIQUE index over it was created.
# The rows stay. Works in databases of its own (see t/88). Needs
# DBIO_TEST_MYSQL_DSN, _USER and _PASS.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
my @DBS;
sub drop_databases { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$_`") for @DBS }
END { if ($raw) { local ($@, $?); eval { drop_databases() } } }

my $k = 0;
sub fresh_db {
  my $db = "dbio_k107b_${$}_" . ++$k;
  push @DBS, $db;
  return $db if eval { $raw->do("DROP DATABASE IF EXISTS `$db`"); $raw->do("CREATE DATABASE `$db`"); 1 };
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}
note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

my $n = 0;
# sources: moniker => { cols => [..], pk => [..], uniques => [[name, [cols]]], rels => [[name, moniker, cond, attrs]] }
sub make_schema {
  my ($db, %sources) = @_;
  my $ns = 'K107Fk::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $moniker (sort keys %sources) {
    my $s = $sources{$moniker};
    my $class = "${ns}::Result::$moniker";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table(lc $moniker);
    $class->add_columns(@{ $s->{cols} });
    $class->set_primary_key(@{ $s->{pk} }) if $s->{pk};
    $class->add_unique_constraint(@$_) for @{ $s->{uniques} // [] };
    $class->belongs_to($_->[0] => "${ns}::Result::$_->[1]", $_->[2], $_->[3] // {}) for @{ $s->{rels} // [] };
    $ns->register_class($moniker => $class);
  }
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$db`"] });
}

sub primary_cols {
  my ($db, $t) = @_;
  return [ map { $_->[0] } @{ $raw->selectall_arrayref(
    "SELECT column_name FROM information_schema.statistics WHERE table_schema = ? AND table_name = ? "
  . "AND index_name = 'PRIMARY' ORDER BY seq_in_index", undef, $db, $t) } ];
}
sub fk_rows {
  my ($db, $t) = @_;
  return $raw->selectall_arrayref(
    "SELECT constraint_name, delete_rule FROM information_schema.referential_constraints "
  . "WHERE constraint_schema = ? AND table_name = ? ORDER BY 1", undef, $db, $t);
}
sub index_names {
  my ($db, $t) = @_;
  return join ',', sort map { $_->[0] } @{ $raw->selectall_arrayref(
    "SELECT DISTINCT index_name FROM information_schema.statistics WHERE table_schema = ? AND table_name = ?", undef, $db, $t) };
}
sub sqls { my ($d) = @_; return join "\n", map { $_->as_sql } @{ $d ? $d->operations : [] } }

# install v1 (with install), run $prepare->($db), upgrade to v2: ($db, $upgrade_diff, $sql)
sub scenario {
  my ($label, $v1, $v2, $prepare, %opts) = @_;
  my $db = fresh_db();
  my $s1 = make_schema($db, %$v1);
  ok eval { DBIO::MySQL::Deploy->new(schema => $s1)->install; 1 }, "$label: version 1 is installed (install)" or diag $@;
  $raw->do("USE `$db`");
  $prepare->($db) if $prepare;
  my $s2 = make_schema($db, %$v2);
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade(%opts) };
  my $err = $@;
  ok !$err, "$label: the upgrade works" or diag "$err";
  my $sql = sqls($diff);
  note "$label:\n$sql";
  return ($db, $s2, $sql, $s1);
}
sub converged {
  my ($schema, $label) = @_;
  my $again = eval { my $d = DBIO::MySQL::Deploy->new(schema => $schema)->diff; $d->operations; $d };
  ok $again && !$again->has_changes, "$label: the second diff is empty"
    or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
}
sub finish { $_->storage->disconnect for @_ }

my $int  = { data_type => 'int' };
my $nint = { data_type => 'int', is_nullable => 1 };
my $ai   = { data_type => 'int', is_auto_increment => 1 };

# --- B2 a. the key of the parent changes under a foreign key (t/100 h) ---
{
  my $q = { cols => [ id => $int, pa => $int ], pk => ['id'], rels => [[ parent => P => { 'foreign.a' => 'self.pa' } ]] };
  my ($db, $s2, $sql, $s1) = scenario('B2 a',
    { P => { cols => [ a => $int, b => $int ], pk => [qw(a b)] }, Q => $q },
    { P => { cols => [ a => $int, b => $int ], pk => ['b'], uniques => [[ p_a => ['a'] ]] }, Q => $q },
    sub { $raw->do($_) for "INSERT INTO p VALUES (1, 1), (2, 2)", "INSERT INTO q VALUES (1, 1), (2, 2)" },
  );
  is_deeply primary_cols($db, 'p'), ['b'], 'B2 a: the key of p is (b)';
  is_deeply [ map { $_->[0] } @{ fk_rows($db, 'q') } ], ['q_pa_fk'], 'B2 a: the foreign key of q is there again, under its fixed name';
  is $raw->selectrow_array("SELECT COUNT(*) FROM q"), 2, 'B2 a: the rows are still there';
  converged($s2, 'B2 a');
  finish($s1, $s2);
}

# --- B2 b. the key of the child is composed in another order ---
{
  my $c = { cols => [ pid => $int, n => $int ], rels => [[ p => P => { 'foreign.id' => 'self.pid' } ]] };
  my $p = { cols => [ id => $int ], pk => ['id'] };
  my ($db, $s2, $sql, $s1) = scenario('B2 b',
    { P => $p, C => { %$c, pk => [qw(pid n)] } },
    { P => $p, C => { %$c, pk => [qw(n pid)] } },
    sub { $raw->do($_) for "INSERT INTO p VALUES (1)", "INSERT INTO c VALUES (1, 1), (1, 2)" },
  );
  is_deeply primary_cols($db, 'c'), [qw(n pid)], 'B2 b: the key of c is (n, pid)';
  is_deeply [ map { $_->[0] } @{ fk_rows($db, 'c') } ], ['c_pid_fk'], 'B2 b: the foreign key of c is there';
  converged($s2, 'B2 b');

  # and back: the index the server made goes after the key (S4)
  my $s3 = make_schema($db, P => $p, C => { %$c, pk => [qw(pid n)] });
  # back to (pid, n): the index the server made for the foreign key goes
  my $d3 = eval { DBIO::MySQL::Deploy->new(schema => $s3)->upgrade(allow_destructive => 1) };
  ok !$@, 'B2 b: and back to (pid, n): the upgrade works' or diag "$@";
  is_deeply primary_cols($db, 'c'), [qw(pid n)], 'B2 b: the key of c is (pid, n) again';
  converged($s3, 'B2 b back');
  finish($s1, $s2, $s3);
}

# --- B2 c. a self reference loses its key; a UNIQUE key takes the foreign key over ---
{
  my $rel = [[ parent => N => { 'foreign.id' => 'self.parent_id' } ]];
  my ($db, $s2, $sql, $s1) = scenario('B2 c',
    { N => { cols => [ id => $int, parent_id => $nint ], pk => ['id'], rels => $rel } },
    { N => { cols => [ id => $int, parent_id => $nint ], uniques => [[ n_id => ['id'] ]], rels => $rel } },
    sub { $raw->do($_) for "INSERT INTO n VALUES (1, NULL), (2, 1)" },
    allow_destructive => 1,   # n loses its primary key
  );
  is_deeply primary_cols($db, 'n'), [], 'B2 c: n has no key any more';
  is_deeply [ map { $_->[0] } @{ fk_rows($db, 'n') } ], ['n_parent_id_fk'], 'B2 c: the self reference is there';
  is $raw->selectrow_array("SELECT COUNT(*) FROM n"), 2, 'B2 c: the rows are still there';
  converged($s2, 'B2 c');
  finish($s1, $s2);
}

# --- B2 d. the action of a foreign key changes: unset -> cascade and back ---
{
  my $p = { cols => [ id => $int ], pk => ['id'] };
  my $q = sub { { cols => [ id => $int, pa => $int ], pk => ['id'], rels => [[ p => P => { 'foreign.id' => 'self.pa' }, $_[0] ]] } };
  my ($db, $s2, $sql, $s1) = scenario('B2 d',
    { P => $p, Q => $q->({}) }, { P => $p, Q => $q->({ on_delete => 'cascade' }) },
    sub { $raw->do($_) for "INSERT INTO p VALUES (1)", "INSERT INTO q VALUES (1, 1)" },
  );
  is_deeply fk_rows($db, 'q'), [[ 'q_pa_fk', 'CASCADE' ]], 'B2 d: unset -> cascade: the server has the action';
  converged($s2, 'B2 d');
  my $s3 = make_schema($db, P => $p, Q => $q->({}));
  eval { DBIO::MySQL::Deploy->new(schema => $s3)->upgrade };
  ok !$@, 'B2 d: cascade -> unset: the upgrade works' or diag "$@";
  isnt $raw->selectall_arrayref("SELECT delete_rule FROM information_schema.referential_constraints WHERE constraint_schema = ? AND table_name = 'q'", undef, $db)->[0][0],
    'CASCADE', 'B2 d: the action is gone';
  converged($s3, 'B2 d back');
  finish($s1, $s2, $s3);
}

# --- B2 e. a constraint the server named <table>_ibfk_1 ---
{
  my $db = fresh_db();
  $raw->do("CREATE TABLE `$db`.p (id int NOT NULL, PRIMARY KEY (id))");
  $raw->do("CREATE TABLE `$db`.q (id int NOT NULL, pa int NOT NULL, PRIMARY KEY (id), "
         . "CONSTRAINT q_ibfk_1 FOREIGN KEY (pa) REFERENCES p(id))");
  is index_names($db, 'q'), 'PRIMARY,q_ibfk_1', 'B2 e: the server made an index named after the constraint';
  my $s = make_schema($db,
    P => { cols => [ id => $int ], pk => ['id'] },
    Q => { cols => [ id => $int, pa => $int ], pk => ['id'], rels => [[ p => P => { 'foreign.id' => 'self.pa' } ]] });
  eval { DBIO::MySQL::Deploy->new(schema => $s)->upgrade(allow_destructive => 1) };   # q_ibfk_1 goes, q_pa_fk comes
  ok !$@, 'B2 e: the upgrade works' or diag "$@";
  is_deeply [ map { $_->[0] } @{ fk_rows($db, 'q') } ], ['q_pa_fk'], 'B2 e: the constraint has its fixed name';
  is index_names($db, 'q'), 'PRIMARY,q_pa_fk', 'B2 e: and one index, named after it';
  converged($s, 'B2 e');
  finish($s);
}

# --- S4 a. the key of the child grows by the column of its foreign key ---
{
  my $p = { cols => [ id => $int ], pk => ['id'] };
  my $c = { cols => [ pid => $int, n => $int ], rels => [[ p => P => { 'foreign.id' => 'self.pid' } ]] };
  my ($db, $s2, $sql, $s1) = scenario('S4 a',
    { P => $p, C => { %$c, pk => ['n'] } }, { P => $p, C => { %$c, pk => [qw(pid n)] } },
    sub { $raw->do($_) for "INSERT INTO p VALUES (1)", "INSERT INTO c VALUES (1, 1), (1, 2)" },
    allow_destructive => 1,   # the index the server made for the foreign key is not the schema's
  );
  is_deeply primary_cols($db, 'c'), [qw(pid n)], 'S4 a: the key of c is (pid, n)';
  is_deeply [ map { $_->[0] } @{ fk_rows($db, 'c') } ], ['c_pid_fk'], 'S4 a: the foreign key stays';
  is index_names($db, 'c'), 'PRIMARY', 'S4 a: the index the server made for it is gone, the new key serves it';
  converged($s2, 'S4 a');
  finish($s1, $s2);
}

# --- S4 b. the UNIQUE key a foreign key points at becomes the primary key ---
{
  my $q = { cols => [ id => $int, pa => $int ], pk => ['id'], rels => [[ p => P => { 'foreign.a' => 'self.pa' } ]] };
  my ($db, $s2, $sql, $s1) = scenario('S4 b',
    { P => { cols => [ id => $int, a => $int ], pk => ['id'], uniques => [[ p_a => ['a'] ]] }, Q => $q },
    { P => { cols => [ id => $int, a => $int ], pk => ['a'] }, Q => $q },
    sub { $raw->do($_) for "INSERT INTO p VALUES (1, 10), (2, 20)", "INSERT INTO q VALUES (1, 10)" },
    allow_destructive => 1,   # the unique index p_a becomes the primary key and leaves
  );
  is_deeply primary_cols($db, 'p'), ['a'], 'S4 b: the key of p is (a)';
  is index_names($db, 'p'), 'PRIMARY', 'S4 b: the UNIQUE index is gone, the key serves the foreign key';
  is_deeply [ map { $_->[0] } @{ fk_rows($db, 'q') } ], ['q_pa_fk'], 'S4 b: the foreign key of q stays';
  is $raw->selectrow_array("SELECT COUNT(*) FROM q"), 1, 'S4 b: the rows are still there';
  converged($s2, 'S4 b');
  finish($s1, $s2);
}

# --- S5. AUTO_INCREMENT leaves the key, or does not stand first ---
{
  my ($db, $s2, $sql, $s1) = scenario('S5 a',
    { G => { cols => [ id => $ai, code => $int ], pk => ['id'] } },
    { G => { cols => [ id => $ai, code => $int ], pk => ['code'], uniques => [[ g_id => ['id'] ]] } },
    sub { $raw->do("INSERT INTO g (code) VALUES (5), (6)") },
  );
  is_deeply primary_cols($db, 'g'), ['code'], 'S5 a: the key of g is (code)';
  like $raw->selectrow_array("SELECT extra FROM information_schema.columns WHERE table_schema = ? AND table_name = 'g' AND column_name = 'id'", undef, $db),
    qr/auto_increment/i, 'S5 a: id is still AUTO_INCREMENT';
  $raw->do("INSERT INTO g (code) VALUES (7)");
  is $raw->selectrow_array("SELECT COUNT(*) FROM g"), 3, 'S5 a: an INSERT without an id still gets one';
  converged($s2, 'S5 a');
  finish($s1, $s2);
}
{
  my ($db, $s2, $sql, $s1) = scenario('S5 b',
    { G => { cols => [ id => $ai, k => $int ], pk => [qw(id k)] } },
    { G => { cols => [ id => $ai, k => $int ], pk => [qw(k id)], uniques => [[ g_id => ['id'] ]] } },
    sub { $raw->do("INSERT INTO g (k) VALUES (5), (6)") },
  );
  is_deeply primary_cols($db, 'g'), [qw(k id)], 'S5 b: the key of g is (k, id): AUTO_INCREMENT not first';
  is $raw->selectrow_array("SELECT COUNT(*) FROM g"), 2, 'S5 b: the rows are still there';
  converged($s2, 'S5 b');
  finish($s1, $s2);
}

drop_databases();
$raw->disconnect;
undef $raw;
done_testing;
