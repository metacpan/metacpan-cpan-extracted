#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:30:45,America/New_York");
$obj->config("language","Italian","dateformat","nonUS");

sub test {
   my(@test)=@_;
   if ($test[0] eq "config") {
      shift(@test);
      $obj->config(@test);
      return ();
   }

   my $err = $obj->parse(@test);
   if ($err) {
      return $obj->err();
   } else {
      my $d1 = $obj->value();
      return $d1;
   }
}


my $tests=qq{

'Lunedi Mag 3, 2010'  => 2010050300:00:00

'Luned\xEC Mag 3, 2010'  => 2010050300:00:00

'Lunedì Mag 3, 2010'  => 2010050300:00:00

'primo lunedì di marzo 2020' => 2020030200:00:00

'seconda domenica di maggio 2021' => 2021050900:00:00

'giovedì della quindicesima settimana del 2020' => 2020040900:00:00

'2a domenica di aprile 2020' => 2020041200:00:00

'1o lunedì del 2020' => 2020010600:00:00

oggi => "2000012100:00:00"

domani => "2000012200:00:00"

ieri => "2000012000:00:00"

adesso => "2000012112:30:45"

dopodomani => "2000012300:00:00"

l'altroieri => "2000011900:00:00"

'domenica scorsa' => "2000011600:00:00"

'giovedì scorso' => "2000012000:00:00"

'sabato  prossimo' => "2000012200:00:00"

'domenica prossima' => "2000012300:00:00"

'ultimo sabato di novembre 2020' => 2020112800:00:00

'ultima domenica di novembre 2020' => 2020112900:00:00

'fra una settimana di sabato' => "2000012912:30:45"

'fra 1 settimana di martedì' => "2000012512:30:45"

'una settimana fa di mercoledì' => "2000011212:30:45"

};

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
