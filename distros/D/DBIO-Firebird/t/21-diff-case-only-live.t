use strict;
use warnings;
use Test::More;

# Live: a database whose names differ from the schema's only in letter case is
# refused by diff and upgrade, and nothing in it is touched (karr k41).
#
# This is the database of everybody who installed before k32. The install DDL
# of that time did not quote, Firebird folds an unquoted name to upper case, so
# the table the schema calls `k41_artist` is K41_ARTIST on the server. Since
# k32 every identifier is quoted: the target model says "k41_artist", a diff
# that compares names exactly finds one table to drop and one to create, and
# upgrade runs both. The rows are gone and nothing said so.
#
# Only a server can show the two halves of that: that the bare DDL really
# lands as K41_ARTIST, and that after the refusal the table and its row are
# still there. And only a server can say whether the ways out the error names
# are real -- each one is walked here to an empty diff:
#
#   table   declare the stored spelling in the schema          (nothing changes)
#   index   DROP INDEX, the next upgrade creates the new name  (no rename exists)
#   column  ALTER TABLE ... ALTER COLUMN "NAME" TO "name"
#
# The result class is the shared Artist from core (not redefined here), loaded
# by name as t/19 does; the schema registers it under a table name of this
# file's own. The schema that declares the STORED spelling has no shared class
# to load -- none is written in upper case -- so its source is built from
# Artist's own columns, upper-cased, and has no result class at all.
#
# Skipped unless a DSN is provided (as t/15, t/17, t/19):
#
#   DBIO_TEST_FIREBIRD_DSN
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS
#
# WARNING: creates and drops the tables K41_ARTIST and "k41_artist".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live case-only diff test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::ResultSource::Table;
use DBIO::ResultClass::HashRefInflator;
use DBIO::Firebird::DDL;
use DBIO::Firebird::Deploy;
use DBIO::Firebird::Introspect;

{
  # The schema as its author wrote it: lower-case names.
  package DBIO::Firebird::Test::K41Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Firebird');
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [qw/ Artist /] });
}
{
  # The same schema, declared the way the old database stores it.
  package DBIO::Firebird::Test::K41StoredSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Firebird');
}

# A table name no other file uses. Set on this schema's registration of the
# source, which is a copy: the shared class keeps `artist`.
my $artist = DBIO::Firebird::Test::K41Schema->source('Artist');
$artist->name('k41_artist');

# karr k34: install_ddl now writes the unique constraints of the shared class,
# and a live table without them would be a constraint difference of its own
# (refused, DBIO::Firebird::Diff::Constraint) -- the old installation below
# was made before they were written. Case-only names are this file's subject,
# constraints are t/29's: the process-local copy of the source has none.
delete @{ $artist->{_unique_constraints} }{ grep { $_ ne 'primary' } keys %{ $artist->{_unique_constraints} } };

{
  my $stored = DBIO::ResultSource::Table->new({ name => 'K41_ARTIST' });
  $stored->add_columns(map { uc($_) => { %{ $artist->column_info($_) } } } $artist->columns);
  $stored->set_primary_key(map { uc } $artist->primary_columns);
  DBIO::Firebird::Test::K41StoredSchema->register_source(Artist => $stored);
}

my %connect = (quote_names => 1, on_connect_call => 'use_softcommit');
my $schema  = DBIO::Firebird::Test::K41Schema->connect($dsn, $user, $pass, {%connect});
my $stored  = DBIO::Firebird::Test::K41StoredSchema->connect($dsn, $user, $pass, {%connect});

eval { $schema->storage->dbh->do('SELECT 1 FROM rdb$database'); 1 }
  or plan skip_all => "Cannot reach Firebird server: $@";

# The old installation, the assertions about what the server holds, and the
# manual steps of the ways out all go over a connection of their own, as in
# t/19 -- ten seconds for a lock instead of the default, which is for good.
my $other = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
}) or plan skip_all => 'Cannot connect: ' . DBI->errstr;
$other->func(-lock_resolution => { wait => 10 }, 'ib_set_tx_param');

# Core announces non-transactional DDL once per process; it is accurate and it
# is not what this file is about.
$SIG{__WARN__} = sub {
  warn @_ unless $_[0] =~ /^non-transactional DDL on /;
};

