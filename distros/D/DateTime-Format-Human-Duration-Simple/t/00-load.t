#!/usr/bin/env perl
#
use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    use_ok( 'DateTime::Format::Human::Duration::Simple' ) || print "Bail out!\n";
}

diag( "Testing DateTime::Format::Human::Duration::Simple $DateTime::Format::Human::Duration::Simple::VERSION, Perl $], $^X" );

done_testing;
