#!/usr/bin/env perl
# t/30-deploy.t — DDL generation + deploy round-trip.

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::Test;
use DBIO::DuckDB::DDL;
use DBIO::DuckDB::Deploy;

my $schema = DBIO::DuckDB::Test->init_schema(no_populate => 1);

my $ddl = DBIO::DuckDB::DDL->install_ddl($schema);
ok length $ddl, 'DDL generated';
like $ddl, qr/CREATE TABLE "?artist"?/, 'DDL includes CREATE TABLE artist';
like $ddl, qr/CREATE TABLE "?cd"?/,     'DDL includes CREATE TABLE cd';
like $ddl, qr/PRIMARY KEY/,             'DDL includes PRIMARY KEY';
like $ddl, qr/nextval/,                 'auto-increment uses nextval sequence';
like $ddl, qr/CREATE SEQUENCE/,         'sequence created';

# Schema already deployed by init_schema; verify tables exist.
my $rows = $schema->storage->dbh->selectall_arrayref(
  q{SELECT table_name FROM information_schema.tables
    WHERE table_schema = 'main' ORDER BY table_name}
);
my @names = map { $_->[0] } @$rows;
ok scalar(grep { $_ eq 'artist' } @names), 'artist table present';
ok scalar(grep { $_ eq 'cd' }     @names), 'cd table present';

done_testing;
