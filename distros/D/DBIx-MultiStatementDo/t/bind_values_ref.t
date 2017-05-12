#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::MultiStatementDo;
use SQL::SplitStatement;

use Test::More tests => 6;

my $sql_code;
my @bind_values;
my @results;

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '', {
    PrintError => 0
});

my $batch = DBIx::MultiStatementDo->new( dbh => $dbh );

# SQLite valid SQL
$sql_code = <<'SQL';
CREATE TABLE state (id, name);
INSERT INTO  state (id, name) VALUES (?, ?);
CREATE TABLE city  (id, name, state_id);
INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?);
INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?)
SQL

@bind_values = (
    undef              , # or []
    [ 1, 'New York' ]  ,
    []                 , # or undef
    [ 1, 'Albany' , 1 ],
    [ 2, 'Buffalo', 1 ],
    undef              ,
    []
);

ok (
    @results = $batch->do( $sql_code, undef, \@bind_values ),
    'mixed statements w/ bind values on sqlite'
);

cmp_ok ( scalar(@results), '==', 5, 'check execution' );

my $cities = $dbh->selectall_arrayref(
    'SELECT id, name, state_id FROM city ORDER BY id'
);

is_deeply(
    $cities, [ [ 1, 'Albany' , 1 ], [ 2, 'Buffalo', 1 ] ],
    'CREATEs mixed with INSERTs with bind values'
);

# ---
# Now check the case of a list of already split statement passed to do()
# ---

$sql_code = <<'SQL';
DROP TABLE state;
DROP TABLE city;
CREATE TABLE state (id, name);
INSERT INTO  state (id, name) VALUES (?, ?);
CREATE TABLE city  (id, name, state_id);
INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?);
INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?)
SQL

@bind_values = (
    undef              ,
    []                 ,
    undef              ,
    [ 1, 'New York' ]  ,
    []                 ,
    [ 1, 'Albany' , 1 ],
    [ 2, 'Buffalo', 1 ],
    undef              ,
    []
);

my $splitter = SQL::SplitStatement->new;

my @statements;

@statements = $splitter->split($sql_code);

cmp_ok ( scalar(@statements), '==', 7, 'check splitting' );

ok (
    @results = $batch->do( \@statements, undef, \@bind_values ),
    'mixed already split statements w/ bind values on sqlite'
);

cmp_ok ( scalar(@results), '==', 7, 'check execution' );
