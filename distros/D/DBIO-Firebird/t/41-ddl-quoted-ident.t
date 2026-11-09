use strict;
use warnings;
use Test::More;

# Offline: the install DDL quotes every identifier it takes from a result
# class (karr k32).
#
# The storage is a quote-everything storage -- sql_quote_char is '"' on
# DBIO::Firebird::Storage::Common, with or without quote_names -- so the ORM
# asks for "artist". Firebird folds a BARE name to upper case: a table created
# as `CREATE TABLE artist` is ARTIST, and "artist" is then `Table unknown`. A
# reserved word used as a column name (`year`, `position`) is not even parsed
# bare. So what the DDL emits has to be spelled the way the SQLMaker spells it.
#
# The result classes are the shared ones from core, not redefined here; only
# the five this file reads are loaded.
#
# The last section is the other half of "a statement the server parses": the
# order of DEFAULT and NOT NULL inside a column clause.

use DBIO::Firebird::DDL;
use DBIO::Firebird::Storage;

{
  package DBIO::Firebird::Test::K32DDLSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [qw/
    Artist CD Track Year2000CDs ComputedColumn
  /] });
}

my $schema = 'DBIO::Firebird::Test::K32DDLSchema';

# karr k34: the shared CD declares is_deferrable => 1 on its relationships and
# Firebird has no deferrable constraints, so install_ddl refuses that
# (t/69-ddl-constraints.t). This file is not about it: the process-local copy
# of the source has the attribute off.
for my $rel ($schema->source('CD')->relationships) {
  $schema->source('CD')->relationship_info($rel)->{attrs}{is_deferrable} = 0;
}

# --- the helper ---------------------------------------------------------------
is(DBIO::Firebird::DDL::_firebird_quote_ident('artist'), '"artist"',
  'a simple lower-case name is quoted');
is(DBIO::Firebird::DDL::_firebird_quote_ident('ARTIST'), '"ARTIST"',
  'a simple upper-case name is quoted');
is(DBIO::Firebird::DDL::_firebird_quote_ident('year'), '"year"',
  'a reserved word is quoted');
is(DBIO::Firebird::DDL::_firebird_quote_ident(q{a"b}), '"a""b"',
  'an embedded double-quote is doubled');
ok(!eval { DBIO::Firebird::DDL::_firebird_quote_ident(undef); 1 },
  'an undef name dies instead of rendering the empty identifier ""');

# --- the claim the helper serves ----------------------------------------------
# What the DDL creates and what the SQLMaker asks for must be one spelling.
is(DBIO::Firebird::Storage->sql_quote_char, '"',
  'the storage quotes with " -- the spelling the DDL has to match');

my $ddl = DBIO::Firebird::DDL->install_ddl($schema);

like($ddl, qr/^CREATE TABLE "artist" \($/m,
  'a lower-case table name is quoted: the ORM selects FROM "artist"');
like($ddl, qr/^CREATE TABLE "track" \($/m, '... and so is the second one');
unlike($ddl, qr/CREATE TABLE (?:artist|track)\b/,
  'no bare spelling the server would fold to ARTIST / TRACK');

like($ddl, qr/^  "artistid" INTEGER/m,       'column names are quoted');
like($ddl, qr/^  "year" VARCHAR\(100\)/m,    'the reserved word year is quoted');
like($ddl, qr/^  "position" INTEGER\b/m,         'the reserved word position is quoted');
like($ddl, qr/^  PRIMARY KEY \("artistid"\)$/m, 'primary key columns are quoted');

# Every column line and every primary key line, not just the sampled ones.
my @bare = grep { !/^  (?:"[^"]+" |PRIMARY KEY \("[^"]+"(?:, "[^"]+")*\)$)/ }
  grep { /^  / } split /\n/, $ddl;
is_deeply(\@bare, [], 'no column or primary key line carries a bare identifier');

# --- a scalar-ref name is the user's literal ----------------------------------
# DBIO::Test::Schema::CD declares table(\'cd'). A scalar-ref name is literal
# SQL: the SQLMaker writes it into FROM as given, unquoted, so the DDL must not
# quote it either -- quoting here would create "cd" while the ORM selects
# FROM cd, which the server reads as CD.
is(ref $schema->source('CD')->name, 'SCALAR', 'CD is the scalar-ref table name');
like($ddl, qr/^CREATE TABLE cd \($/m,
  'a scalar-ref table name is emitted as written, not quoted');
unlike($ddl, qr/CREATE TABLE "cd"/, '... so there is no "cd" beside it');

# --- a view: the name is ours to quote, the body is not ------------------------
# view_definition is SQL the user wrote; it goes out as written, bare `year`
# and all. Whether the server takes that body is the user's SQL to answer for.
like($ddl,
  qr/^CREATE VIEW "year2000cds" AS SELECT cdid, artist, title, year, genreid, single_track FROM cd WHERE year = '2000';$/m,
  'the view name is quoted and the view definition is passed through untouched');

# --- the unique index path ----------------------------------------------------
# No shared result class flags a column is_unique, so the flag is set for the
# length of this block on the one registered here.
{
  my $info = $schema->source('Track')->column_info('position');
  local $info->{is_unique} = 1;

  like(DBIO::Firebird::DDL->install_ddl($schema),
    qr/^CREATE UNIQUE INDEX "track_position_idx" ON "track" \("position"\);$/m,
    'unique index: its name, its table and its column are quoted');
}
unlike(DBIO::Firebird::DDL->install_ddl($schema), qr/CREATE UNIQUE INDEX/,
  '(the flag is gone again after the block)');

# --- DEFAULT before NOT NULL --------------------------------------------------
# Firebird's column clause is <type> [DEFAULT ...] [NOT NULL], in that order.
# The other order is not a style: `VARCHAR(20) NOT NULL DEFAULT 'foo'` is
# `Token unknown - DEFAULT` and the whole CREATE TABLE fails.
# DBIO::Test::Schema::ComputedColumn is the shared class with columns that are
# both: one with a string default, one with a scalar-ref (literal SQL) default.
like($ddl, qr/^  "charfield" VARCHAR\(20\) DEFAULT 'foo' NOT NULL,?$/m,
  'a string default comes before NOT NULL');
like($ddl, qr/^  "a_computed_column" VARCHAR\(255\) DEFAULT getdate\(\) NOT NULL,?$/m,
  'a scalar-ref default comes before NOT NULL');
unlike($ddl, qr/NOT NULL DEFAULT/, 'the order the server rejects appears nowhere');
like($ddl, qr/^  "a_timestamp" TIMESTAMP NOT NULL,?$/m,
  'NOT NULL without a default is unchanged');
# rank declares no is_nullable: NOT NULL since ADR 0043 (karr k52), still after
# the DEFAULT.
like($ddl, qr/^  "rank" INTEGER DEFAULT '13' NOT NULL,?$/m,
  'a default on a column without is_nullable is followed by NOT NULL');

done_testing;
