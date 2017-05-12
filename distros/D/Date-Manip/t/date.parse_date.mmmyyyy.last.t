#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'date :: parse_date (format_mmmyyyy=last)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  if ($test[0] eq "config") {
     shift(@test);
     $obj->config(@test);
     return ();
  }

  my $err = $obj->parse_date(@test);
  if ($err) {
     return $obj->err();
  } else {
     $d1 = $obj->value();
     return($d1);
  }
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-00:00:00,America/New_York",
             "format_mmmyyyy","last",
             "yytoyyyy","c20");

$tests="

'Jun1925'   => '1925063000:00:00'

'Jun/1925'  => '1925063000:00:00'

'1925/Jun'  => '1925063000:00:00'

'1925Jun'   => '1925063000:00:00'

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
