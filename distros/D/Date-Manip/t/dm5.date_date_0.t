#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DM5 :: DateCalc (date,date,exact)';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;
if ($] < 5.010  ||  $ENV{'DATE_MANIP_TEST_DM5'}) {
   $t->feature("TEST_DM5",1);
}

$t->skip_all('Date::Manip 5.xx tests ignored (set DATE_MANIP_TEST_DM5 to test)',
             'TEST_DM5');

Date_Init("TZ=EST");

$tests="

'Jan 1 1996 12:00:00' 'Jan 1 1996 14:30:30' 0 => +0:0:0:0:2:30:30

'Jan 1 1996 14:30:30' 'Jan 1 1996 12:00:00' 0 => -0:0:0:0:2:30:30

'Jan 1 1996 12:00:00' 'Jan 2 1996 14:30:30' 0 => +0:0:0:1:2:30:30

'Jan 2 1996 14:30:30' 'Jan 1 1996 12:00:00' 0 => -0:0:0:1:2:30:30

'Jan 1 1996 12:00:00' 'Jan 2 1996 10:30:30' 0 => +0:0:0:0:22:30:30

'Jan 2 1996 10:30:30' 'Jan 1 1996 12:00:00' 0 => -0:0:0:0:22:30:30

'Jan 1 1996 12:00:00' 'Jan 2 1997 10:30:30' 0 => +0:0:52:2:22:30:30

'Jan 2 1997 10:30:30' 'Jan 1 1996 12:00:00' 0 => -0:0:52:2:22:30:30

'Jan 1st 1997 00:00:01' 'Feb 1st 1997 00:00:00' 0 => +0:0:4:2:23:59:59

'Jan 1st 1997 00:00:01' 'Mar 1st 1997 00:00:00' 0 => +0:0:8:2:23:59:59

'Jan 1st 1997 00:00:01' 'Mar 1st 1998 00:00:00' 0 => +0:0:60:3:23:59:59

";

$t->tests(func  => \&DateCalc,
          tests => $tests);
$t->done_testing();

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:
