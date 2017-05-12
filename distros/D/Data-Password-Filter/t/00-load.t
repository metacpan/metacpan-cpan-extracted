#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('Data::Password::Filter')         || print "Bail out!";
    use_ok('Data::Password::Filter::Params') || print "Bail out!";
}

diag( "Testing Data::Password::Filter $Data::Password::Filter::VERSION, Perl $], $^X" );
