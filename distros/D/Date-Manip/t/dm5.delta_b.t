#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DM5 :: Delta (signs)';
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
Date_Init("DeltaSigns=1");

$tests="

1:2:3:4:5:6:7  => +1:+2:+3:+4:+5:+6:+7

-1:2:3:4:5:6:7 => -1:-2:-3:-4:-5:-6:-7

35x            => ''

+0             => +0:+0:+0:+0:+0:+0:+0

";

$t->tests(func  => \&ParseDateDelta,
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
