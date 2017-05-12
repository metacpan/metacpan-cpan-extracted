#!/usr/bin/perl -w

use utf8;
use Test::Inter;
$t = new Test::Inter 'date :: parse (Romanian)';
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

  my $err = $obj->parse(@test);
  if ($err) {
     return $obj->err();
  } else {
     $d1 = $obj->value();
     return $d1;
  }
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:30:45,America/New_York");
$obj->config("language","Romanian","dateformat","nonUS");

$tests="

'marți iunie 8, 2010'   => 2010060800:00:00

'marti iunie 8, 2010'   => 2010060800:00:00

'marþi iunie 8, 2010'   => 2010060800:00:00

'mar\xFEi iunie 8, 2010'   => 2010060800:00:00

'sâmbătă iunie 12, 2010'   => 2010061200:00:00

'duminică iunie 13, 2010'   => 2010061300:00:00

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
