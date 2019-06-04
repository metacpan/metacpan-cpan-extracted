#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

my $obj = new Date::Manip::Recur;
$obj->config("forcedate","2000-01-21-00:00:00,America/New_York");

sub test {
   my($recur,$arg1,$arg2) = @_;
   my $err = $obj->parse($recur);
   if ($err) {
      return $obj->err();
   } else {
      my $start = undef;
      my $end   = undef;
      if (defined($arg1)) {
         $start = $obj->new_date();
         $start->parse($arg1);
      }
      if (defined($arg2)) {
         $end = $obj->new_date();
         $end->parse($arg2);
      }
      my @dates = $obj->dates($start,$end);
      $err   = $obj->err();
      return $err  if ($err);
      my @ret   = ();
      foreach my $d (@dates) {
         my $v = $d->value();
         push(@ret,$v);
      }
      return @ret;
   }
}

my $tests="

1:2:3:4*12:30:00**2000010500:00:00*2000010100:00:00*2003010100:00:00
   =>
   2000010512:30:00
   2001033012:30:00
   2002062412:30:00

1:2:3:4*12:30:00**2000010500:00:00*2000010100:00:00*2003010100:00:00
2001010100:00:00
   =>
   2001033012:30:00
   2002062412:30:00

1:2:3:4*12:30:00**2000010500:00:00*2000010100:00:00*2003010100:00:00
__undef__
2001123100:00:00
   =>
   2000010512:30:00
   2001033012:30:00

1:2:3:4*12:30:00**2000010500:00:00*2000010100:00:00*2003010100:00:00
2001010100:00:00
2001123100:00:00
   =>
   2001033012:30:00

1:2:3:4*12:30:00**2000010500:00:00
2000010100:00:00
2003010100:00:00
   =>
   2000010512:30:00
   2001033012:30:00
   2002062412:30:00

### Test new years definition

1*1:0:1:0:0:0*dwd**1999060100:00:00*2006060100:00:00
   =>
   1999123100:00:00
   2001010100:00:00
   2002010100:00:00
   2003010100:00:00
   2004010100:00:00
   2004123100:00:00
   2006010200:00:00

# Test recur with no frequency

*2013:1:0:20:10:11:12***2013010100:00:00*2013013012:00:00
   =>
   2013012010:11:12

*2013:1:0:20:10:11:12***2013012100:00:00*2013013012:00:00
   =>

# Test overriding dates with no frequency

*1990-1995:12:0:1:0:0:0
   =>
   1990120100:00:00
   1991120100:00:00
   1992120100:00:00
   1993120100:00:00
   1994120100:00:00
   1995120100:00:00

*1990-1995:12:0:1:0:0:0
1992-01-01
1994-12-31
   =>
   1992120100:00:00
   1993120100:00:00
   1994120100:00:00

";

$::ti->tests(func  => \&test,
             tests => $tests);
$::ti->done_testing();

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
