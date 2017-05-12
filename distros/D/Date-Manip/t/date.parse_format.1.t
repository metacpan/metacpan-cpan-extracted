#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'date :: parse_format';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  ($format,$string,@g) = @_;
  ($err,%m) = $obj->parse_format($format,$string);
  if ($err) {
     return $err;
  }
  $v = $obj->value();
  push(@ret,$v);
  foreach my $g (@g) {
    push(@ret,$m{$g});
  }
  return @ret;
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:30:45,America/New_York");

$tests=q{

'(?<PRE>.*?)%Y-%m-%d(?<POST>.*)'
'before 2014-01-25 after'
PRE
POST
   =>
   2014012500:00:00
   'before '
   ' after'

};

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();

1;

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
