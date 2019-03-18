#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('App::ValidateSortCode')         || print "Bail out!\n";
    use_ok('App::ValidateSortCode::Option') || print "Bail out!\n";
}

diag( "Testing App::ValidateSortCode $App::ValidateSortCode::VERSION, Perl $], $^X" );
