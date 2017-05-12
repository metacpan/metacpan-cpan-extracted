#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('Address::PostCode::UserAgent')            || print "Bail out!\n";
    use_ok('Address::PostCode::UserAgent::Exception') || print "Bail out!\n";
}

diag( "Testing Address::PostCode::UserAgent $Address::PostCode::UserAgent::VERSION, Perl $], $^X" );
