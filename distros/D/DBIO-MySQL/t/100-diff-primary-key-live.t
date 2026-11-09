use strict;
use warnings;
use Test::More;

# LIVE half of karr k107 (t/99 has the offline half): DBIO::MySQL::Deploy->upgrade
# gives an existing table the primary key the schema names.
#
# WHY IT MATTERS. is_pk was no field of the column comparison and the index
# diff leaves the PRIMARY index out: a table installed without a key stayed
# without one, a table whose key was composed differently kept the old one,
# and the diff said nothing about either. The statement has to be one the
# server takes -- with rows in the table, an AUTO_INCREMENT column, a key that
# only changes its column order -- and only the servers can say that, MySQL
# and MariaDB each for itself. Each case installs version 1 of the schema,
# fills the table, upgrades to version 2 and asks the server:
#   a. a table without a primary key gets one;
#   b. a composite key of other columns is the new key;
#   c. the same columns in another order are the new key (b, a after a, b);
#   d. after each upgrade the next diff has nothing left (it converges), and
#      the rows are still there;
#   e. a table with a UNIQUE key over a NOT NULL column and no primary key
#      is given none (karr k83 beside this card);
#   f. a column that gains AUTO_INCREMENT and is the new key (the server
#      refuses the MODIFY without a key); and an AUTO_INCREMENT key that grows
#      a second column behind the first;
#   g. a schema without a primary key drops the one the table has (the drop is
#      named in the summary): a composite key, an AUTO_INCREMENT key whose
#      column loses the attribute, and one whose column keeps it with a
#      UNIQUE key instead (released for the drop, given back after the key);
#   h. a primary key that a foreign key needs as its index changes: the child
#      foreign key is dropped, the key changes, the index that takes over is
#      created, the foreign key is added again -- the rows stay, the next diff
#      has nothing left. MySQL refuses the plain statement (1553), MariaDB's
#      errno 150 is the same refusal for a plain DROP PRIMARY KEY;
#   i. a new AUTO_INCREMENT column that is the key of a table with rows: ADD
#      COLUMN and ADD PRIMARY KEY in one ALTER TABLE, the rows get their ids;
#   j. a schema that declares a foreign key over a key it does not have is not
#      applied at all: nothing is changed.
# Works in a database of its own (see t/88). Needs DBIO_TEST_MYSQL_DSN, _USER
# and _PASS.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $DB = "dbio_k107_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END { if ($raw) { local ($@, $?); eval { drop_database() } } }

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}
note sprintf 'server %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'), $DB;
$raw->do("USE `$DB`");

my $n = 0;
# sources: moniker => [ [ columns ], [ primary key ] | undef, [ unique ] | undef ]
sub make_schema {
  my (%sources) = @_;
  my $ns = 'K107Live::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $moniker (sort keys %sources) {
    my ($cols, $pk, $unique, $rels) = @{ $sources{$moniker} };
    my $class = "${ns}::Result::$moniker";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table(lc $moniker);
    $class->add_columns(@$cols);
    $class->set_primary_key(@$pk) if $pk;
    $class->add_unique_constraint(@$unique) if $unique;
    $class->belongs_to($_->[0] => "${ns}::Result::$_->[1]", $_->[2]) for @{ $rels // [] };
    $ns->register_class($moniker => $class);
  }
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

sub primary_cols {
  my ($t) = @_;
  return [ map { $_->[0] } @{ $raw->selectall_arrayref(
    "SELECT column_name FROM information_schema.statistics WHERE table_schema = ? AND table_name = ? "
  . "AND index_name = 'PRIMARY' ORDER BY seq_in_index", undef, $DB, $t) } ];
}
sub upgrade_to {
  my ($schema, %opts) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade(%opts) };
  my $err = $@;
  return ($diff, $err);
}
sub converged {
  my ($schema, $what) = @_;
  my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $again && !$again->has_changes, "$what: the next diff has nothing left"
    or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
}
my $int = { data_type => 'int' };

