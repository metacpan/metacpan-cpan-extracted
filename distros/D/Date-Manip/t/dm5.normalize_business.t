#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DM5 :: Normalize (after business day)';
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

sub Test_Normalize {
  my(@args)=@_;
  my($tmp,$err);
  $tmp=ParseDateDelta(@args);
  $tmp=DateCalc("today","+ 1 business days",\$err);
  $tmp=ParseDateDelta(@args);
  return $tmp;
}

$tests="

+0:0:0:0:9:9:1 => +0:0:0:0:9:9:1

";

$t->tests(func  => \&Test_Normalize,
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
