#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::MultiStatementDo;

use Test::More;

BEGIN {
    unless ( eval 'use Test::Exception; 1' ) {
        plan skip_all => "please install Test::Exception to run these tests"
    }
}

plan tests => 16;

my @sql_statements;
my @flat_bind_values;
my @compound_bind_values;
my @placeholder_numbers;
my $batch;
my $cities;

@sql_statements = (
    'CREATE TABLE state (id, name)',
    'INSERT INTO  state (id, name) VALUES (?, ?)',
    'CREATE TABLE city  (id, name, state_id)',
    'INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?)',
    'INSERT INTO  city  (id, name, state_id) VALUES (?, ?, ?)',
    'DROP TABLE state'
);

@compound_bind_values = (
    undef              , # or []
    [ 1, 'New York' ]  ,
    []                 , # or undef
    [ 1, 'Albany' , 1 ],
    [ 2, 'Buffalo', 1 ],
    undef,
    []
);

@flat_bind_values = (1, 'New York', 1, 'Albany', 1, 2, 'Buffalo', 1);

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '', {
    PrintError => 1
}) or die $DBI::errstr;

$batch = DBIx::MultiStatementDo->new( dbh => $dbh );
my @results;

throws_ok {
    $batch->do( \@sql_statements, undef, @flat_bind_values )
} qr/Bind values as a flat list require the placeholder numbers listref/,
'Bind values as a flat list require the placeholder numbers listref';

ok (
    @results = $batch->do(
        \@sql_statements, undef, \@compound_bind_values
    ),
    'mixed statements w/ bind values as compound list'
);
cmp_ok ( scalar(@results), '==', 6, 'check success' );

$cities = $dbh->selectall_arrayref(
    'SELECT id, name, state_id FROM city ORDER BY id'
);

is_deeply(
    $cities, [ [ 1, 'Albany' , 1 ], [ 2, 'Buffalo', 1 ] ],
    'check insertions'
);

unshift @sql_statements, 'DROP TABLE city';
@placeholder_numbers = (0, 0, 2, 0, 3, 3, 0);

ok (
    @results = $batch->do(
        [ \@sql_statements, \@placeholder_numbers ],
        undef,
        @flat_bind_values
    ),
    'mixed statements w/ bind values as flat list'
);
cmp_ok ( scalar(@results), '==', 7, 'check success' );

$cities = $dbh->selectall_arrayref(
    'SELECT id, name, state_id FROM city ORDER BY id'
);

is_deeply(
    $cities, [ [ 1, 'Albany' , 1 ], [ 2, 'Buffalo', 1 ] ],
    'check insertions'
);

@compound_bind_values = (
    undef              , # or []
    undef              , # or []
    [ 1, 'New York' ]  ,
    []                 , # or undef
    [ 1, 'Albany' , 1 ],
    [ 2, 'Buffalo', 1 ],
    [],
    []
);

ok (
    @results = $batch->do(
        [ \@sql_statements, \@placeholder_numbers ],
        undef,
        \@compound_bind_values
    ),
    'mixed statements w/ compound bind values and placeholder numbers'
);
cmp_ok ( scalar(@results), '==', 7, 'check success' );

$cities = $dbh->selectall_arrayref(
    'SELECT id, name, state_id FROM city ORDER BY id'
);

is_deeply(
    $cities, [ [ 1, 'Albany' , 1 ], [ 2, 'Buffalo', 1 ] ],
    'check insertions'
);

$batch = DBIx::MultiStatementDo->new( dbh => $dbh, rollback => 0 );

ok (
    @results = $batch->do(
        [ \@sql_statements, \@placeholder_numbers ],
        undef,
        @flat_bind_values
    ),
    'mixed statements w/ bind values as flat list, no rollback'
);
cmp_ok ( scalar(@results), '==', 7, 'check success' );

$cities = $dbh->selectall_arrayref(
    'SELECT id, name, state_id FROM city ORDER BY id'
);

is_deeply(
    $cities, [ [ 1, 'Albany' , 1 ], [ 2, 'Buffalo', 1 ] ],
    'check insertions'
);

ok (
    @results = $batch->do(
        [ \@sql_statements, \@placeholder_numbers ],
        undef,
        \@compound_bind_values
    ),
    'mixed statements w/ compound bind values and placeholder numbers, no rollback'
);
cmp_ok ( scalar(@results), '==', 7, 'check success' );

$cities = $dbh->selectall_arrayref(
    'SELECT id, name, state_id FROM city ORDER BY id'
);

is_deeply(
    $cities, [ [ 1, 'Albany' , 1 ], [ 2, 'Buffalo', 1 ] ],
    'check insertions'
);
