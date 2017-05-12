#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::RS14_PP' );
}

diag( "Tested Crypt::RS14_PP $Crypt::RS14_PP::VERSION, Perl $], $^X" );
