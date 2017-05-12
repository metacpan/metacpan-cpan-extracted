#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'date :: list_holidays (new years)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;

  if ($test[0] eq 'configfile') {
     $obj->config('EraseHolidays',1,
                  'ConfigFile',"$testdir/$test[1]");
     return ();
  }

  @ret = ();
  ($y0,$y1) = @test;
  foreach my $y ($y0..$y1) {
    @date = $obj->list_holidays($y);
    foreach my $date (@date) {
       my $d = $date->value();
       push(@ret,$d);
    }
  }
  return @ret;
}

$obj = new Date::Manip::Date;

$obj->config("forcedate","2000-01-01-00:00:00,America/New_York");

$tests="

configfile New_Years.1.cnf =>

2000 2015 =>
   2000010100:00:00
   2001010100:00:00
   2002010100:00:00
   2003010100:00:00
   2004010100:00:00
   2005010100:00:00
   2006010100:00:00
   2007010100:00:00
   2008010100:00:00
   2009010100:00:00
   2010010100:00:00
   2011010100:00:00
   2012010100:00:00
   2013010100:00:00
   2014010100:00:00
   2015010100:00:00

configfile New_Years.2.cnf =>

2000 2015 =>
   2001010100:00:00
   2002010100:00:00
   2003010100:00:00
   2004010100:00:00
   2004123100:00:00
   2006010200:00:00
   2007010100:00:00
   2008010100:00:00
   2009010100:00:00
   2010010100:00:00
   2010123100:00:00
   2012010200:00:00
   2013010100:00:00
   2014010100:00:00
   2015010100:00:00

configfile New_Years.3.cnf =>

2000 2015 =>
   2000010100:00:00
   2001010100:00:00
   2002010100:00:00
   2003010100:00:00
   2004010100:00:00
   2005010100:00:00
   2006010200:00:00
   2007010100:00:00
   2008010100:00:00
   2009010100:00:00
   2010010100:00:00
   2011010100:00:00
   2012010200:00:00
   2013010100:00:00
   2014010100:00:00
   2015010100:00:00

configfile New_Years.4.cnf =>

2000 2015 =>
   2000010100:00:00
   2001010100:00:00
   2002010100:00:00
   2003010100:00:00
   2004010100:00:00
   2005010100:00:00
   2006010200:00:00
   2007010100:00:00
   2008010100:00:00
   2009010100:00:00
   2010010100:00:00
   2011010100:00:00
   2012010200:00:00
   2013010100:00:00
   2014010100:00:00
   2015010100:00:00

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
