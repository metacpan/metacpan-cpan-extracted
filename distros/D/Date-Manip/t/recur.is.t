#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

my $obj = new Date::Manip::Recur;

sub test {
   my ($test)=@_;
   if ($test eq 'date') {
      return $obj->is_date();
   } elsif ($test eq 'delta') {
      return $obj->is_delta();
   } elsif ($test eq 'recur') {
      return $obj->is_recur();
   }
}

my $tests="

date => 0

delta => 0

recur => 1

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
