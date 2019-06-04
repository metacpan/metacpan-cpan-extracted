#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

our $obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:30:45,America/New_York");

sub test {
   my($format,$string,@g) = @_;
   my($err,%m) = $obj->parse_format($format,$string);
   if ($err) {
      return $err;
   }
   my $v = $obj->value();
   my(@ret) = ($v);
   foreach my $g (@g) {
      push(@ret,$m{$g});
   }
   return @ret;
}

my $tests=q{

'(?<PRE>.*?)%Y-%m-%d(?<POST>.*)'
'before 2014-01-25 after'
PRE
POST
   =>
   2014012500:00:00
   'before '
   ' after'

};

$::ti->tests(func  => \&test,
             tests => $tests);
$::ti->done_testing();

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
