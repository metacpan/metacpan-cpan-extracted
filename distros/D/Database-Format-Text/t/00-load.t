#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Database::Format::Text' ) || print "Bail out!\n";
}

diag( "Testing Database::Format::Text $Database::Format::Text::VERSION, Perl $], $^X" );
