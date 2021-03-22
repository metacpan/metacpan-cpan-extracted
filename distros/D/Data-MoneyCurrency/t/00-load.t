use strict;
use warnings;
use Test::More;
use lib 'lib';

plan tests => 1;

BEGIN {
    use_ok('Data::MoneyCurrency') || print "Bail out!\n";
}

