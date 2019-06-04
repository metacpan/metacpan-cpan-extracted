#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

my $obj = new Date::Manip::Delta;
$obj->config("forcedate","now,America/New_York");

sub test {
   my(@test)=@_;
   my $o = $obj->new_delta();
   my $err = $o->set(@test);
   if ($err) {
      return $o->err();
   } else {
      my @val = $o->value();
      return @val;
   }
}

my $tests="

{ delta [ 0 0 0 0 1 20 30 ] }                                  => 0 0 0 0 1 20 30

{ delta [ 0 0 0 0 1 20 30 ] nonorm 1 }                         => 0 0 0 0 1 20 30

{ delta [ 0 0 0 0 1 20 30 ] mode business  type exact }        => 0 0 0 0 1 20 30

{ delta [ 0 0 0 0 1 20 30 ] mode business  type semi }         => 0 0 0 0 1 20 30

{ delta [ 0 0 0 0 1 20 30 ] mode business  type approx }       => 0 0 0 0 1 20 30

{ delta [ 0 0 0 0 1 20 30 ] mode business  type estimated }    => 0 0 0 0 1 20 30

{ delta [ 0 0 0 0 1 20 30 ] mode standard  type exact }        => 0 0 0 0 1 20 30

{ delta [ 0 0 0 0 1 20 30 ] mode standard  type semi }         => 0 0 0 0 1 20 30

{ delta [ 0 0 0 0 1 20 30 ] mode standard  type approx }       => 0 0 0 0 1 20 30

{ delta [ 0 0 0 0 1 20 30 ] mode standard  type estimated }    => 0 0 0 0 1 20 30

#

{ delta [ 0 0 0 0 10 20 30 ] }                                 => 0 0 0 0 10 20 30

{ delta [ 0 0 0 0 10 20 30 ] nonorm 1 }                        => 0 0 0 0 10 20 30

{ delta [ 0 0 0 0 10 20 30 ] mode business  type exact }       => 0 0 0 1 1 20 30

{ delta [ 0 0 0 0 10 20 30 ] mode business  type semi }        => 0 0 0 1 1 20 30

{ delta [ 0 0 0 0 10 20 30 ] mode business  type approx }      => 0 0 0 1 1 20 30

{ delta [ 0 0 0 0 10 20 30 ] mode business  type estimated }   => 0 0 0 1 1 20 30

{ delta [ 0 0 0 0 10 20 30 ] mode standard  type exact }       => 0 0 0 0 10 20 30

{ delta [ 0 0 0 0 10 20 30 ] mode standard  type semi }        => 0 0 0 0 10 20 30

{ delta [ 0 0 0 0 10 20 30 ] mode standard  type approx }      => 0 0 0 0 10 20 30

{ delta [ 0 0 0 0 10 20 30 ] mode standard  type estimated }   => 0 0 0 0 10 20 30

#

{ delta [ 0 0 0 0 75 20 30 ] }                                 => 0 0 0 0 75 20 30

{ delta [ 0 0 0 0 75 20 30 ] nonorm 1 }                        => 0 0 0 0 75 20 30

{ delta [ 0 0 0 0 75 20 30 ] mode business  type exact }       => 0 0 0 8 3 20 30

{ delta [ 0 0 0 0 75 20 30 ] mode business  type semi }        => 0 0 1 3 3 20 30

{ delta [ 0 0 0 0 75 20 30 ] mode business  type approx }      => 0 0 1 3 3 20 30

{ delta [ 0 0 0 0 75 20 30 ] mode business  type estimated }   => 0 0 1 3 3 20 30

{ delta [ 0 0 0 0 75 20 30 ] mode standard  type exact }       => 0 0 0 0 75 20 30

{ delta [ 0 0 0 0 75 20 30 ] mode standard  type semi }        => 0 0 0 3 3 20 30

{ delta [ 0 0 0 0 75 20 30 ] mode standard  type approx }      => 0 0 0 3 3 20 30

{ delta [ 0 0 0 0 75 20 30 ] mode standard  type estimated }   => 0 0 0 3 3 20 30

#

{ delta [ 0 0 0 4 1 20 30 ] }                                  => 0 0 0 4 1 20 30

{ delta [ 0 0 0 4 1 20 30 ] nonorm 1 }                         => 0 0 0 4 1 20 30

{ delta [ 0 0 0 4 1 20 30 ] mode business  type exact }        => 0 0 0 4 1 20 30

{ delta [ 0 0 0 4 1 20 30 ] mode business  type semi }         => 0 0 0 4 1 20 30

