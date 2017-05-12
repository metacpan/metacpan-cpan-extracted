#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'delta :: is';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  ($test)=@_;
  if ($test eq 'date') {
     return $obj->is_date();
  } elsif ($test eq 'delta') {
     return $obj->is_delta();
  } elsif ($test eq 'recur') {
     return $obj->is_recur();
  }
}

$obj = new Date::Manip::Delta;

$tests="

date => 0

delta => 1

recur => 0

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
