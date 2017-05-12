#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 7;

BEGIN {
    use_ok('Date::Exception')                    || print "Bail out!\n";
    use_ok('Date::Exception::InvalidDay')        || print "Bail out!\n";
    use_ok('Date::Exception::InvalidDayCount')   || print "Bail out!\n";
    use_ok('Date::Exception::InvalidMonth')      || print "Bail out!\n";
    use_ok('Date::Exception::InvalidMonthCount') || print "Bail out!\n";
    use_ok('Date::Exception::InvalidYear')       || print "Bail out!\n";
    use_ok('Date::Exception::InvalidYearCount')  || print "Bail out!\n";
}

diag( "Testing Date::Exception $Date::Exception::VERSION, Perl $], $^X" );
