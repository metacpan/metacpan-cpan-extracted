#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN {
    use_ok('Address::PostCode::Australia')         || print "Bail out!\n";
    use_ok('Address::PostCode::Australia::Place')  || print "Bail out!\n";
    use_ok('Address::PostCode::Australia::Params') || print "Bail out!\n";
}

diag( "Testing Address::PostCode::Australia $Address::PostCode::Australia::VERSION, Perl $], $^X" );