# --- install version 1 ---
my @v1 = (
  A => [ [ id => $int, v => { data_type => 'int', is_nullable => 1 } ], undef, [ a_v => ['v'] ] ],
  B => [ [ a => $int, b => $int, c => $int ], ['a'] ],
  C => [ [ a => $int, b => $int ], [qw(a b)] ],
  E => [ [ code => $int, label => { data_type => 'int', is_nullable => 1 } ], undef, [ e_code => ['code'] ] ],
  F => [ [ id => $int, v => $int ], undef ],
  G => [ [ id => { data_type => 'int', is_auto_increment => 1 }, k => $int ], ['id'] ],
  H => [ [ a => $int, b => $int ], [qw(a b)] ],
  I => [ [ id => { data_type => 'int', is_auto_increment => 1 }, k => $int ], ['id'] ],
  J => [ [ id => { data_type => 'int', is_auto_increment => 1 }, k => $int ], ['id'] ],
  N => [ [ k => $int ], undef ],
  P => [ [ a => $int, b => $int ], [qw(a b)] ],
  Q => [ [ id => $int, pa => $int ], ['id'], undef, [ [ parent => P => { 'foreign.a' => 'self.pa' } ] ] ],
);
my $s1 = make_schema(@v1);
# with install, not upgrade: an upgrade from an empty database leaves the
# indexes the server makes for a constraint to the server and so hides what the
# next diff makes of them (karr k106)
my $e1 = do { local $@; eval { DBIO::MySQL::Deploy->new(schema => $s1)->install; 1 } ? '' : $@ };
ok !$e1, 'version 1 is installed (install)' or diag $e1;
is_deeply primary_cols('a'), [], 'a: installed without a primary key';
is_deeply primary_cols('c'), [qw(a b)], 'c: installed with the key (a, b)';
$raw->do($_) for
  "INSERT INTO a (id, v) VALUES (1, 10), (2, 20)", "INSERT INTO b VALUES (1, 1, 1), (2, 1, 2)",
  "INSERT INTO c VALUES (1, 1), (1, 2)", "INSERT INTO e (code) VALUES (7)",
  "INSERT INTO f VALUES (1, 1), (2, 2)", "INSERT INTO g (k) VALUES (5), (6)",
  "INSERT INTO h VALUES (1, 1), (1, 2)", "INSERT INTO i (k) VALUES (5), (6)", "INSERT INTO j (k) VALUES (5), (6)",
  "INSERT INTO n VALUES (10), (20)", "INSERT INTO p VALUES (1, 1), (2, 2)", "INSERT INTO q VALUES (1, 1), (2, 2)";
is scalar @{ $raw->selectall_arrayref("SELECT 1 FROM information_schema.referential_constraints WHERE constraint_schema = ? AND table_name = 'q'", undef, $DB) }, 1,
  'q: installed with its foreign key over p.a';

# --- version 2 ---
my $s2 = make_schema(
  A => [ [ id => $int, v => { data_type => 'int', is_nullable => 1 } ], ['id'], [ a_v => ['v'] ] ],
  B => [ [ a => $int, b => $int, c => $int ], [qw(b c)] ],
  C => [ [ a => $int, b => $int ], [qw(b a)] ],
  E => [ [ code => $int, label => { data_type => 'int', is_nullable => 1 }, more => { data_type => 'int', is_nullable => 1 } ],
         undef, [ e_code => ['code'] ] ],
  F => [ [ id => { data_type => 'int', is_auto_increment => 1 }, v => $int ], ['id'] ],
  G => [ [ id => { data_type => 'int', is_auto_increment => 1 }, k => $int ], [qw(id k)] ],
  H => [ [ a => $int, b => $int ], undef ],
  I => [ [ id => $int, k => $int ], undef ],
  J => [ [ id => { data_type => 'int', is_auto_increment => 1 }, k => $int ], undef, [ j_id => ['id'] ] ],
  N => [ [ id => { data_type => 'int', is_auto_increment => 1 }, k => $int ], ['id'] ],
  P => [ [ a => $int, b => $int ], ['b'], [ p_a => ['a'] ] ],
  Q => [ [ id => $int, pa => $int ], ['id'], undef, [ [ parent => P => { 'foreign.a' => 'self.pa' } ] ] ],
);
my ($d2, $e2) = upgrade_to($s2, allow_destructive => 1);   # h, i and j lose their key
ok !$e2, 'upgrade to version 2 works on both servers' or diag $e2;
my $sql = join "\n", map { $_->as_sql } @{ $d2 ? $d2->operations : [] };
note $sql;

is_deeply primary_cols('a'), ['id'],      'a: the table without a key has one';
is_deeply primary_cols('b'), [qw(b c)],   'b: the composite key is (b, c)';
is_deeply primary_cols('c'), [qw(b a)],   'c: (b, a) after (a, b): the order counts';
is_deeply primary_cols('e'), [],          'e: a UNIQUE key over a NOT NULL column is no reason for a primary key';
is_deeply primary_cols('f'), ['id'],      'f: a column that gains AUTO_INCREMENT is the new key';
is_deeply primary_cols('g'), [qw(id k)],  'f: an AUTO_INCREMENT key grows a second column';

