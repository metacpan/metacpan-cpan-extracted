#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'DBIx::Schema::DSL';
}

diag "Testing DBIx::Schema::DSL/$DBIx::Schema::DSL::VERSION";