{ delta [ 0 0 0 4 1 20 30 ] mode business  type approx }       => 0 0 0 4 1 20 30

{ delta [ 0 0 0 4 1 20 30 ] mode business  type estimated }    => 0 0 0 4 1 20 30

{ delta [ 0 0 0 4 1 20 30 ] mode standard  type exact }
   =>
   '[set] Type must be semi/approx/estimated'

{ delta [ 0 0 0 4 1 20 30 ] mode standard  type semi }         => 0 0 0 4 1 20 30

{ delta [ 0 0 0 4 1 20 30 ] mode standard  type approx }       => 0 0 0 4 1 20 30

{ delta [ 0 0 0 4 1 20 30 ] mode standard  type estimated }    => 0 0 0 4 1 20 30

#

{ delta [ 0 0 0 4 10 20 30 ] }                                 => 0 0 0 4 10 20 30

{ delta [ 0 0 0 4 10 20 30 ] nonorm 1 }                        => 0 0 0 4 10 20 30

{ delta [ 0 0 0 4 10 20 30 ] mode business  type exact }       => 0 0 0 5 1 20 30

{ delta [ 0 0 0 4 10 20 30 ] mode business  type semi }        => 0 0 1 0 1 20 30

{ delta [ 0 0 0 4 10 20 30 ] mode business  type approx }      => 0 0 1 0 1 20 30

{ delta [ 0 0 0 4 10 20 30 ] mode business  type estimated }   => 0 0 1 0 1 20 30

{ delta [ 0 0 0 4 10 20 30 ] mode standard  type exact }
   =>
   '[set] Type must be semi/approx/estimated'

{ delta [ 0 0 0 4 10 20 30 ] mode standard  type semi }        => 0 0 0 4 10 20 30

{ delta [ 0 0 0 4 10 20 30 ] mode standard  type approx }      => 0 0 0 4 10 20 30

{ delta [ 0 0 0 4 10 20 30 ] mode standard  type estimated }   => 0 0 0 4 10 20 30

#

{ delta [ 0 0 2 4 10 20 30 ] }                                 => 0 0 2 4 10 20 30

{ delta [ 0 0 2 4 10 20 30 ] nonorm 1 }                        => 0 0 2 4 10 20 30

{ delta [ 0 0 2 4 10 20 30 ] mode business  type exact }
   =>
   '[set] Type must be semi/approx/estimated'

{ delta [ 0 0 2 4 10 20 30 ] mode business  type semi }        => 0 0 3 0 1 20 30

{ delta [ 0 0 2 4 10 20 30 ] mode business  type approx }      => 0 0 3 0 1 20 30

{ delta [ 0 0 2 4 10 20 30 ] mode business  type estimated }   => 0 0 3 0 1 20 30

{ delta [ 0 0 2 4 10 20 30 ] mode standard  type exact }
   =>
   '[set] Type must be semi/approx/estimated'

{ delta [ 0 0 2 4 10 20 30 ] mode standard  type semi }        => 0 0 2 4 10 20 30

{ delta [ 0 0 2 4 10 20 30 ] mode standard  type approx }      => 0 0 2 4 10 20 30

{ delta [ 0 0 2 4 10 20 30 ] mode standard  type estimated }   => 0 0 2 4 10 20 30

#

{ delta [ 0 14 2 4 10 20 30 ] }                                => 1 2 2 4 10 20 30

{ delta [ 0 14 2 4 10 20 30 ] nonorm 1 }                       => 0 14 2 4 10 20 30

{ delta [ 0 14 2 4 10 20 30 ] mode business  type exact }
   =>
   '[set] Type must be approx/estimated'

{ delta [ 0 14 2 4 10 20 30 ] mode business  type semi }
   =>
   '[set] Type must be approx/estimated'

{ delta [ 0 14 2 4 10 20 30 ] mode business  type approx }     => 1 2 3 0 1 20 30

{ delta [ 0 14 2 4 10 20 30 ] mode business  type estimated }  => 1 2 3 0 1 20 30

{ delta [ 0 14 2 4 10 20 30 ] mode standard  type exact }
   =>
   '[set] Type must be approx/estimated'

{ delta [ 0 14 2 4 10 20 30 ] mode standard  type semi }
   =>
   '[set] Type must be approx/estimated'

{ delta [ 0 14 2 4 10 20 30 ] mode standard  type approx }     => 1 2 2 4 10 20 30

{ delta [ 0 14 2 4 10 20 30 ] mode standard  type estimated }  => 1 2 2 4 10 20 30

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
