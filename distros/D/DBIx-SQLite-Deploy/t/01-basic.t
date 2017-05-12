#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use DBIx::SQLite::Deploy;

my ($scratch, $file, $deploy, $dbh, $result);

$scratch = Directory::Scratch->new;

$file = $scratch->file(qw/ path to database.sqlite /);
ok(! -f $file );

{
    $deploy = DBIx::SQLite::Deploy->deploy( $file, => <<_END_ );
[% PRIMARY_KEY = "INTEGER PRIMARY KEY AUTOINCREMENT" %]
[% KEY = "INTEGER" %]
[% CLEAR %]
---
CREATE TABLE artist (

    id                  [% PRIMARY_KEY %],
    uuid                TEXT NOT NULL,

    name                TEXT,
    description         TEXT,

    UNIQUE (uuid)
);
---
CREATE TABLE cd (

    id                  [% PRIMARY_KEY %],

    title               TEXT,
    description         TEXT
);
_END_

    ok(! -f $file );
    is( ($deploy->information)[0], "dbi:SQLite:dbname=$file" );
    ok( -f $file );
    ok( -s _ );

    ok( $dbh = $deploy->connect );
    ok( $dbh->ping );

    $dbh->do( "INSERT INTO artist (uuid, name) VALUES ('1', 'Alice')" );
    $result = $dbh->selectall_arrayref( "SELECT * FROM artist" );
    cmp_deeply( $result, [ [ 1, 1, 'Alice', undef ] ] );
}

{
    $deploy = DBIx::SQLite::Deploy->deploy( $file, => <<_END_ );
CREATE TABLE track ( title TEXT );
_END_

    ok( $dbh = $deploy->connect );
    ok( $dbh->ping );

    $result = $dbh->selectall_arrayref( "SELECT * FROM artist" );
    cmp_deeply( $result, [ [ 1, 1, 'Alice', undef ] ] );
}

{
    $deploy = DBIx::SQLite::Deploy->deploy( $scratch->file( 'empty.sqlite' ) );

    ok( $dbh = $deploy->connect );
    ok( $dbh->ping );
}
