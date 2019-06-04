#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","1997-03-08-12:30:00,America/New_York");
$obj->config("language","English","dateformat","nonUS");

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

my $tests="

'TODAY' => '1997030800:00:00'

'today' => '1997030800:00:00'

'now' => '1997030812:30:00'

'tomorrow' => '1997030900:00:00'

'yesterday' => '1997030700:00:00'

'Jun, twenty-seventh 1977 16:00:00' => 1977062716:00:00

04.12.1999 => 1999120400:00:00

'May 2 2012' => 2012050200:00:00

'2 May 2012' => 2012050200:00:00

'2 may 2012' => 2012050200:00:00

'2 MAY 2012' => 2012050200:00:00

31/12/2000 => 2000123100:00:00

'3 Sep 1975' => 1975090300:00:00

'27 Oct 2001' => 2001102700:00:00

'September, 1st 1980' => 1980090100:00:00

'December 20, 1999' => 1999122000:00:00

'20 July 1987 12:32:20' => 1987072012:32:20

'23:37:20 Jun 1st 1987' => 1987060123:37:20

'20/12/01 17:27:08' => 2001122017:27:08

'20/12/01 at 17:27:08' => 2001122017:27:08

'17:27:08 20/12/01' => 2001122017:27:08

'4 October 1975 at 4 pm' => 1975100416:00:00

'now PST' => 1997030809:30:00

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
