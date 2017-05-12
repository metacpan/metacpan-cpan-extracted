#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Nopaste::Service::PastebinComAPI' ) || print "Bail out!\n";
}

diag( "Testing App::Nopaste::Service::PastebinComAPI $App::Nopaste::Service::PastebinComAPI::VERSION, Perl $], $^X" );
