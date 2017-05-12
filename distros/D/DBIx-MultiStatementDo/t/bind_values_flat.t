#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::MultiStatementDo;

use Test::More tests => 3;

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '', {
    PrintError => 0
}) or die $DBI::errstr;

my $sql_code;
my @bind_values;
my $batch;
my $cities;

$sql_code = <<'SQL';
CREATE TABLE state (id, name);
INSERT INTO  state (id, name) VALUES (?, ?);
CREATE TABLE city  (id, name, state_id);
INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?);
INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?);
DROP TABLE state;
SQL

@bind_values = (1, 'New York', 1, 'Albany', 1, 2, 'Buffalo', 1);

$batch = DBIx::MultiStatementDo->new( dbh => $dbh );
my @results;

ok (
    @results = $batch->do( $sql_code, undef, @bind_values ),
    'mixed statements w/ bind values on sqlite'
);
cmp_ok ( scalar(@results), '==', 6, 'check success' );

$cities = $dbh->selectall_arrayref(
    'SELECT id, name, state_id FROM city ORDER BY id'
);

is_deeply(
    $cities, [ [ 1, 'Albany' , 1 ], [ 2, 'Buffalo', 1 ] ],
    'CREATEs mixed with INSERTs with bind values'
)
