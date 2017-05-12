#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Schema::Versioned::Inline' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::Schema::Versioned::Inline $DBIx::Class::Schema::Versioned::Inline::VERSION, Perl $], $^X" );
