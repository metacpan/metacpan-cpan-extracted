#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::HTTP::ConditionalRequest' )
    || print "Bail out!\n";
}

diag( "Testing"
    . " Dancer2::Plugin::HTTP::ConditionalRequest "
    . "$Dancer2::Plugin::HTTP::ConditionalRequest::VERSION, "
    . "Perl $], $^X"
);
