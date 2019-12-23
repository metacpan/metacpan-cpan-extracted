#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'BigIP::LTM::ParseConfig' ) || print "Bail out!\n";
}

diag( "Testing BigIP::LTM::ParseConfig $BigIP::LTM::ParseConfig::VERSION, Perl $], $^X" );