is_deeply primary_cols('h'), [], 'g: a composite key the schema does not have is dropped';
like $d2->summary, qr/^  -pk: DROP PRIMARY KEY on h \(was a, b\)$/m, 'g: the summary names the drop' if $d2;
is_deeply primary_cols('i'), [], 'g: an AUTO_INCREMENT key the schema does not have is dropped';
is_deeply primary_cols('j'), [], 'g: so is one whose column keeps AUTO_INCREMENT ...';
my ($ai_i, $ai_j) = map { $raw->selectrow_array("SELECT extra FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = 'id'", undef, $DB, $_) } qw(i j);
unlike $ai_i // '', qr/auto_increment/i, 'g: ... the column that loses the attribute is a plain column now';
like   $ai_j // '', qr/auto_increment/i, 'g: ... the one that keeps it has it again (given back after its UNIQUE key)';
$raw->do("INSERT INTO j (k) VALUES (7)");
is $raw->selectrow_array("SELECT COUNT(*) FROM j"), 3, 'g: an INSERT without an id still gets one';

is_deeply primary_cols('p'), ['b'], 'h: the key a foreign key needed is (b) now';
is $raw->selectrow_array("SELECT COUNT(*) FROM information_schema.referential_constraints WHERE constraint_schema = ? AND table_name = 'q' AND referenced_table_name = 'p'", undef, $DB), 1,
  'h: the foreign key of q is there again';
my @at = map { index $sql, $_ } 'DROP FOREIGN KEY', 'DROP PRIMARY KEY, ADD PRIMARY KEY (`b`)', 'ADD CONSTRAINT';
ok $at[0] >= 0 && $at[0] < $at[1] && $at[1] < $at[2], 'h: foreign key dropped, key changed, foreign key added' or diag $sql;
is $raw->selectrow_array("SELECT COUNT(*) FROM q"), 2, 'h: the rows of q are still there';
is $raw->selectrow_array("SELECT COUNT(*) FROM p"), 2, 'h: and those of p';
ok !eval { $raw->do("INSERT INTO q VALUES (9, 99)"); 1 }, 'h: the foreign key works (a child without a parent is refused)';

is_deeply primary_cols('n'), ['id'], 'i: the new AUTO_INCREMENT column is the key';
is_deeply $raw->selectcol_arrayref("SELECT id FROM n ORDER BY id"), [1, 2], 'i: the rows have their ids';
like $sql, qr/ALTER TABLE `n` ADD COLUMN `id` \S+ NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY \(`id`\);/, 'i: one ALTER TABLE for column and key';

my ($ai) = $raw->selectrow_array("SELECT extra FROM information_schema.columns WHERE table_schema = ? AND table_name = 'f' AND column_name = 'id'", undef, $DB);
like $ai // '', qr/auto_increment/i, 'f: the column is AUTO_INCREMENT';
$raw->do("INSERT INTO f (v) VALUES (3)");
is $raw->selectrow_array("SELECT COUNT(*) FROM f"), 3, 'f: an INSERT without an id gets one';
is $raw->selectrow_array("SELECT COUNT(*) FROM $_"), {a=>2,b=>2,c=>2,e=>1,g=>2,h=>2,i=>2,n=>2}->{$_}, "d: the rows of $_ are still there" for qw(a b c e g h i n);
converged($s2, 'd');

# --- j. a foreign key over a key the schema does not have ---
my $s3 = make_schema(
  P => [ [ a => $int, b => $int ], ['b'] ],
  Q => [ [ id => $int, pa => $int ], ['id'], undef, [ [ parent => P => { 'foreign.a' => 'self.pa' } ] ] ],
);
my ($d3, $e3) = upgrade_to($s3);
ok $e3, 'j: a schema whose foreign key points at a column with no key is not applied' or note 'no error';
note "error: $e3";
is_deeply primary_cols('p'), ['b'], 'j: nothing was changed (the key of p)';
is $raw->selectrow_array("SELECT COUNT(*) FROM information_schema.referential_constraints WHERE constraint_schema = ? AND table_name = 'q'", undef, $DB), 1,
  'j: nothing was changed (the foreign key of q)';
$s3->storage->disconnect;

$s1->storage->disconnect;
$s2->storage->disconnect;
drop_database();
$raw->disconnect;
undef $raw;
done_testing;
