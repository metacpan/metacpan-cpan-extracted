#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Dochazka::WWW' ) || print "Bail out!\n";
}

diag( "Testing App::Dochazka::WWW $App::Dochazka::WWW::VERSION, Perl $], $^X" );
