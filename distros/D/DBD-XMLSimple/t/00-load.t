#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('DBD::XMLSimple') || print 'Bail out!';
}

require_ok('DBD::XMLSimple') || print 'Bail out!';

diag( "Testing DBD::XMLSimple $DBD::XMLSimple::VERSION, Perl $], $^X" );
