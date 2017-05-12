#!perl -w
use strict;
use Test::More;
use Data::Dumper;

use DBIx::RunSQL;

plan tests => 1;
my @statements = DBIx::RunSQL->split_sql(<<'SQL');
DROP TABLE IF EXISTS player1; 
DROP TABLE IF EXISTS player2;

SQL

is scalar( @statements ), 2, "Trailing whitespace is allowed in statements"
    or diag Dumper \@statements;
