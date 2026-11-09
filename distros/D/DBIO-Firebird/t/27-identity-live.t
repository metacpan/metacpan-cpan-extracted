use strict;
use warnings;
use Test::More;

# LIVE: an is_auto_increment column is an IDENTITY column (karr k46).
# Deploy->install, then `create` without a key returns an object with id set,
# ids are 1,2,3 and never handed out twice; the diff afterwards is empty.
# No hand-built generator or trigger.
#
# Then the path through Deploy->upgrade, where the target is the introspected
# temp database (the model carries is_auto_increment from rdb$identity_type):
#
#   * a NEW table with an identity key made by upgrade produces its own key,
#     and a second upgrade is empty;
#   * a NEW identity column added to an existing (empty) table by upgrade
#     takes the clause;
#   * an existing column that gains IDENTITY is refused before the first
#     statement, and nothing was changed on the server;
#   * a numeric(9,0) key is accepted as IDENTITY (measured: the server takes
#     any exact number type with scale 0).
#
# Skipped unless a DSN is provided:
#
#   DBIO_TEST_FIREBIRD_DSN / _USER / _PASS
#
# WARNING: creates and drops the tables "k46_item", "k46_num", "k46_new",
# "k46_grow" and "k46_plain".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live identity test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Deploy;
use DBIO::Firebird::Introspect;

