use strict;
use warnings;
use Test::More;

# Live deploy round trip (karr k32): the whole path a user of
# DBIO::Firebird::Deploy walks, against a real server, because every step of it
# is a statement the server has to accept AND read the way the ORM means it:
#
#   install -> ORM insert and select -> diff is empty
#           -> drift on the server -> upgrade -> diff is empty
#           -> the dropped column is back and usable through the ORM
#
# Three things only a server can say, and all three were wrong before k32:
#
#  * Firebird folds a bare identifier to upper case and does not parse a bare
#    reserved word, while the storage quotes every name it emits. A DDL that
#    writes `CREATE TABLE artist` creates ARTIST; the ORM then asks for
#    "artist" and gets `Table unknown`. `year` and `position` as bare column
#    names are a syntax error.
#  * A column's size is part of its type. `ADD "name" varchar` is a syntax
#    error, and a size difference that renders no statement is reported by
#    every later diff, forever.
#  * A column clause is <type> [DEFAULT ...] [NOT NULL], in that order.
#    `INTEGER NOT NULL DEFAULT '13'` is `Token unknown - DEFAULT`, in CREATE
#    TABLE and in ALTER TABLE ... ADD alike.
#
# The result classes are the shared ones from core (not redefined here), a
# subset loaded by name: the full DBIO::Test::Schema does not install on
# Firebird (three foreign-dialect column types), and views are kept out of this file on purpose, and so are the unique
# constraints of Artist (see below); the foreign keys and constraints have
# t/29-constraints-live.t. Artist is the lower-case table name, CD carries the reserved word
# `year` and is the scalar-ref table name (\'cd', literal SQL, so CD on the
# server), Track carries the reserved word `position`.
#
# Skipped unless a DSN is provided (as t/15, t/17):
#
#   DBIO_TEST_FIREBIRD_DSN
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS
#
# WARNING: creates and drops the tables "artist", cd, "track" and "k32_extra".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live deploy round trip'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use File::Basename ();
use DBIO::Firebird::Deploy;
use DBIO::Firebird::Introspect;

{
  package DBIO::Firebird::Test::K32Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Firebird');
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [qw/ Artist CD Track /] });
}

# karr k34: install_ddl now writes the unique constraints of the shared result
# classes. Every column of Artist is in one (artistid is the key, name, and
# charfield + rank), Track.title is, and a drifted column that a constraint uses cannot be
# dropped or repaired by an upgrade: the diff refuses constraint changes of an
# existing table. Constraints are the subject of t/29-constraints-live.t, not of
# this file, so the process-local copy of the source has none (the primary key
# stays).
# karr k34: the shared CD declares is_deferrable => 1 on its relationships and
# Firebird has no deferrable constraints, so install_ddl refuses that
# (t/69-ddl-constraints.t). This file is not about it: the process-local copy
# of the source has the attribute off.
for my $rel (DBIO::Firebird::Test::K32Schema->source('CD')->relationships) {
  DBIO::Firebird::Test::K32Schema->source('CD')->relationship_info($rel)->{attrs}{is_deferrable} = 0;
}

for my $name (qw/ Artist CD Track /) {
  my $s = DBIO::Firebird::Test::K32Schema->source($name);
  delete @{ $s->{_unique_constraints} }{ grep { $_ ne 'primary' } keys %{ $s->{_unique_constraints} } };
}

# A column that is NOT NULL and has a default. The only shared result class
# that declares one outright is ComputedColumn, and it cannot be installed
# here: its other defaulted column is `getdate()`, a function Firebird does not
# have. Artist.rank has the default (13) and no is_nullable at all -- which
# core reads as NOT NULL (ADR 0043), while this driver's DDL writes NOT NULL
# only for an explicit 0. So say the 0 explicitly, on the class's own column
# info, for this process.
DBIO::Firebird::Test::K32Schema->source('Artist')->column_info('rank')->{is_nullable} = 0;

my $schema = DBIO::Firebird::Test::K32Schema->connect($dsn, $user, $pass, {
  quote_names     => 1,
  on_connect_call => 'use_softcommit',
});

eval { $schema->storage->dbh->do('SELECT 1 FROM rdb$database'); 1 }
  or plan skip_all => "Cannot reach Firebird server: $@";

# The drift below is somebody else changing the database, so it gets a
# connection of its own -- not the schema's. It waits ten seconds for a lock and
# then fails, instead of the default, which is to wait for good.
my $other = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
}) or plan skip_all => 'Cannot connect: ' . DBI->errstr;
$other->func(-lock_resolution => { wait => 10 }, 'ib_set_tx_param');

