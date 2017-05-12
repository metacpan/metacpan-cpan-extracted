#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Nopaste::Service::PastebinCa' ) || print "Bail out!\n";
}

diag( "Testing App::Nopaste::Service::PastebinCa $App::Nopaste::Service::PastebinCa::VERSION, Perl $], $^X" );
