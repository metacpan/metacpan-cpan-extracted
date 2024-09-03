#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

if ( $@ ) {
    plan skip_all => "DBD::SQLite 1.74";
}

plan tests => 4;

BEGIN { use_ok('DBIx::Fast'); }
BEGIN { use_ok('DBIx::Connector'); }
BEGIN { use_ok('SQL::Abstract'); }
BEGIN { use_ok('Moo'); }

diag( "Testing DBIx::Fast $DBIx::Fast::VERSION, Perl $], $^X" );
