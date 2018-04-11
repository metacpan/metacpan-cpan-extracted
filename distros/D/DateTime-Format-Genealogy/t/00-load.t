#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('DateTime::Format::Genealogy') || print 'Bail out!';
}

require_ok('DateTime::Format::Genealogy') || print 'Bail out!';

diag( "Testing DateTime::Format::Genealogy $DateTime::Format::Genealogy::VERSION, Perl $], $^X" );