# Every temp database a diff creates, so the end of the file can prove each one
# is gone again. The server's file system is not ours to list; a database that
# still accepts a connection is the leftover.
my @temp_ids;
{
  my $create = DBIO::Firebird::Deploy->can('_create_temp_db');
  no warnings 'redefine';
  *DBIO::Firebird::Deploy::_create_temp_db = sub {
    my $id = $create->(@_);
    push @temp_ids, $id;
    return $id;
  };
}

# Core announces non-transactional DDL once per process; it is accurate and it
# is not what this file is about.
$SIG{__WARN__} = sub {
  warn @_ unless $_[0] =~ /^non-transactional DDL on /;
};

my $deploy = DBIO::Firebird::Deploy->new(schema => $schema);

cleanup();

# --- install ------------------------------------------------------------------
ok(lives(sub { $deploy->install }), 'install: the server accepts every statement of the install DDL');

is_deeply(column(artist => 'rank'), { not_null => 1, default_value => q{'13'} },
  'install: "rank" is NOT NULL and has its default -- the clause the server only takes as DEFAULT ... NOT NULL');

# --- the ORM finds what install created ---------------------------------------
# The first statement the storage sends is INSERT INTO "artist" (...): it only
# resolves if the DDL created "artist" and not ARTIST.
my $ok = lives(sub {
  $schema->resultset('Artist')->create({ artistid => 1, name => 'Alpha' });
  $schema->resultset('CD')->create({ cdid => 1, artist => 1, title => 'First', year => '1999' });
  $schema->resultset('Track')->create({ trackid => 1, cd => 1, position => 7, title => 'Intro' });
});
ok($ok, 'ORM insert into the lower-case table, the scalar-ref table and the reserved-word columns');

SKIP: {
  skip 'no rows to read', 4 unless $ok;

  my $artist = $schema->resultset('Artist')->find(1);
  is($artist && $artist->name, 'Alpha', 'ORM select from "artist"');
  is($artist && $artist->rank, 13, '... and the column default of the install DDL applied');

  my $cd = $schema->resultset('CD')->search({ year => '1999' })->single;
  is($cd && $cd->title, 'First', 'ORM select filtering on the reserved-word column "year"');

  my $track = $schema->resultset('Track')->search({ position => 7 })->single;
  is($track && $track->title, 'Intro', 'ORM select filtering on the reserved-word column "position"');
}

# --- a fresh install has nothing to upgrade -----------------------------------
no_changes('after install');

# --- drift --------------------------------------------------------------------
# Every drift is made in the direction upgrade can repair. Firebird widens a
# VARCHAR and refuses to narrow one, so "year" is not widened on the server: it
# is dropped and re-added SHORTER than the result class wants, and the upgrade
# has to widen it back. The extra table and the extra index carry lower-case
# names: a DROP that is not quoted addresses K32_EXTRA, which does not exist.
# "rank" is the NOT NULL column with a default; "artist" has a row by now, so
# the upgrade has to add it back to a table that is not empty. CD."year" has no
# is_nullable, so it is NOT NULL (ADR 0043): the drift column is added nullable,
# filled for the row that is there, then made NOT NULL -- narrower in size only,
# so the diff carries the TYPE statement and no nullability one.
ok(lives(sub { drift(
  'ALTER TABLE "artist" DROP "name"',
  'ALTER TABLE "artist" DROP "rank"',
  'ALTER TABLE cd DROP "year"',
  'ALTER TABLE cd ADD "year" VARCHAR(50)',
  q{UPDATE cd SET "year" = '1999'},
  'ALTER TABLE cd ALTER "year" SET NOT NULL',
  'CREATE TABLE "k32_extra" ("id" INTEGER NOT NULL PRIMARY KEY, "note" VARCHAR(10))',
  'CREATE INDEX "k32_extra_idx" ON "track" ("position")',
) }), 'drift: two dropped columns, a narrowed column, an extra table, an extra index');

my $diff = lives(sub { $deploy->diff });
ok($diff && $diff->has_changes, 'the drift is seen');

