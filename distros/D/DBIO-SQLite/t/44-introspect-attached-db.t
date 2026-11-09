use strict;
use warnings;
use Test::More;
use DBI;

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

use DBIO::SQLite::Introspect;

# Regression for karr k45.
#
# THE CLAIM this test samples: when the introspected handle carries an
# ATTACHed database, DBIO::SQLite::Introspect MUST refuse loudly -- croak,
# naming the attached schema -- rather than silently pass its tables over.
#
# The silent pass is the whole danger. Introspect reads only the MAIN
# database's sqlite_master, so a table living in an ATTACHed database is
# invisible to it. The deploy diff then sees that table as MISSING and emits
# CREATE TABLE for it in main. That CREATE runs cleanly and shadows the real,
# still-populated attached table with a fresh empty one in main; an unqualified
# SELECT afterwards reads the empty main table while the data sits untouched in
# the attached database. From the user's seat that is indistinguishable from
# data loss, and -- unlike k44's failed DROP chain -- it happens without a
# single error. So the safe state (maintainer's decision on k45, option (a)) is
# to refuse: turn the silent mis-description into a named, actionable exception.
#
# This test asserts the REFUSAL property (a croak that names the attached
# schema), not the mere existence of a code path. Before the fix Introspect
# does NOT croak -- it returns a model that quietly omits the attached table --
# so the croak assertion below is genuinely red, sampling exactly the property
# the fix must add.

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 });

# --- 1. The omission is real -----------------------------------------------
# A table in an ATTACHed database does not appear in main's sqlite_master, so
# introspection that only reads main's sqlite_master genuinely cannot see it.
$dbh->do(q{ATTACH DATABASE ':memory:' AS aux});
$dbh->do('CREATE TABLE aux.remote_only (id INTEGER PRIMARY KEY, name TEXT)');

my %main_master =
  map { $_->[0] => 1 }
  @{ $dbh->selectall_arrayref(
      q{SELECT name FROM sqlite_master WHERE type IN ('table','view')}) };
ok !$main_master{remote_only},
  "aux.remote_only is absent from main's sqlite_master (the omission is real)";

# --- 2. Introspection refuses loudly and names the attached schema ----------
my $model = eval { DBIO::SQLite::Introspect->new(dbh => $dbh)->model };
my $err   = $@;

ok !$model, 'introspection does not return a model when a database is attached';
ok $err, 'introspection croaks instead of silently omitting the attached table';
like $err, qr/\baux\b/,
  'the exception names the attached schema (aux) so the cause is actionable';
like $err, qr/attach/i,
  'and says an attached database is why it refused';

$dbh->do('DETACH DATABASE aux');
$dbh->disconnect;

# --- 3. No false positive: a plain handle introspects normally --------------
{
  my $plain = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 });
  $plain->do('CREATE TABLE local_only (id INTEGER PRIMARY KEY, name TEXT)');

  my $m = eval { DBIO::SQLite::Introspect->new(dbh => $plain)->model };
  ok $m, 'a handle with no attached database still introspects (no croak)'
    or diag "unexpected croak: $@";
  ok $m->{tables}{local_only}, 'and the model contains its table';
  $plain->disconnect;
}

# --- 4. temp is not an attachment: it must NOT trigger the refusal ----------
# PRAGMA database_list reports the temp schema alongside main once a temp table
# exists; temp is part of the connection, not an ATTACHed database, so the
# allowlist (main/temp) keeps it out of the refusal.
{
  my $temp = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 });
  $temp->do('CREATE TABLE kept (id INTEGER PRIMARY KEY, name TEXT)');
  $temp->do('CREATE TEMP TABLE scratch (id INTEGER PRIMARY KEY)');

  my $m = eval { DBIO::SQLite::Introspect->new(dbh => $temp)->model };
  ok $m, 'a temp table/temp schema does not trigger the attached-db refusal'
    or diag "unexpected croak: $@";
  ok $m->{tables}{kept}, 'and the main table is still introspected';
  $temp->disconnect;
}

done_testing;
