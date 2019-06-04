#!/usr/bin/perl

binmode(STDOUT,':utf8');
binmode(STDERR,':utf8');
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

my $tests="

'\xd1\xc5\xc3\xce\xc4\xcd\xdf' => '1997030800:00:00'

'\xe7\xe0\xe2\xf2\xf0\xe0' => '1997030900:00:00'

'2 \xcc\xc0\xdf 2012' => 2012050200:00:00

'2 \xec\xe0\xff 2012' => 2012050200:00:00

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