{
  package K46Live::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('Firebird');

  package K46Live::Schema::Result::Item;
  use DBIO 'Core';
  __PACKAGE__->table('k46_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package K46Live::Schema::Result::Num;
  use DBIO 'Core';
  __PACKAGE__->table('k46_num');
  __PACKAGE__->add_columns(
    id   => { data_type => 'numeric', size => [9, 0], is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package main;
  K46Live::Schema->register_class(Item => 'K46Live::Schema::Result::Item');
  K46Live::Schema->register_class(Num  => 'K46Live::Schema::Result::Num');

  # The upgrade phases: A is what is on the server first, B what the schema
  # wants afterwards.
  for my $phase (qw(A B)) {
    my $sc = "K46Live::Phase$phase";
    no strict 'refs';
    @{"${sc}::ISA"} = ('DBIO::Schema');
    $sc->load_components('Firebird');
    my $mk = sub {
      my ($name, $table, $cols, $pk) = @_;
      my $rc = "${sc}::Result::$name";
      @{"${rc}::ISA"} = ('DBIO::Core');
      $rc->table($table);
      $rc->add_columns(@$cols);
      $rc->set_primary_key(@$pk) if $pk;
      $sc->register_class($name => $rc);
    };
    my $x = [ x => { data_type => 'integer', is_nullable => 1 } ];
    my $id = [ id => { data_type => 'integer', is_auto_increment => ($phase eq 'B' ? 1 : 0) } ];
    $mk->(Grow => 'k46_grow', [ @$x, ($phase eq 'B' ? (gid => { data_type => 'integer', is_auto_increment => 1 }) : ()) ]);
    $mk->(Plain => 'k46_plain', [ @$id, @$x ], ['id']);
    $mk->(New => 'k46_new', [ id => { data_type => 'integer', is_auto_increment => 1 }, v => { data_type => 'varchar', size => 5, is_nullable => 1 } ], ['id'])
      if $phase eq 'B';
  }
}

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my $schema = K46Live::Schema->connect($dsn, $user, $pass, {
  quote_names => 1, on_connect_call => 'use_softcommit',
});
my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach Firebird server: $@";

my ($ver) = $dbh->selectrow_array(
  q{SELECT rdb$get_context('SYSTEM','ENGINE_VERSION') FROM rdb$database});
plan skip_all => "IDENTITY needs Firebird 3 (server is $ver)" if ($ver =~ /^(\d+)/)[0] < 3;

sub cleanup { eval { $dbh->do(qq{DROP TABLE "$_"}) } for qw(k46_item k46_num k46_new k46_grow k46_plain) }
cleanup();

my $deploy = DBIO::Firebird::Deploy->new(schema => $schema);
ok eval { $deploy->install; 1 }, 'install accepts an auto-increment column' or diag $@;

my $diff = eval { $deploy->diff };
ok $diff && !$diff->has_changes, 'the diff afterwards is empty'
  or diag $diff ? $diff->as_sql : "diff failed: $@";

my $rs = $schema->resultset('Item');
my @rows = eval { map { $rs->create({ name => "n$_" }) } 1 .. 3 };
is $@, '', 'three creates without a key' or diag $@;
is_deeply [ map { $_->id } @rows ], [1, 2, 3], 'ids are 1, 2, 3';
is_deeply [ map { $_->id } $rs->search({}, { order_by => 'id' })->all ], [1, 2, 3],
  'and the table holds the same ids (no id handed out twice)';

# --- a numeric(9,0) identity key ---------------------------------------------
ok eval { $deploy->diff->has_changes; 1 }, 'diff after the install runs';
{
  my $num = $schema->resultset('Num');
  my @n = eval { map { $num->create({ name => "m$_" }) } 1 .. 2 };
  is $@, '', 'numeric(9,0) key: two creates without a key' or diag $@;
  is_deeply [ map { $_->id } @n ], [1, 2], '... ids 1 and 2';
}
{
  my $col = _column($dbh, 'k46_num', 'id');
  ok $col && $col->{is_auto_increment}, 'Introspect reports the numeric key as is_auto_increment';
  is $col && $col->{data_type}, 'decimal', '... as decimal (the DDL spells numeric as DECIMAL)';
}
{
  my $col = _column($dbh, 'k46_item', 'id');
  ok $col && $col->{is_auto_increment}, 'Introspect reports the integer key as is_auto_increment';
  ok !_column($dbh, 'k46_item', 'name')->{is_auto_increment}, '... and not the plain column';
}

# --- Deploy->upgrade ----------------------------------------------------------
cleanup();
my $a = K46Live::PhaseA->connect($dsn, $user, $pass, { quote_names => 1, on_connect_call => 'use_softcommit' });
ok eval { DBIO::Firebird::Deploy->new(schema => $a)->install; 1 }, 'phase A: install' or diag $@;
$a->storage->dbh->do(q{INSERT INTO "k46_plain" ("id", "x") VALUES (1, 1)});

my $b = K46Live::PhaseB->connect($dsn, $user, $pass, { quote_names => 1, on_connect_call => 'use_softcommit' });
my $up = DBIO::Firebird::Deploy->new(schema => $b);

# the plain column "id" of k46_plain would gain IDENTITY: refused, nothing run
my $refused = eval { $up->diff->as_sql; 1 };
ok !$refused, 'upgrade: a column that gains IDENTITY is refused';
like $@, qr/"k46_plain"\."id".*IDENTITY/is, '... naming table and column';
ok !eval { $up->upgrade; 1 }, 'upgrade dies';
my ($has_new) = $dbh->selectrow_array(q{SELECT COUNT(*) FROM rdb$relations WHERE rdb$relation_name = 'k46_new'});
is $has_new, 0, '... before its first statement: the new table was not created';

# take the refused column out of the way; the rest is upgrade's to do. Every
# other handle lets go of the table first: DROP TABLE waits for them.
$a->storage->disconnect;
$b->storage->disconnect;
$dbh->do(q{DROP TABLE "k46_plain"});
$dbh->do(q{CREATE TABLE "k46_plain" ("id" INTEGER GENERATED BY DEFAULT AS IDENTITY NOT NULL, "x" INTEGER, PRIMARY KEY ("id"))});
ok eval { $up->upgrade; 1 }, 'upgrade: new identity table and new identity column on an empty table' or diag $@;
my $d2 = eval { $up->diff };
ok $d2 && !$d2->has_changes, 'a second upgrade has nothing to do' or diag $d2 ? $d2->as_sql : $@;

ok _column($dbh, 'k46_new', 'id')->{is_auto_increment}, 'k46_new.id is an identity column';
ok _column($dbh, 'k46_grow', 'gid')->{is_auto_increment}, 'k46_grow.gid (added by upgrade) is an identity column';
{
  my $new = $b->resultset('New');
  my @r = eval { map { $new->create({ v => "v$_" }) } 1 .. 3 };
  is $@, '', 'create without a key in the table upgrade made' or diag $@;
  is_deeply [ map { $_->id } @r ], [1, 2, 3], '... ids 1, 2, 3';
}
$dbh->do(q{INSERT INTO "k46_grow" ("x") VALUES (7)});
is(($dbh->selectrow_array(q{SELECT "gid" FROM "k46_grow"}))[0], 1, 'the added identity column hands out its value');

sub _column {
  my ($dbh, $table, $name) = @_;
  my ($c) = grep { $_->{column_name} eq $name }
    @{ DBIO::Firebird::Introspect->new(dbh => $dbh)->model->{columns}{$table} };
  return $c;
}

# DROP TABLE waits for every other handle on the table: they all go first.
$_->storage->disconnect for $b, $a;
cleanup();
$schema->storage->disconnect;
done_testing;
