#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Chandra::Markdown' ) || print "Bail out!\n";
}

diag( "Testing Chandra::Markdown $Chandra::Markdown::VERSION, Perl $], $^X" );
