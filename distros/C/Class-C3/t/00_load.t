#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Class::C3;
use Class::C3::next;

if ($] > 5.009_004) {
  ok ($Class::C3::C3_IN_CORE, 'C3 in core');
  ok (!$Class::C3::C3_XS, 'Not using XS');
  diag "Fast C3 provided by this perl version $] in core"
    unless $INC{'Devel/Hide.pm'};
}
else {
  ok (!$Class::C3::C3_IN_CORE, 'C3 not in core');

  if (eval { require Class::C3::XS; Class::C3::XS->VERSION }) {
    ok ($Class::C3::C3_XS, 'Using XS');
    diag "XS speedups available (via Class::C3::XS)"
      unless $INC{'Devel/Hide.pm'};
  }
  else {
    ok (! $Class::C3::C3_XS, 'Not using XS');
    unless ($INC{'Devel/Hide.pm'}) {
      diag "NO XS speedups - YOUR CODE WILL BE VERY SLOW. Consider installing Class::C3::XS";
      sleep 3 if -t *STDIN or -t *STDERR;
    }
  }
}
