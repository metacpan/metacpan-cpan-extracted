#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'BigIP::GTM::ParseConfig' ) || print "Bail out!\n";
}

diag( "Testing BigIP::GTM::ParseConfig $BigIP::GTM::ParseConfig::VERSION, Perl $], $^X" );
