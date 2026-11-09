#!/usr/bin/env perl
# t/32-ddl-not-null.t — DBIO::DuckDB::DDL's not_null derivation from
# column_info is_nullable (karr #147, ADR 0043). Offline: a mock schema,
# no database.
#
# ADR 0043 (core): canonical_column turns a MISSING is_nullable into
# not_null=1, but the driver DDLs only emitted NOT NULL for a defined &&
# false is_nullable. Option A: missing means NOT NULL. A column whose
# column_info carries no is_nullable key must therefore deploy as NOT NULL.

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::DDL;

package Mock::Source;
sub new { my ($class, %a) = @_; bless { %a }, $class }
sub name { $_[0]->{name} }
sub primary_columns { @{ $_[0]->{pk} || [] } }
sub columns { @{ $_[0]->{cols} } }
sub column_info { $_[0]->{info}{ $_[1] } }
sub result_class { $_[0] }
sub relationships { () }
sub index_declarations_for { () }

package Mock::Schema;
sub new { my ($class, %a) = @_; bless { %a }, $class }
sub sources { keys %{ $_[0]->{sources} } }
sub source { $_[0]->{sources}{ $_[1] } }

package main;

my $schema = Mock::Schema->new(sources => {
  t => Mock::Source->new(
    name => 't',
    cols => [qw(a b c)],
    info => {
      a => { data_type => 'INTEGER', is_nullable => 0 },
      b => { data_type => 'INTEGER', is_nullable => 1 },
      c => { data_type => 'INTEGER' },   # no is_nullable key
    },
  ),
});

my $ddl = DBIO::DuckDB::DDL->install_ddl($schema);

is $ddl,
  qq{CREATE TABLE "t" (\n  "a" INTEGER NOT NULL,\n  "b" INTEGER,\n  "c" INTEGER NOT NULL\n);},
  'missing is_nullable deploys as NOT NULL (ADR 0043 Option A)';

done_testing;
