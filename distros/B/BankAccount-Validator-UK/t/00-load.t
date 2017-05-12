#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('BankAccount::Validator::UK')       || print "Bail out!\n";
    use_ok('BankAccount::Validator::UK::Rule') || print "Bail out!\n";
}

diag( "Testing BankAccount::Validator::UK $BankAccount::Validator::UK::VERSION, Perl $], $^X" );