my $deploy        = DBIO::Firebird::Deploy->new(schema => $schema);
my $stored_deploy = DBIO::Firebird::Deploy->new(schema => $stored);

# Today's install DDL of the lower-case schema. With the quotes taken out it is
# the statement an install before k32 sent.
my $install_ddl = DBIO::Firebird::DDL->install_ddl($schema);

cleanup();

# === table ======================================================================
(my $old_ddl = $install_ddl) =~ s/"//g;
ok(lives(sub { raw($old_ddl, q{INSERT INTO k41_artist (artistid, name) VALUES (1, 'Alpha')}) }),
  'the old installation: the install DDL without quotes, and a row');

is_deeply([ tables() ], ['K41_ARTIST'],
  'the server stores the unquoted table upper-cased: K41_ARTIST, and no "k41_artist"');

refused_ok($deploy, [ qr/table "K41_ARTIST"/, qr/"k41_artist"/ ], 'table');

is_deeply([ tables() ], ['K41_ARTIST'],
  'after the refused diff and upgrade the table is still there, and no second one beside it');
is(eval { $other->selectrow_array('SELECT name FROM k41_artist WHERE artistid = 1') }, 'Alpha',
  '... and so is its row') or diag $@;

# --- way out: declare the stored spelling ---------------------------------------
# Nothing on the server changes; the schema names table and columns as they
# are stored, and the target model then says K41_ARTIST as well.
no_changes($stored_deploy, 'schema declaring the stored spelling (K41_ARTIST, upper-case columns)');

is_deeply(
  eval { [ map { $_->{NAME} } hashes($stored) ] } || "$@", ['Alpha'],
  '... and the ORM reads the old row through it: "K41_ARTIST" quoted is the table the server has',
);

# === index ======================================================================
# What the stored-spelling schema meets next. The old install named a unique
# column's index <table>_<column>_idx, unquoted: K41_ARTIST_NAME_IDX. Today's
# DDL quotes that name with the declared spellings and its own lower-case
# suffix: "K41_ARTIST_NAME_idx". No declaration in the schema can close that
# gap, the suffix is the DDL's.
$stored->source('Artist')->column_info('NAME')->{is_unique} = 1;

ok(lives(sub { raw('CREATE UNIQUE INDEX k41_artist_name_idx ON k41_artist (name)') }),
  'the old installation had a unique index on the column, created unquoted');
is_deeply([ indexes('K41_ARTIST') ], ['K41_ARTIST_NAME_IDX'], 'the server stores it as K41_ARTIST_NAME_IDX');

refused_ok($stored_deploy,
  [ qr/index "K41_ARTIST_NAME_IDX"/, qr/"K41_ARTIST_NAME_idx"/, qr/table "K41_ARTIST"/ ], 'index');

is_deeply([ indexes('K41_ARTIST') ], ['K41_ARTIST_NAME_IDX'],
  'after the refused diff and upgrade the index is still there, and no second one beside it');

# --- way out: drop it, the upgrade creates the new name -------------------------
ok(lives(sub { raw('DROP INDEX K41_ARTIST_NAME_IDX') }), 'way out: DROP INDEX on the old name');

my $diff = lives(sub { $stored_deploy->diff });
is(eval { $diff->as_sql }, 'CREATE UNIQUE INDEX "K41_ARTIST_NAME_idx" ON "K41_ARTIST" ("NAME");',
  '... leaves an ordinary diff: create the index under the name the DDL gives it') or diag $@;

quiet();
ok(lives(sub { $stored_deploy->upgrade }), '... which upgrade applies');
is_deeply([ indexes('K41_ARTIST') ], ['K41_ARTIST_NAME_idx'], '... the index now carries the new name');
no_changes($stored_deploy, 'after it');
is(eval { $other->selectrow_array('SELECT name FROM k41_artist WHERE artistid = 1') }, 'Alpha',
  '... and the row has been there all along') or diag $@;

# === column =====================================================================
# The table spelled as the schema spells it, one column not: a table somebody
# created with quotes and extended without.
cleanup();

(my $mixed_ddl = $install_ddl) =~ s/"name"/name/;
ok(lives(sub { raw($mixed_ddl, q{INSERT INTO "k41_artist" ("artistid", name) VALUES (1, 'Alpha')}) }),
  'a table created quoted, with one column left unquoted, and a row');

