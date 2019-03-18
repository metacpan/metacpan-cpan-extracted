#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('App::ValidateBankAccount')         || print "Bail out!\n";
    use_ok('App::ValidateBankAccount::Option') || print "Bail out!\n";
}

diag( "Testing App::ValidateBankAccount $App::ValidateBankAccount::VERSION, Perl $], $^X" );
