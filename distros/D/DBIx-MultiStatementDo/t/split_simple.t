#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::MultiStatementDo;

use Test::More tests => 4;

my @statements_w_placeholders;
my @statements_wo_placeholders;

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

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '' );
my $splitter_options = {
    keep_terminators      => 1,
    keep_extra_spaces     => 1,
    keep_empty_statements => 1
};

my $sql_splitter = DBIx::MultiStatementDo->new(
    dbh => $dbh, splitter_options => $splitter_options
);

@statements_w_placeholders
    = @{ ( $sql_splitter->split_with_placeholders($sql) )[0] };

ok (
    @statements_w_placeholders == 3,
    'correct number of statements - instance method all set'
);

is (
    join('', @statements_w_placeholders), $sql,
    'code successfully rebuilt - instance method all set'
);

@statements_wo_placeholders = $sql_splitter->new(
    dbh => $dbh, splitter_options => $splitter_options
)->split($sql);

cmp_ok (
    scalar(@statements_wo_placeholders), '==', 3,
    'number of statements returned by split'
);

is_deeply(
    \@statements_w_placeholders, \@statements_wo_placeholders,
    'statements w/ and w/o placeholders match'
)