is_deeply(
  [ $diff ? split(/\n/, $diff->as_sql) : () ],
  [
    'DROP TABLE "k32_extra";',
    'DROP INDEX "k32_extra_idx";',
    'ALTER TABLE "CD" ALTER "year" TYPE varchar(100);',
    'ALTER TABLE "artist" ADD "name" varchar(100);',
    q{ALTER TABLE "artist" ADD "rank" integer DEFAULT '13' NOT NULL;},
  ],
  'one statement per drift, each naming the object as the server stores it, the sized '
. 'columns carrying the size, the default before NOT NULL',
);

# --- upgrade ------------------------------------------------------------------
# The drift of the diff above includes an extra table the schema does not have:
# its DROP TABLE is destructive and needs the release (core k399, ADR 0080).
my $unreleased = !eval { $deploy->upgrade; 1 };
my $unreleased_why = "$@";
ok($unreleased && $unreleased_why =~ /allow_destructive/ && $unreleased_why =~ /k32_extra/,
  'upgrade without the release dies before a statement, naming the table it would drop');
ok(lives(sub { $deploy->upgrade(allow_destructive => 1) }), 'upgrade: the server accepts every statement of the diff');

no_changes('after upgrade');

is_deeply(column(artist => 'rank'), { not_null => 1, default_value => q{'13'} },
  'upgrade: "rank" is back, NOT NULL and with its default');
is(eval { $schema->resultset('Artist')->find(1)->rank }, 13,
  '... and the row that was already there got the default: ADD ... DEFAULT x NOT NULL '
. 'on a table with rows is accepted and fills them') or diag $@;

# --- the repaired columns work through the ORM --------------------------------
my $long_year = 'y' x 80;
$ok = lives(sub {
  $schema->resultset('Artist')->find(1)->update({ name => 'Beta' });
  $schema->resultset('CD')->find(1)->update({ year => $long_year });
});
ok($ok, 'ORM update of the re-added column and of the re-widened one');

SKIP: {
  skip 'nothing written', 2 unless $ok;
  is($schema->resultset('Artist')->find(1)->name, 'Beta',
    'the dropped column "name" is back and holds what the ORM wrote');
  is($schema->resultset('CD')->find(1)->year, $long_year,
    '"year" holds 80 characters again -- it was VARCHAR(50) before the upgrade');
}

# --- a change the server refuses is refused by the diff (karr k38) -----------
# The other direction: the live column is WIDER than the result class wants.
# Firebird does not narrow a VARCHAR. Until k38 the diff rendered the narrowing
# statement, the server refused it, and upgrade died half way on the server's
# own text. Now the diff keeps reporting the difference, and generating the
# statement is what dies -- with a message naming table, column and the
# reason -- before ANY statement of the upgrade runs. The extra table below
# sorts before the column change in the script ("DROP TABLE" comes first), so a
# driver that rendered and executed statement by statement would have dropped
# it before it met the refusal; it must still be there afterwards.
ok(lives(sub { drift(
  'ALTER TABLE "track" ALTER "title" TYPE VARCHAR(150)',
  'CREATE TABLE "k32_extra" ("id" INTEGER NOT NULL PRIMARY KEY, "note" VARCHAR(10))',
) }), 'drift: a column widened on the server, and an extra table');

$diff = lives(sub { $deploy->diff });
ok($diff && $diff->has_changes, 'a live column wider than desired: the difference is reported');
like($diff && $diff->summary, qr/column: track\.title/, '... the summary lists the column');

my $err = eval { $diff->as_sql; 1 } ? '' : $@;
isa_ok($err, 'DBIO::Exception', 'as_sql of that diff dies with');
my $why = "$err";
like($why, qr/"track"\."title"/, '... an error about that column');
like($why, qr/varchar\(150\) -> varchar\(100\)/, '... old and new type');
like($why, qr/never narrows/, '... and the reason');
unlike($why, qr/DROP TABLE/, '... the extra table\'s drop is not rendered either');
note $why;

# Released with allow_destructive: the release never covers a refusal (ADR 0080
# section 2), and the refusal is the diff's own message. Unreleased, the guard
# for the table drop answers first -- also before any statement.
eval { $deploy->upgrade; 1 };
like("$@",qr/allow_destructive/, 'upgrade without the release dies at the guard, before a statement');
$@ = '';
my $refused = !eval { $deploy->upgrade(allow_destructive => 1); 1 };
my $upgrade_why = "$@";
ok($refused, 'upgrade dies');
like($upgrade_why, qr/refusing to change 1 column/, '... with the diff\'s refusal, not the server\'s error');
unlike($upgrade_why, qr/Dynamic SQL Error|unsuccessful metadata update/i, '... no statement reached the server');

