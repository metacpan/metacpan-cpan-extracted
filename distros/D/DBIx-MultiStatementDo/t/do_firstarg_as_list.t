#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::MultiStatementDo;
use SQL::SplitStatement;

use Test::More tests => 3;

# SQLite valid SQL
my $sql_code = <<'SQL';
CREATE TABLE state (id, name);
INSERT INTO  state (id, name) VALUES (?, ?);
CREATE TABLE city  (id, name, state_id);
INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?);
INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?);
DROP TABLE state;
SQL

my @bind_values = (1, 'New York', 1, 'Albany', 1, 2, 'Buffalo', 1);

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '', {
    PrintError => 0
});

my $splitter = SQL::SplitStatement->new;

# Two value listref.
my @statements_and_placeholders
    = $splitter->split_with_placeholders( $sql_code );

my $batch = DBIx::MultiStatementDo->new( dbh => $dbh );
my @results;

ok (
    @results = $batch->do( \@statements_and_placeholders, undef, @bind_values ),
    'mixed statements w/ bind values on sqlite'
);
cmp_ok ( scalar(@results), '==', 6, 'check success' );

my $cities = $dbh->selectall_arrayref(
    'SELECT id, name, state_id FROM city ORDER BY id'
);

is_deeply(
    $cities, [ [ 1, 'Albany' , 1 ], [ 2, 'Buffalo', 1 ] ],
    'CREATEs mixed with INSERTs with bind values'
)
