#!perl -T
use strict;
use warnings;

use Test::More;

plan tests => 4;

BEGIN { use_ok('DBIx::Fast'); }
BEGIN { use_ok('DBIx::Connector'); }
BEGIN { use_ok('SQL::Abstract'); }
BEGIN { use_ok('Moo'); }

diag( "Testing DBIx::Fast $DBIx::Fast::VERSION, Perl $], $^X" );
