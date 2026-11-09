use strict;
use warnings;
use Test::More;
use DBIO::Optional::Dependencies ();

# LIVE (karr k25): foreign keys and unique constraints end to end.
#
#  * install writes the keys after all tables (also a cycle of two), the
#    multi-column unique constraint under its name; the server reads them back
#    and the diff afterwards is empty;
#  * the server enforces them: a child without a parent, a second row with the
#    same unique pair are refused; ON DELETE CASCADE deletes the child;
#  * upgrade gives a table that exists without a constraint the constraint, and
#    drops a key the schema no longer has;
#  * a unique constraint that changes together with the key that references
#    it: the key is dropped first (the server would take it along with the
#    constraint, and a second drop fails with -623), added back last.
# Creates and drops only the tables "zz_ix_k25_*".

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');
my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run this test' unless $dsn;

use DBIO::Core;
use DBIO::Schema;
use DBIO::Informix::Deploy;
use DBIO::Informix::Introspect;

my $seq = 0;
# [ Name, table, columns, pk, extra-callback ]
sub build_schema {
  my (@sources) = @_;
  my $sc = 'K25Con::S' . ++$seq;
  no strict 'refs';
  @{"${sc}::ISA"} = ('DBIO::Schema');
  $sc->storage_type('DBIO::Informix::Storage');
  my (@classes, @later);
  for my $s (@sources) {
    my ($name, $table, $cols, $pk, $extra) = @$s;
    my $rc = "${sc}::Result::$name";
    @{"${rc}::ISA"} = ('DBIO::Core');
    $INC{ ($rc =~ s{::}{/}gr) . '.pm' } = 1;
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key(@$pk);
    push @later, sub { $extra->($rc, $sc) } if $extra;
    push @classes, [ $name => $rc ];
  }
  $_->() for @later;
  $sc->register_class(@$_) for @classes;
  return $sc->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });
}
sub ints { map { $_ => { data_type => 'integer' } } @_ }
sub cls { my ($sc, $n) = @_; "${sc}::Result::$n" }

my @tables = qw(zz_ix_k25_child zz_ix_k25_parent zz_ix_k25_a zz_ix_k25_b zz_ix_k25_late);
my $dbh = build_schema([ T => 'zz_ix_k25_parent', [ints('id')], ['id'] ])->storage->dbh;
sub cleanup { eval { $dbh->do("DROP TABLE $_") } for @tables }
cleanup();
END { cleanup() if $dbh }

