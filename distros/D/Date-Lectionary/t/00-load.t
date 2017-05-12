#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok('Date::Lectionary')       || print "Bail out!\n";
    use_ok('Date::Lectionary::Year') || print "Bail out!\n";
    use_ok('Date::Lectionary::Day')  || print "Bail out!\n";
}

diag("Testing Date::Lectionary $Date::Lectionary::VERSION, Perl $], $^X");
