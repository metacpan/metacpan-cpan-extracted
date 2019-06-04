#!/usr/bin/perl

use utf8;
use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","1997-03-08-12:30:00,America/New_York");
$obj->config("language","Russian","dateformat","nonUS");

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

my($currS,$currMN,$currH,$currD,$currM,$currY)=("00","30","12","08","03","1997");

my $now           = "${currY}${currM}${currD}${currH}:${currMN}:${currS}";
my $today         = "${currY}${currM}${currD}00:00:00";
my $yesterdaydate = "${currY}${currM}". ${currD}-1;
my $tomorrowdate  = "${currY}${currM}". ${currD}+1;
my $yesterday     = "${yesterdaydate}00:00:00";
my $tomorrow      = "${tomorrowdate}00:00:00";

my $tests="

'СЕГОДНЯ' => $today

'сегодня' => $today

'сейчас' => $now

'завтра' => $tomorrow

'вчера' => $yesterday

'двадцать седьмого июня 1977 16:00:00' => 1977062716:00:00

04.12.1999 => 1999120400:00:00

'2 мая 2012' => 2012050200:00:00

'2 май 2012' => 2012050200:00:00

31/12/2000 => 2000123100:00:00

'3 сен 1975' => 1975090300:00:00

'27 окт 2001' => 2001102700:00:00

'первое сентября 1980' => 1980090100:00:00

'декабрь 20, 1999' => 1999122000:00:00

'20 июля 1987 12:32:20' => 1987072012:32:20

'23:37:20 первое июня 1987' => 1987060123:37:20

'20/12/01 17:27:08' => 2001122017:27:08

'20/12/01 в 17:27:08' => 2001122017:27:08

'20/12/01 в 17ч27м08с00' => 2001122017:27:08

'17:27:08 20/12/01' => 2001122017:27:08

'4 октября 1975 4ч00 дня' => 1975100416:00:00

#'4 октября 1975 4 часа дня' => 1975100416:00:00

#'4 октября 1975 в 4 часа дня' => 1975100416:00:00
";

$::ti->tests(func  => \&test,
             tests => $tests);
$::ti->done_testing();

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
