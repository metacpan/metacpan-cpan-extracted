#!/usr/bin/perl -w

use Test::More;
use Test::Inter;
binmode(STDOUT,':utf8');
binmode(STDERR,':utf8');

$t = new Test::Inter 'date :: parse (Russian, cp1251)';
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
$obj->config("language","Russian","dateformat","nonUS");

$tests="

'\xd1\xc5\xc3\xce\xc4\xcd\xdf' => '1997030800:00:00'

'\xe7\xe0\xe2\xf2\xf0\xe0' => '1997030900:00:00'

'2 \xcc\xc0\xdf 2012' => 2012050200:00:00

'2 \xec\xe0\xff 2012' => 2012050200:00:00

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
