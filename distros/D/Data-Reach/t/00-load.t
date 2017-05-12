#!perl
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Reach' ) or BAIL_OUT "compilation error";
}

diag( "Testing Data::Reach $Data::Reach::VERSION, Perl $], $^X" );
