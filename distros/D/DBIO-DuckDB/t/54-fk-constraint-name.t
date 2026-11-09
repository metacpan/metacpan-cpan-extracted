#!/usr/bin/env perl
# t/54-fk-constraint-name.t -- the FK hash carries its name as constraint_name
# (karr k48, ADR 0021 in core).
#
# WHY this matters: core's introspection contract names the key
# `constraint_name`; the driver used to write `fk_id`, which no consumer of the
# contract reads. The name must be what DuckDB itself reports for a real
# database file, not a value the test made up -- DuckDB ignores a name given
# with CONSTRAINT ... FOREIGN KEY and derives <table>_<column>_<parentcolumn>_fkey.

use strict;
use warnings;
use Test::More;
use DBI;
use File::Temp ();
use DBIO::Util qw(file_path);
use DBIO::DuckDB::Introspect::ForeignKeys;

my $dir  = File::Temp->newdir;
my $file = file_path($dir->dirname, 'fk.duckdb');

my $dbh = DBI->connect("dbi:DuckDB:dbname=$file", '', '', { RaiseError => 1, PrintError => 0 });

$dbh->do('CREATE TABLE parent (id INTEGER PRIMARY KEY)');
$dbh->do('CREATE TABLE child (id INTEGER, pid INTEGER, FOREIGN KEY (pid) REFERENCES parent (id))');
$dbh->do('CREATE TABLE named (id INTEGER, pid INTEGER, CONSTRAINT my_fk FOREIGN KEY (pid) REFERENCES parent (id))');

my $fks = DBIO::DuckDB::Introspect::ForeignKeys->fetch(
  $dbh, 'main', { parent => 1, child => 1, named => 1 },
);

is_deeply [ sort keys %$fks ], [qw(child named)], 'FKs found on both child tables';

my ($child) = @{ $fks->{child} };
is $child->{constraint_name}, 'child_pid_id_fkey',
  'constraint_name is the name information_schema reports';
ok !exists $child->{fk_id}, 'no fk_id key';
is_deeply $child->{from_columns}, ['pid'], 'from_columns';
is $child->{to_table}, 'parent', 'to_table';

# DuckDB accepts CONSTRAINT <name> but reports its own derived name.
my ($named) = @{ $fks->{named} };
is $named->{constraint_name}, 'named_pid_id_fkey',
  'a given CONSTRAINT name is not what information_schema reports';
ok !exists $named->{fk_id}, 'no fk_id key on the named FK';

$dbh->disconnect;

done_testing;
