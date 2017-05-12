#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 5;

BEGIN {
    use_ok('CPANTS::Kwalitee::Report')               || print "Bail out!\n";
    use_ok('CPANTS::Kwalitee::Report::Score')        || print "Bail out!\n";
    use_ok('CPANTS::Kwalitee::Report::Generator')    || print "Bail out!\n";
    use_ok('CPANTS::Kwalitee::Report::Indicator')    || print "Bail out!\n";
    use_ok('CPANTS::Kwalitee::Report::Distribution') || print "Bail out!\n";
}

diag( "Testing CPANTS::Kwalitee::Report $CPANTS::Kwalitee::Report::VERSION, Perl $], $^X" );