sub model { DBIO::Informix::Introspect->new(dbh => $dbh)->model }
sub ours  { my ($op) = @_; ($op->can('table_name') ? $op->table_name : '') =~ /\Azz_ix_k25_/ }
sub open_ops { my ($schema) = @_; [ grep { ours($_) } @{ DBIO::Informix::Deploy->new(schema => $schema)->diff->operations } ] }
sub fk_count { scalar @{ model()->{foreign_keys}{$_[0]} // [] } }
sub uniques { [ map { join ',', @{ $_->{columns} } } @{ model()->{unique_constraints}{$_[0]} // [] } ] }
sub refused { my ($sql, @b) = @_; eval { $dbh->do($sql, undef, @b); 1 } ? 0 : 1 }

# --- install: keys, cycle, multi-column unique -------------------------------
sub full_schema {
  build_schema(
    [ Parent => 'zz_ix_k25_parent', [ ints(qw/id a b/) ], ['id'], sub {
        $_[0]->add_unique_constraint(zz_ix_k25_parent_ab => [qw/a b/]);
        $_[0]->has_many(kids => cls($_[1], 'Child'), 'pid');
      } ],
    [ Child => 'zz_ix_k25_child', [ ints(qw/id pid/) ], ['id'], sub {
        $_[0]->belongs_to(parent => cls($_[1], 'Parent'), 'pid');
      } ],
    [ A => 'zz_ix_k25_a', [ ints(qw/id b_id/) ], ['id'], sub { $_[0]->belongs_to(b => cls($_[1], 'B'), 'b_id') } ],
    [ B => 'zz_ix_k25_b', [ ints(qw/id a_id/) ], ['id'], sub { $_[0]->belongs_to(a => cls($_[1], 'A'), 'a_id') } ],
  );
}
my $schema = full_schema();
ok eval { DBIO::Informix::Deploy->new(schema => $schema)->install; 1 }, 'install writes tables, keys, a cycle and a unique constraint' or diag $@;
is fk_count('zz_ix_k25_child'), 1, 'the server holds the key of the child';
is fk_count('zz_ix_k25_a') + fk_count('zz_ix_k25_b'), 2, '... and both keys of the cycle';
is_deeply uniques('zz_ix_k25_parent'), ['a,b'], '... and the unique pair, read back as one constraint';
{
  my $ops = open_ops(full_schema());
  is scalar @$ops, 0, 'the diff after the install has nothing to say' or diag join "\n", map { $_->as_sql } @$ops;
}

# --- the server enforces them ---------------------------------------------------
$dbh->do('INSERT INTO zz_ix_k25_parent (id, a, b) VALUES (1, 1, 1)');
ok refused('INSERT INTO zz_ix_k25_child (id, pid) VALUES (1, 99)'), 'a child without a parent is refused';
ok !refused('INSERT INTO zz_ix_k25_child (id, pid) VALUES (1, 1)'), 'a child with a parent is accepted';
ok refused('INSERT INTO zz_ix_k25_parent (id, a, b) VALUES (2, 1, 1)'), 'a second row with the same unique pair is refused';
ok !refused('INSERT INTO zz_ix_k25_parent (id, a, b) VALUES (3, 1, 2)'), '... one differing in one column is accepted';
# the has_many (cascade_delete by default) makes the key ON DELETE CASCADE
ok !refused('DELETE FROM zz_ix_k25_parent WHERE id = 1'), 'ON DELETE CASCADE: the parent is deleted';
is $dbh->selectrow_array('SELECT COUNT(*) FROM zz_ix_k25_child'), 0, '... and its child with it';

# --- upgrade of a table that lacks the constraint -------------------------------
{
  $dbh->do('CREATE TABLE zz_ix_k25_late (id INTEGER NOT NULL, code INTEGER, PRIMARY KEY (id))');
  my $late = build_schema([ Late => 'zz_ix_k25_late', [ ints(qw/id code/) ], ['id'], sub {
    $_[0]->add_unique_constraint(zz_ix_k25_late_code => ['code']) }]);
  ok scalar @{ open_ops($late) }, 'a table lacking its unique constraint: the diff reports it';
  ok eval { DBIO::Informix::Deploy->new(schema => $late)->upgrade(allow_destructive => 1); 1 }, 'upgrade adds it' or diag $@;
  is_deeply uniques('zz_ix_k25_late'), ['code'], '... the server holds it';
  is scalar @{ open_ops($late) }, 0, '... and the diff is empty afterwards';
  my $plain = build_schema([ Late => 'zz_ix_k25_late', [ ints(qw/id code/) ], ['id'] ]);
  ok eval { DBIO::Informix::Deploy->new(schema => $plain)->upgrade(allow_destructive => 1); 1 }, 'upgrade drops a constraint the schema no longer has' or diag $@;
  is_deeply uniques('zz_ix_k25_late'), [], '... gone on the server';
}

# --- a key the schema no longer has -----------------------------------------------
{
  my $nokey = build_schema(
    [ Parent => 'zz_ix_k25_parent', [ ints(qw/id a b/) ], ['id'], sub { $_[0]->add_unique_constraint(zz_ix_k25_parent_ab => [qw/a b/]) } ],
    [ Child => 'zz_ix_k25_child', [ ints(qw/id pid/) ], ['id'] ],
    [ A => 'zz_ix_k25_a', [ ints(qw/id b_id/) ], ['id'] ],
    [ B => 'zz_ix_k25_b', [ ints(qw/id a_id/) ], ['id'] ],
  );
  ok eval { DBIO::Informix::Deploy->new(schema => $nokey)->upgrade(allow_destructive => 1); 1 }, 'upgrade drops the keys the schema lacks' or diag $@;
  is fk_count('zz_ix_k25_child') + fk_count('zz_ix_k25_a') + fk_count('zz_ix_k25_b'), 0, '... none left on the server';
}

# --- the unique constraint a key references changes together with the key --------
# (the server would drop the key along with the constraint; the diff already
# drops it, and must not drop it a second time: -623)
{
  my $mk = sub {
    my ($ucol, $fcol) = @_;
    build_schema(
      [ Parent => 'zz_ix_k25_parent', [ ints(qw/id a b/) ], ['id'], sub { $_[0]->add_unique_constraint("zz_ix_k25_parent_u" => [$ucol]) } ],
      [ Child => 'zz_ix_k25_child', [ ints(qw/id pa pb/) ], ['id'], sub {
          $_[0]->belongs_to(parent => cls($_[1], 'Parent'), { "foreign.$ucol" => "self.$fcol" }) } ],
      [ A => 'zz_ix_k25_a', [ ints(qw/id b_id/) ], ['id'] ],
      [ B => 'zz_ix_k25_b', [ ints(qw/id a_id/) ], ['id'] ],
    );
  };
  $dbh->do($_) for 'DROP TABLE zz_ix_k25_child', 'DROP TABLE zz_ix_k25_parent';
  my $one = $mk->('a', 'pa');
  ok eval { DBIO::Informix::Deploy->new(schema => $one)->upgrade; 1 }, 'a key over a unique constraint on a: upgraded in' or diag $@;
  is fk_count('zz_ix_k25_child'), 1, '... the key is there';
  my $two = $mk->('b', 'pb');
  ok eval { DBIO::Informix::Deploy->new(schema => $two)->upgrade(allow_destructive => 1); 1 }, 'constraint and key both move to b: upgrade runs' or diag $@;
  is_deeply uniques('zz_ix_k25_parent'), ['b'], '... the constraint is the new one';
  is fk_count('zz_ix_k25_child'), 1, '... and so is the key';
  is scalar @{ open_ops($two) }, 0, '... the diff is empty afterwards';
}

# --- a changed unique constraint is a replacement, a vanishing one is a removal ---
{
  my $mk = sub {
    my ($cols) = @_;
    build_schema([ Late => 'zz_ix_k25_late', [ ints(qw/id code other/) ], ['id'], sub {
      $_[0]->add_unique_constraint(zz_ix_k25_late_u => $cols) }]);
  };
  cleanup();
  $dbh->do($_) for 'CREATE TABLE zz_ix_k25_late (id INTEGER NOT NULL, code INTEGER, other INTEGER, PRIMARY KEY (id))';
  ok eval { DBIO::Informix::Deploy->new(schema => $mk->(['code']))->upgrade; 1 }, 'a new unique constraint needs no release' or diag $@;
  my $wide = $mk->([qw/code other/]);
  ok eval { DBIO::Informix::Deploy->new(schema => $wide)->upgrade; 1 }, 'a changed unique constraint runs without allow_destructive' or diag $@;
  is_deeply uniques('zz_ix_k25_late'), ['code,other'], '... the server holds the new one';
  my $plain = build_schema([ Late => 'zz_ix_k25_late', [ ints(qw/id code other/) ], ['id'] ]);
  ok !eval { DBIO::Informix::Deploy->new(schema => $plain)->upgrade; 1 }, 'a vanishing unique constraint needs allow_destructive';
  is_deeply uniques('zz_ix_k25_late'), ['code,other'], '... and is still there';
}

done_testing;
