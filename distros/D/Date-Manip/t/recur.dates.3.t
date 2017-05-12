#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'recur :: unmodified date range';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  ($recur,$arg1,$arg2) = @_;
  $err = $obj->parse($recur);
  if ($err) {
     return $obj->err();
  } else {
     $start = undef;
     $end   = undef;
     if (defined($arg1)) {
        $start = $obj->new_date();
        $start->parse($arg1);
     }
     if (defined($arg2)) {
        $end = $obj->new_date();
        $end->parse($arg2);
     }
     @dates = $obj->dates($start,$end);
     @ret   = ();
     foreach my $d (@dates) {
        $v = $d->value();
        push(@ret,$v);
     }
     return @ret;
  }
}

$obj = new Date::Manip::Recur;
$obj->config("forcedate","2000-01-21-00:00:00,America/New_York");

$tests="

1*1:0:1:0:0:0***2004010100:00:00*2007123123:59:59
   =>
   2004010100:00:00
   2005010100:00:00
   2006010100:00:00
   2007010100:00:00

1*1:0:1:0:0:0*dwd**2004010100:00:00*2007123123:59:59
   =>
   2004010100:00:00
   2004123100:00:00
   2006010200:00:00
   2007010100:00:00

1*1:0:1:0:0:0*dwd**2005010100:00:00*2005123123:59:59
   =>

1*1:0:1:0:0:0*dwd**2005010100:00:00*2005123123:59:59*1
   =>
   2004123100:00:00

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
