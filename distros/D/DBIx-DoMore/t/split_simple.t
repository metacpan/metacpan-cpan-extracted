#!perl

use strict;
use warnings;

use DBI;
use DBIx::DoMore;

use Test::More tests => 4;

my $sql = <<'SQL';
CREATE TABLE foo (
    foo_field_1 VARCHAR,
    foo_field_2 VARCHAR
);

CREATE TABLE bar (
    bar_field_1 VARCHAR,
    bar_field_2 VARCHAR
);
SQL

chomp( my $clean_sql = $sql );

my @statements = DBIx::DoMore->split($sql);

ok (
    @statements == 2,
    'correct number of statements - class method'
);

ok (
    join('', @statements) eq $clean_sql,
    'code successfully rebuilt - class method'
);

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '');
my $splitter = DBIx::DoMore->new(dbh => $dbh);

@statements = $splitter->split($sql);

ok (
    @statements == 2,
    'correct number of statements - instance method'
);

chomp $sql;

ok (
    join('', @statements) eq $clean_sql,
    'code successfully rebuilt - instance method'
);
