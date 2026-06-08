#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('DBIx::Class::Schema::GraphQL') || print "Bail out!\n";
}

diag( "Testing DBIx::Class::Schema::GraphQL $DBIx::Class::Schema::GraphQL::VERSION, Perl $], $^X" );
