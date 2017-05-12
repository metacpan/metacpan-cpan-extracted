#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Data::Fetch') || print 'Bail out!';
}

require_ok('Data::Fetch') || print 'Bail out!';

diag( "Testing Data::Fetch $Data::Fetch::VERSION, Perl $], $^X" );
