use strict;
use warnings;
use Test::More;

# LIVE: foreign keys and unique constraints (karr k34).
#
# install_ddl wrote columns and the primary key only, so a deployed schema had
# no referential integrity. Claims only a server can answer:
#
#  * install writes the keys after all tables (also a cycle between two), the
#    unique constraints under their declared names, the server reads them back
#    with the rules the relationships declared, and the diff afterwards is empty;
#  * the server enforces them: a child row without a parent, a second row with
#    the same unique value are refused; ON DELETE CASCADE deletes the child;
#  * Deploy->upgrade creates a NEW table together with its key and unique
#    constraint (the target model is the temp database, so the constraints are in
#    it), and the second upgrade has nothing to do;
#  * a table that exists and lacks a constraint the schema declares -- a
#    database installed before k34 -- gets it by Deploy->upgrade (karr k62:
#    the diff used to refuse), together with a new table beside it, and the
#    diff is empty afterwards; a key the schema dropped is dropped.
#
# Skipped unless a DSN is provided (as t/19):
#
#   DBIO_TEST_FIREBIRD_DSN / _USER / _PASS
#
# WARNING: creates and drops the tables "k34_parent", "k34_child", "k34_a",
# "k34_b", "k34_late", "k34_art", "k34_cd", "k34_keep".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live constraint test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Core;
use DBIO::Schema;
use DBIO::Firebird::Deploy;
use DBIO::Firebird::Introspect;

# A schema class from a list of [ Name, table, columns, pk, extra-callback ].
my $seq = 0;
sub build_schema {
  my (@sources) = @_;
  my $sc = 'K34Live::S' . ++$seq;
  no strict 'refs';
  @{"${sc}::ISA"} = ('DBIO::Schema');
  $sc->load_components('Firebird');
  my (@classes, @later);
  for my $s (@sources) {
    my ($name, $table, $cols, $pk, $extra) = @$s;
    my $rc = "${sc}::Result::$name";
    @{"${rc}::ISA"} = ('DBIO::Core');
    $INC{ ($rc =~ s{::}{/}gr) . '.pm' } = 1;
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key(@$pk);
    push @later, sub { $extra->($rc, sub { "${sc}::Result::$_[0]" }) } if $extra;
    push @classes, [ $name => $rc ];
  }
  $_->() for @later;
  $sc->register_class(@$_) for @classes;
  return $sc;
}
sub ints { map { $_ => { data_type => 'integer' } } @_ }
sub nint { map { $_ => { data_type => 'integer', is_nullable => 1 } } @_ }

my $parent = [ Parent => 'k34_parent', [ ints('id') ], ['id'] ];
my $child  = [ Child  => 'k34_child',  [ ints('id'), nint('pid'), ints('code') ], ['id'], sub {
  my ($rc, $cls) = @_;
  $rc->belongs_to(parent => $cls->('Parent'), 'pid', { on_delete => 'CASCADE' });
  $rc->add_unique_constraint(k34_child_code => ['code']);
} ];

my %connect = (quote_names => 1, on_connect_call => 'use_softcommit');
my $full = build_schema($parent, $child);
my $schema = $full->connect($dsn, $user, $pass, {%connect});

eval { $schema->storage->dbh->do('SELECT 1 FROM rdb$database'); 1 }
  or plan skip_all => "Cannot reach Firebird server: $@";

my $other = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
}) or plan skip_all => 'Cannot connect: ' . DBI->errstr;
$other->func(-lock_resolution => { wait => 10 }, 'ib_set_tx_param');

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my @tables = qw(k34_child k34_late k34_a k34_b k34_cd k34_art k34_keep k34_parent);
sub cleanup {
  eval { $_->storage->disconnect } for grep { $_ } ($schema, @_);
  my $fks = eval { $other->selectall_arrayref(
    q{SELECT TRIM(rdb$relation_name), TRIM(rdb$constraint_name) FROM rdb$relation_constraints }
  . q{WHERE rdb$constraint_type = 'FOREIGN KEY' AND TRIM(rdb$relation_name) STARTING WITH 'k34_'}) } || [];
  eval { $other->do(sprintf 'ALTER TABLE "%s" DROP CONSTRAINT "%s"', @$_) } for @$fks;
  eval { $other->do(qq{DROP TABLE "$_"}) } for @tables;
}
cleanup();

sub count_of { my ($n) = @_; ($other->selectrow_array(q{SELECT COUNT(*) FROM rdb$relations WHERE TRIM(rdb$relation_name) = ?}, undef, $n))[0] }
sub model_of { DBIO::Firebird::Introspect->new(dbh => $other)->model }