is_deeply([ columns('k41_artist') ], [qw/artistid NAME rank charfield/],
  'the server stores that one column upper-cased: NAME');

refused_ok($deploy, [ qr/column "NAME"/, qr/"name"/, qr/table "k41_artist"/ ], 'column');

is_deeply([ columns('k41_artist') ], [qw/artistid NAME rank charfield/],
  'after the refused diff and upgrade the column is still there, and no second one beside it');
is(eval { $other->selectrow_array('SELECT name FROM "k41_artist" WHERE "artistid" = 1') }, 'Alpha',
  '... and so is its value') or diag $@;

# --- way out: rename the column -------------------------------------------------
ok(lives(sub { raw('ALTER TABLE "k41_artist" ALTER COLUMN "NAME" TO "name"') }),
  'way out: ALTER TABLE ... ALTER COLUMN "NAME" TO "name"');

no_changes($deploy, 'after the rename');
is(eval { $schema->resultset('Artist')->find(1)->name }, 'Alpha',
  '... and the ORM reads the value that was in NAME') or diag $@;

cleanup();
$other->disconnect;
undef $other;
done_testing;

END { cleanup() if $other }

# Run a code ref; its return value (or 1) on success, false and a diag on death.
sub lives {
  my ($code) = @_;
  my $got = eval { $code->() // 1 };
  return $got || 1 unless $@;
  diag "died: $@";
  return;
}

# Close both schema connections. Each keeps its transaction (use_softcommit
# commits retaining), and DDL on a table that transaction has touched waits
# for it -- from the other schema's connection without a timeout. See drift()
# in t/19 for the long version. The storages reconnect on their next use.
sub quiet {
  $_->storage->disconnect for $schema, $stored;
  return;
}

# Statements sent behind the schemas' backs: the old installation and the
# manual steps of a way out.
sub raw {
  quiet();
  $other->do($_) for @_;
  return 1;
}

# The diff of this deploy is refused at every place a caller can ask it for
# statements, upgrade is refused too, and each error names both spellings.
#
# Deploy->diff itself returns: it builds the two models and hands back the
# diff object, whose operations are computed on first use. The refusal is that
# computation.
sub refused_ok {
  my ($deploy, $names, $what) = @_;

  for my $entry (qw/as_sql has_changes summary/) {
    quiet();
    my $diff = lives(sub { $deploy->diff });
    ok($diff, "$what: Deploy->diff builds the two models and returns the diff object") or next;
    my $got  = eval { $diff->$entry };
    my $err  = "$@";
    ok(!defined $got && length $err, "$what: diff->$entry dies") or diag "it returned: $got";
    like($err, $_, "$what: diff->$entry names $_") for @$names;
  }

  quiet();
  my $done = eval { $deploy->upgrade; 1 };
  my $err  = "$@";
  ok(!$done, "$what: upgrade dies") or diag 'upgrade ran';
  like($err, $_, "$what: upgrade names $_") for @$names;

  quiet();
  return;
}

sub no_changes {
  my ($deploy, $when) = @_;
  quiet();
  my $diff = lives(sub { $deploy->diff });
  ok($diff && eval { !$diff->has_changes }, "diff has no changes: $when")
    or diag($diff ? eval { $diff->as_sql } // $@ : 'no diff');
  quiet();
  return;
}

# All rows of the one source as plain hashes -- the stored-spelling schema has
# no result class to inflate into.
sub hashes {
  my ($schema) = @_;
  my @rows = $schema->resultset('Artist')->search(undef, {
    result_class => 'DBIO::ResultClass::HashRefInflator',
  })->all;
  $schema->storage->disconnect;
  return @rows;
}

# What the server holds, read over the other connection, exact spelling.
sub model { DBIO::Firebird::Introspect->new(dbh => $other)->model }

sub tables  { sort grep { /^k41_/i } keys %{ model()->{tables} } }
sub columns { map { $_->{column_name} } @{ model()->{columns}{ $_[0] } || [] } }
sub indexes { sort keys %{ model()->{indexes}{ $_[0] } || {} } }

# Drop whatever this file creates, in both spellings: a run that fails half way
# -- or runs against a diff that still drops and creates -- leaves the database
# as it found it.
sub cleanup {
  quiet();
  eval { $other->do($_) } for 'DROP TABLE K41_ARTIST', 'DROP TABLE "k41_artist"';
  return;
}
