use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBI;
use DBIO::Test::ExtensionSet qw(extension_set_ok extension_set_violations);
use DBIO::Extension::Protocol;
use DBIO::SQLite::Deploy;
use DBIO::SQLite::Introspect;
use DBIO::SQLite::Extension::FTS5;
use DBIO::SQLite::Extension::RTree;

# OFFLINE test: a set of extension classes over DBIO::SQLite::Deploy runs
# through core's commutativity test (ADR 0066, section 2.4; karr k85).
#
# WHY: the protocol makes the result independent of the order of the
# extensions only as long as each extension keeps to it. The driver is the one
# that applies claims to its model, so the driver is also what the test has to
# be run over: a way of applying them that depends on order would show here
# and nowhere else.
#
# What this file claims:
#   1. FTS5, R*Tree and an extension with a library commute over the SQLite
#      deploy, in every order, on a database that holds both kinds of virtual
#      table -- the extensions of the family, and any pair of them;
#   2. the test is not vacuous here: the claims really take the shadow tables
#      out of the model (they are in it without the extensions), each in its
#      own module only, in either order;
#   3. an extension that keeps state between calls is reported, so a violation
#      would show.

{
  package T78::Lib;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'libz' }
  sub driver { 'DBIO::SQLite' }
  sub activation { { load => { libz => '/opt/sqlite/libz.so' } } }

  package T78::Stateful;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'stateful' }
  sub driver { 'DBIO::SQLite' }
  my $calls = 0;
  sub claims { $calls++ ? [ [ table => 'docs' ] ] : [] }
}

sub memory_db {
  return DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
}

# The live model, with the shadow tables in it as a libsqlite without PRAGMA
# table_list (or any other source that does not classify them) hands them over.
my ($dbh, $source, $target);
{
  no warnings 'redefine';
  local *DBIO::SQLite::Introspect::Tables::_drop_shadow_tables = sub {};
  $dbh = memory_db;
  $dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
  $dbh->do('CREATE VIRTUAL TABLE docs USING fts5(title, body)');
  $dbh->do('CREATE VIRTUAL TABLE geo USING rtree(id, minx, maxx, miny, maxy)');
  $source = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;

  my $bare = memory_db;
  $bare->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
  $target = DBIO::SQLite::Introspect->new(dbh => $bare)->model;
}

my %fixture = (
  driver => 'DBIO::SQLite::Deploy',
  source => $source,
  target => $target,
  dbh    => $dbh,
);

# --- 1 -------------------------------------------------------------------------
extension_set_ok(
  %fixture,
  extensions => [qw( DBIO::SQLite::Extension::FTS5 DBIO::SQLite::Extension::RTree T78::Lib )],
  name       => 'fts5, rtree and a library extension commute over the SQLite deploy',
);
extension_set_ok(
  %fixture,
  extensions => [qw( DBIO::SQLite::Extension::FTS5 DBIO::SQLite::Extension::RTree )],
  name       => 'fts5 and rtree commute',
);
extension_set_ok(
  %fixture,
  extensions => [qw( DBIO::SQLite::Extension::FTS5 )],
  name       => 'a set of one',
);

# --- 2 -------------------------------------------------------------------------
{
  my @tables = sort keys %{ $source->{tables} };
  is scalar(@tables), 1 + 2 + 5 + 3, 'the fixture holds the shadow tables (artist, docs, geo and eight of theirs)';

  my %left;
  for my $order ([qw( fts5 rtree )], [qw( rtree fts5 )]) {
    my $protocol = DBIO::Extension::Protocol->new(
      entries   => [ map { { name => $_->name, class => $_, options => {}, installed => 0 } }
                       qw( DBIO::SQLite::Extension::FTS5 DBIO::SQLite::Extension::RTree ) ],
      run_order => $order,
      driver    => DBIO::SQLite::Deploy->new->_extension_driver_helpers,
    );
    $protocol->inspect($dbh);
    my ($s) = $protocol->extend_models(DBIO::SQLite::Deploy->new, $source, $target);
    is_deeply [ sort keys %{ $s->{tables} } ], [qw( artist docs geo )], "[@$order] only the application's tables are left (virtual tables included)";
    ok !grep({ /^(?:docs|geo)_/ } keys %{ $s->{columns} }, keys %{ $s->{indexes} }), "[@$order] ... and none of their sections";
  }

  # each extension takes the shadow tables of its own module only
  for my $one (['DBIO::SQLite::Extension::FTS5', qr/^docs_/], ['DBIO::SQLite::Extension::RTree', qr/^geo_/]) {
    my ($class, $own) = @$one;
    my $protocol = DBIO::Extension::Protocol->new(
      entries => [ { name => $class->name, class => $class, options => {}, installed => 0 } ],
      driver  => DBIO::SQLite::Deploy->new->_extension_driver_helpers,
    );
    $protocol->inspect($dbh);
    my ($s) = $protocol->extend_models(DBIO::SQLite::Deploy->new, $source, $target);
    is scalar(grep { $_ =~ $own } keys %{ $s->{tables} }), 0, $class->name . ': its shadow tables are gone';
    my $other = $class->name eq 'fts5' ? qr/^geo_/ : qr/^docs_/;
    ok scalar(grep { $_ =~ $other } keys %{ $s->{tables} }), '... and the other module\'s are still there';
  }
}

# --- 3 ---------------------------------------------------------------------------
{
  my @v = extension_set_violations(%fixture,
    extensions => [qw( DBIO::SQLite::Extension::FTS5 T78::Stateful )]);
  ok scalar @v, 'an extension that keeps state between calls is reported';
  like join("\n", @v), qr/differs from order/, '... as a difference between runs';
}

done_testing;