# === install ======================================================================
my $deploy = DBIO::Firebird::Deploy->new(schema => $schema);
ok eval { $deploy->install; 1 }, 'install: the server accepts the tables, the unique constraint and the key' or diag $@;

{
  my $m = model_of();
  my ($fk) = @{ $m->{foreign_keys}{k34_child} // [] };
  ok $fk, 'the server holds a foreign key on k34_child' or diag explain $m->{foreign_keys};
  is_deeply [ $fk->{constraint_name}, $fk->{from_columns}, $fk->{to_table}, $fk->{to_columns} ],
    [ 'k34_child_pid_k34_parent_fk', ['pid'], 'k34_parent', ['id'] ], '... named <table>_<columns>_<target>_fk, over the right columns';
  is $fk->{on_delete}, 'CASCADE', '... with the ON DELETE CASCADE the relationship declared';
  is $fk->{on_update}, 'RESTRICT', '... and the default for the rule it did not';
  is_deeply $m->{unique_constraints}{k34_child}, [ [ 'k34_child_code', ['code'] ] ],
    'the unique constraint is there under the declared name';
}

my $d = eval { $deploy->diff };
ok $d && !$d->has_changes, 'the diff after the install is empty' or diag $d ? $d->as_sql : $@;

# === enforcement ====================================================================
my $p = $schema->resultset('Parent');
my $c = $schema->resultset('Child');
ok eval { $p->create({ id => 1 }); $p->create({ id => 2 }); $c->create({ id => 1, pid => 1, code => 10 }); 1 },
  'rows with a parent are accepted' or diag $@;

ok !eval { $c->create({ id => 2, pid => 99, code => 11 }); 1 }, 'a child whose parent does not exist is refused by the server';
like "$@", qr/violation of FOREIGN KEY constraint/i, '... as a foreign key violation';
ok !eval { $c->create({ id => 3, pid => 2, code => 10 }); 1 }, 'a second row with the same unique value is refused';
like "$@", qr/(?:UNIQUE|PRIMARY or UNIQUE) KEY|unique/i, '... as a unique violation';
is $c->count, 1, '... and nothing of the refused rows is there';

ok eval { $p->find(1)->delete; 1 }, 'deleting the parent works' or diag $@;
is $c->count, 0, 'ON DELETE CASCADE removed its child';

# === a cycle ========================================================================
cleanup();
{
  my $cyc = build_schema(
    [ A => 'k34_a', [ ints('id'), nint('b_id') ], ['id'], sub { $_[0]->belongs_to(b => $_[1]->('B'), 'b_id') } ],
    [ B => 'k34_b', [ ints('id'), nint('a_id') ], ['id'], sub { $_[0]->belongs_to(a => $_[1]->('A'), 'a_id') } ],
  )->connect($dsn, $user, $pass, {%connect});
  ok eval { DBIO::Firebird::Deploy->new(schema => $cyc)->install; 1 }, 'a cycle between two tables installs' or diag $@;
  my $m = model_of();
  is_deeply [ sort map { $_->{constraint_name} } map { @{ $m->{foreign_keys}{$_} // [] } } qw(k34_a k34_b) ],
    [ 'k34_a_b_id_k34_b_fk', 'k34_b_a_id_k34_a_fk' ], '... and both keys are there';
  my $dd = eval { DBIO::Firebird::Deploy->new(schema => $cyc)->diff };
  ok $dd && !$dd->has_changes, '... and the diff is empty' or diag $dd ? $dd->as_sql : $@;
  cleanup($cyc);
}

# === the actions come from the other side ===========================================
# DBIO's cascade delete runs AFTER the requested delete, so the parent goes
# first: without ON DELETE CASCADE on the key the server refuses it.
cleanup();
{
  my $art = [ Art => 'k34_art', [ ints('id') ], ['id'], sub {
    my ($rc, $cls) = @_;
    $rc->has_many(cds => $cls->('Cd'), 'art_id');
  } ];
  my $cd = [ Cd => 'k34_cd', [ ints('id', 'art_id') ], ['id'], sub {
    my ($rc, $cls) = @_;
    $rc->belongs_to(art => $cls->('Art'), 'art_id');
  } ];
  my $dv = build_schema($art, $cd)->connect($dsn, $user, $pass, {%connect});
  ok eval { DBIO::Firebird::Deploy->new(schema => $dv)->install; 1 }, 'a belongs_to / has_many pair installs' or diag $@;
  my ($fk) = @{ model_of()->{foreign_keys}{k34_cd} // [] };
  is_deeply [ $fk && $fk->{on_delete}, $fk && $fk->{on_update} ], [ 'CASCADE', 'CASCADE' ],
    'the key is ON DELETE CASCADE ON UPDATE CASCADE although the belongs_to declares nothing';
  $dv->resultset('Art')->create({ id => 1 });
  $dv->resultset('Cd')->create({ id => $_, art_id => 1 }) for 1, 2;
  ok eval { $dv->resultset('Art')->find(1)->delete; 1 }, '$artist->delete with CDs runs through (the ORM deletes the parent first)' or diag $@;
  is $dv->resultset('Cd')->count, 0, '... and the CDs are gone';
  $dv->resultset('Art')->create({ id => 2 });
  $dv->resultset('Cd')->create({ id => 3, art_id => 2 });
  ok eval { $dv->resultset('Art')->find(2)->update({ id => 9 }); 1 }, 'ON UPDATE CASCADE: the parent key changes' or diag $@;
  is eval { $dv->resultset('Cd')->find(3)->art_id }, 9, '... and the child follows';
  cleanup($dv);
}

# === DROP TABLE in the order of the keys ===============================================
{
  my $keep = [ Keep => 'k34_keep', [ ints('id') ], ['id'] ];
  my $pair = build_schema($parent, $child, $keep)->connect($dsn, $user, $pass, {%connect});
  ok eval { DBIO::Firebird::Deploy->new(schema => $pair)->install; 1 }, 'parent, child and a third table installed' or diag $@;
  $pair->storage->disconnect;

  my $only = build_schema($keep)->connect($dsn, $user, $pass, {%connect});
  my $dd = DBIO::Firebird::Deploy->new(schema => $only);
  like eval { $dd->diff->as_sql } // '', qr/DROP TABLE "k34_child";.*DROP TABLE "k34_parent";/s,
    'the diff drops the child before the parent';
  ok eval { $dd->upgrade(allow_destructive => 1); 1 }, 'upgrade removes parent and child together' or diag $@;
  is count_of($_), 0, "... $_ is gone" for qw(k34_child k34_parent);
  is count_of('k34_keep'), 1, '... and the other table stays';
  $only->storage->disconnect;
  cleanup();

  # a cycle between the dropped tables
  my $cyc = build_schema(
    [ A => 'k34_a', [ ints('id'), nint('b_id') ], ['id'], sub { $_[0]->belongs_to(b => $_[1]->('B'), 'b_id') } ],
    [ B => 'k34_b', [ ints('id'), nint('a_id') ], ['id'], sub { $_[0]->belongs_to(a => $_[1]->('A'), 'a_id') } ],
    $keep,
  )->connect($dsn, $user, $pass, {%connect});
  ok eval { DBIO::Firebird::Deploy->new(schema => $cyc)->install; 1 }, 'a cycle (and a third table) installed' or diag $@;
  $cyc->storage->disconnect;
  my $only2 = build_schema($keep)->connect($dsn, $user, $pass, {%connect});
  my $d2s = DBIO::Firebird::Deploy->new(schema => $only2);
  like eval { $d2s->diff->as_sql } // '', qr/DROP CONSTRAINT.*DROP CONSTRAINT.*DROP TABLE/s, 'the diff drops the keys of the cycle first';
  ok eval { $d2s->upgrade(allow_destructive => 1); 1 }, 'upgrade removes both tables of the cycle' or diag $@;
  is count_of($_), 0, "... $_ is gone" for qw(k34_a k34_b);
  $only2->storage->disconnect;
  cleanup();
}

# === two keys over one column to different tables ======================================
{
  my $sc = build_schema(
    [ P1 => 'k34_a', [ ints('id') ], ['id'] ],
    [ P2 => 'k34_b', [ ints('id') ], ['id'] ],
    [ Kid => 'k34_child', [ ints('id'), nint('pid') ], ['id'], sub {
      $_[0]->belongs_to(one => $_[1]->('P1'), { 'foreign.id' => 'self.pid' });
      $_[0]->belongs_to(two => $_[1]->('P2'), { 'foreign.id' => 'self.pid' });
    } ],
  )->connect($dsn, $user, $pass, {%connect});
  ok eval { DBIO::Firebird::Deploy->new(schema => $sc)->install; 1 }, 'two keys over one column to two tables install (distinct names)' or diag $@;
  is_deeply [ sort map { $_->{constraint_name} } @{ model_of()->{foreign_keys}{k34_child} // [] } ],
    [ 'k34_child_pid_k34_a_fk', 'k34_child_pid_k34_b_fk' ], '... both are there';
  cleanup($sc);
}

# === upgrade creates a new table with its constraints ==============================
my $a = build_schema($parent)->connect($dsn, $user, $pass, {%connect});
ok eval { DBIO::Firebird::Deploy->new(schema => $a)->install; 1 }, 'phase A: only the parent' or diag $@;
$a->storage->disconnect;

my $late = [ Late => 'k34_late', [ ints('id'), nint('pid'), ints('code') ], ['id'], sub {
  my ($rc, $cls) = @_;
  $rc->belongs_to(parent => $cls->('Parent'), 'pid');
  $rc->add_unique_constraint(k34_late_code => ['code']);
} ];
my $b = build_schema($parent, $late)->connect($dsn, $user, $pass, {%connect});
my $up = DBIO::Firebird::Deploy->new(schema => $b);

my $sql = eval { $up->diff->as_sql } // '';
like $sql, qr/CREATE TABLE "k34_late".*ALTER TABLE "k34_late" ADD CONSTRAINT "k34_late_code" UNIQUE.*ALTER TABLE "k34_late" ADD CONSTRAINT "k34_late_pid_k34_parent_fk" FOREIGN KEY/s,
  'the diff creates the table, then its unique constraint, then its key' or diag $@;
ok eval { $up->upgrade; 1 }, 'upgrade: the server accepts every statement' or diag $@;
{
  my $m = model_of();
  is_deeply [ map { $_->{constraint_name} } @{ $m->{foreign_keys}{k34_late} // [] } ], ['k34_late_pid_k34_parent_fk'], 'the new table has its foreign key';
  is_deeply $m->{unique_constraints}{k34_late}, [ [ 'k34_late_code', ['code'] ] ], '... and its unique constraint';
}
my $d2 = eval { $up->diff };
ok $d2 && !$d2->has_changes, 'a second upgrade has nothing to do' or diag $d2 ? $d2->as_sql : $@;
$b->resultset('Parent')->create({ id => 5 });
ok !eval { $b->resultset('Late')->create({ id => 1, pid => 77, code => 1 }); 1 }, 'the key the upgrade made is enforced';

# === a table that exists and lacks a constraint: written (karr k62) =================
$b->storage->disconnect;
$other->do('ALTER TABLE "k34_late" DROP CONSTRAINT "k34_late_pid_k34_parent_fk"');
$other->do('ALTER TABLE "k34_late" DROP CONSTRAINT "k34_late_code"');

my $c3 = build_schema($parent, $late, [ Fresh => 'k34_a', [ ints('id') ], ['id'] ])->connect($dsn, $user, $pass, {%connect});
my $ref = DBIO::Firebird::Deploy->new(schema => $c3);
my $rd = eval { $ref->diff };
ok $rd && $rd->has_changes, 'a database without the constraints of its schema: the difference is reported';
my $sql3 = eval { $rd->as_sql } // '';
like $sql3, qr/CREATE TABLE "k34_a".*ALTER TABLE "k34_late" ADD CONSTRAINT "k34_late_code" UNIQUE \("code"\);.*ADD CONSTRAINT "k34_late_pid_k34_parent_fk" FOREIGN KEY \("pid"\) REFERENCES "k34_parent" \("id"\);/s,
  'as_sql writes the new table, then the unique constraint, then the key (no refusal)' or diag $@;
ok eval { $ref->upgrade; 1 }, 'upgrade: the server accepts every statement' or diag $@;
{
  my $m = model_of();
  is_deeply [ map { $_->{constraint_name} } @{ $m->{foreign_keys}{k34_late} // [] } ], ['k34_late_pid_k34_parent_fk'], 'the key is back';
  is_deeply $m->{unique_constraints}{k34_late}, [ [ 'k34_late_code', ['code'] ] ], '... and the unique constraint';
  ok $m->{tables}{k34_a}, '... and the new table is there';
}
my $fd = eval { $ref->diff };
ok $fd && !$fd->has_changes, 'the diff is empty afterwards' or diag $fd ? $fd->as_sql : $@;

# a key the schema no longer declares is dropped
$c3->storage->disconnect;
my $c4 = build_schema($parent, [ Late => 'k34_late', [ ints('id'), nint('pid'), ints('code') ], ['id'] ], [ Fresh => 'k34_a', [ ints('id') ], ['id'] ])
  ->connect($dsn, $user, $pass, {%connect});
my $dn = DBIO::Firebird::Deploy->new(schema => $c4);
ok eval { $dn->upgrade(allow_destructive => 1); 1 }, 'a schema without those constraints: upgrade drops them' or diag $@;
{
  my $m = model_of();
  is_deeply $m->{foreign_keys}{k34_late} // [], [], 'the key is gone';
  is_deeply $m->{unique_constraints}{k34_late} // [], [], '... and the unique constraint';
}
my $dd4 = eval { $dn->diff };
ok $dd4 && !$dd4->has_changes, '... and the diff is empty' or diag $dd4 ? $dd4->as_sql : $@;

cleanup($a, $b, $c3, $c4);
$other->disconnect;
done_testing;
