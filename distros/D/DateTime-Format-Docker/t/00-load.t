#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DateTime::Format::Docker' ) || print "Bail out!\n";
}

diag( "Testing DateTime::Format::Docker $DateTime::Format::Docker::VERSION, Perl $], $^X" );
