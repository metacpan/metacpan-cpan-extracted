#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

if ( eval("use Test::Exception; 1") ) {
    plan tests => 2;
}
else {
    plan skip_all => 'No Test::Exception installed'
}

use BSON qw/encode decode/;

dies_ok( sub{ decode("something") }, "Incorrect BSON");
dies_ok( sub{ decode("\5\0\0\0 1234\0")  }, "Unsupported type" )

