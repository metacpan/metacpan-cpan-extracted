#!/usr/bin/perl -w

use utf8;
use Test::Inter;
$t = new Test::Inter 'date :: parse (Turkish)';
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
$obj->config("forcedate","1997-03-08-12:30:00,America/New_York");
$obj->config("language","Turkish","dateformat","nonUS");

$tests="

'Bugün' => '1997030800:00:00'

'şimdi' => '1997030812:30:00'

'bugün' => '1997030800:00:00'

'yarın' => '1997030900:00:00'

'dün' => '1997030700:00:00'

'DÜN' => '1997030700:00:00'

";

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
