#!perl -T
use 5.8.0;
use strict;
use warnings;
use Test::More;

our $VERSION='0.06';

plan tests => 1;

BEGIN {
    use_ok( 'Data::Random::Structure::UTF8' ) || print "Bail out!\n";
}

diag( "Testing Data::Random::Structure::UTF8 $Data::Random::Structure::UTF8::VERSION, Perl $], $^X" );
