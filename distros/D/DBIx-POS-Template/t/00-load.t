#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::POS::Template' ) || print "Bail out!\n";
}

diag( "Testing DBIx::POS::Template $DBIx::POS::Template::VERSION, Perl $], $^X" );