is(scalar $other->selectrow_array(q{SELECT COUNT(*) FROM rdb$relations WHERE rdb$relation_name = 'k32_extra'}),
  1, 'the extra table is still there: nothing of the upgrade ran');
is(column_size(track => 'title'), 150, '... and the column is as wide as it was');

$diff = lives(sub { $deploy->diff });
ok($diff && $diff->has_changes, '... and the difference is still reported afterwards');

# --- cleanup, and no temp database left behind ---------------------------------
cleanup();

ok(scalar @temp_ids, 'the diffs went through temp databases (' . scalar(@temp_ids) . ')');
for my $id (@temp_ids) {
  my ($tdsn, $tuser, $tpass) = $deploy->_temp_connect_info($id);
  my $left = DBI->connect($tdsn, $tuser, $tpass, {
    RaiseError => 0, PrintError => 0, AutoCommit => 1,
  });
  ok(!$left, 'temp database is gone again: ' . (File::Basename::basename($id)));
  $left->func('ib_drop_database') if $left;    # do not leave it behind either way
}

$other->disconnect;
$schema->storage->disconnect;
done_testing;

# Run a code ref; its return value (or 1) on success, false and a diag on death.
sub lives {
  my ($code) = @_;
  my $got = eval { $code->() // 1 };
  return $got || 1 unless $@;
  diag "died: $@";
  return;
}

# What the server says about one column, read over the other connection.
sub column {
  my ($table, $name) = @_;
  my $cols = eval { DBIO::Firebird::Introspect->new(dbh => $other)->model->{columns}{$table} } || [];
  my ($col) = grep { $_->{column_name} eq $name } @$cols;
  return $col && { map { $_ => $col->{$_} } qw/not_null default_value/ };
}

# The size the server reports for one column, read over the other connection.
sub column_size {
  my ($table, $name) = @_;
  my $cols = eval { DBIO::Firebird::Introspect->new(dbh => $other)->model->{columns}{$table} } || [];
  my ($col) = grep { $_->{column_name} eq $name } @$cols;
  return $col && $col->{size};
}

sub no_changes {
  my ($when) = @_;
  my $diff = lives(sub { $deploy->diff });
  ok($diff && !$diff->has_changes, "diff has no changes $when")
    or diag($diff ? $diff->as_sql : 'no diff');
}

# Change the database behind the schema's back, over the other connection --
# with the schema's own connection closed, for two reasons this server gave:
#
#  * the schema's connection keeps its transaction (use_softcommit commits
#    retaining), and DDL from another connection on a table that transaction
#    has touched waits for it: CREATE INDEX answers `object TABLE "track" is in
#    use` once the lock wait runs out, and without a lock timeout never.
#  * the upgrade runs its DDL over the schema's connection, and DBD::Firebird
#    destroys every statement of a connection on the commit after DDL -- the
#    selects above among them, which the storage prepared and cached. Since
#    k37 the storage notices and prepares them anew; that is the subject of
#    t/23-statement-cache-ddl-live.t and not of this file. With the
#    connection closed here, the assertions after the upgrade below do not
#    rest on it.
#
# The storage reconnects on its next use.
sub drift {
  $schema->storage->disconnect;
  $other->do($_) for @_;
  return 1;
}

# Drop whatever this file creates. The bare spellings are what an install DDL
# that does not quote would have created (ARTIST, TRACK); with them a failing
# run still leaves the database as it found it. The schema's connection is
# closed first so that none of its statements holds a table (as t/10 does).
sub cleanup {
  $schema->storage->disconnect;
  # foreign keys first: a table another one points at cannot be dropped (karr k34)
  my $fks = eval { $other->selectall_arrayref(
    q{SELECT TRIM(rdb$relation_name), TRIM(rdb$constraint_name) FROM rdb$relation_constraints }
  . q{WHERE rdb$constraint_type = 'FOREIGN KEY' AND TRIM(rdb$relation_name) IN ('CD', 'track', 'artist')}) } || [];
  eval { $other->do(sprintf 'ALTER TABLE "%s" DROP CONSTRAINT "%s"', @$_) } for @$fks;
  for my $drop (
    'DROP TABLE "k32_extra"',
    'DROP TABLE "track"', 'DROP TABLE track',
    'DROP TABLE cd',
    'DROP TABLE "artist"', 'DROP TABLE artist',
  ) {
    eval { $other->do($drop) };
  }
  return;
}
