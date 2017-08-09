#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('App::calendr')         || print "Bail out!\n";
    use_ok('App::calendr::Option') || print "Bail out!\n";
}

diag( "Testing App::calendr $App::calendr::VERSION, Perl $], $^X" );
