#!/usr/bin/perl -w

require 5.001;

$runtests=shift(@ARGV);
if ( -f "t/test.pl" ) {
  require "t/test.pl";
  $dir="./lib";
  $tdir="t";
} elsif ( -f "test.pl" ) {
  require "test.pl";
  $dir="../lib";
  $tdir=".";
} else {
  die "ERROR: cannot find test.pl\n";
}

unshift(@INC,$dir);
use Array::AsObject;

sub test {
  ($op,$o1,$o2,@test) = @_;

  $obj1 = $obj{$o1};
  $obj2 = $obj{$o2};

  if ($op eq "union") {
     $ret = $obj1->union($obj2,@test);
  } elsif ($op eq "difference") {
     $ret = $obj1->difference($obj2,@test);
  } elsif ($op eq "intersection") {
     $ret = $obj1->intersection($obj2,@test);
  } elsif ($op eq "symmetric_difference") {
     $ret = $obj1->symmetric_difference($obj2,@test);
  } elsif ($op eq "is_equal") {
     $ret = $obj1->is_equal($obj2,@test);
  } elsif ($op eq "not_equal") {
     $ret = $obj1->not_equal($obj2,@test);
  } elsif ($op eq "is_subset") {
     $ret = $obj1->is_subset($obj2,@test);
  } elsif ($op eq "not_subset") {
     $ret = $obj1->not_subset($obj2,@test);
  }
  if (ref($ret)) {
     return $ret->list();
  }
  return $ret;
}

$obj{l1} = new Array::AsObject qw(a a b c);
$obj{l2} = new Array::AsObject qw(a c d d e);
$obj{l3} = new Array::AsObject qw(a a c d);
$obj{l4} = new Array::AsObject qw(a a b b c);
$obj{l5} = new Array::AsObject qw(a c);
$obj{l6} = new Array::AsObject qw(a a b);
$obj{l7} = new Array::AsObject qw(a b);
$obj{l8} = new Array::AsObject qw(b a);

$tests = "

union l1 l2 ~ a a b c a c d d e

union l1 l2 1 ~ a b c d e

difference l1 l2 ~ a b

difference l1 l2 1 ~ b

intersection l1 l3 ~ a a c

intersection l1 l3 1 ~ a c

symmetric_difference l4 l5 ~ a b b

symmetric_difference l4 l5 1 ~ b b

is_equal l6 l7 ~ 0

is_equal l6 l7 1 ~ 1

is_equal l7 l8 ~ 1

is_equal l7 l8 1 ~ 1

not_equal l6 l7 ~ 1

not_equal l6 l7 1 ~ 0

not_equal l7 l8 ~ 0

not_equal l7 l8 1 ~ 0

is_subset l6 l7 0 ~ 1

is_subset l6 l7 1 ~ 1

is_subset l7 l6 0 ~ 0

is_subset l7 l6 1 ~ 1

is_subset l1 l6 0 ~ 1

";

print "set operations...\n";
test_Func(\&test,$tests,$runtests);

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

