#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'date :: _init_args';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  my $obj = new Date::Manip::Date(@test);
  return $obj->err();
}

$tests="

2001-01-01-00:00:00        => __blank__

2001-01-01-00:00:00 nodow  => __blank__

";

$t->tests(func  => \&test,
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
