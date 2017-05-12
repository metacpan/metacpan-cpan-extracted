#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 6;

BEGIN {
    use_ok('Data::Money')                                       || print "Bail out!\n";
    use_ok('Data::Money::BaseException')                        || print "Bail out!\n";
    use_ok('Data::Money::BaseException::ExcessivePrecision')    || print "Bail out!\n";
    use_ok('Data::Money::BaseException::InvalidCurrencyCode')   || print "Bail out!\n";
    use_ok('Data::Money::BaseException::InvalidCurrencyFormat') || print "Bail out!\n";
    use_ok('Data::Money::BaseException::MismatchCurrencyType')  || print "Bail out!\n";
}

diag("Testing Data::Money $Data::Money::VERSION, Perl $], $^X");
