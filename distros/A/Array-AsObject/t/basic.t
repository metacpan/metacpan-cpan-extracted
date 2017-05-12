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
  ($op,@test) = @_;

  if ($op eq "length") {
     @ret = ($obj->length());
  } elsif ($op eq "clear") {
     @ret = ($obj->clear(@test));
  } elsif ($op eq "list") {
     @ret = ($obj->list(@test));
  } elsif ($op eq "compact") {
     @ret = ($obj->compact(@test));
  } elsif ($op eq "unique") {
     @ret = ($obj->unique(@test));
  } elsif ($op eq "push") {
     @ret = ($obj->push(@test));
  } elsif ($op eq "pop") {
     @ret = ($obj->pop(@test));
  } elsif ($op eq "unshift") {
     @ret = ($obj->unshift(@test));
  } elsif ($op eq "shift") {
     @ret = ($obj->shift(@test));
  } elsif ($op eq "reverse") {
     @ret = ($obj->reverse(@test));
  } elsif ($op eq "rotate") {
     @ret = ($obj->rotate(@test));
  } elsif ($op eq "first") {
     @ret = ($obj->first(@test));
  } elsif ($op eq "last") {
     @ret = ($obj->last(@test));
  } elsif ($op eq "count") {
     @ret = ($obj->count(@test));
  } elsif ($op eq "index") {
     @ret = ($obj->index(@test));
  } elsif ($op eq "rindex") {
     @ret = ($obj->rindex(@test));
  } elsif ($op eq "exists") {
     @ret = ($obj->exists(@test));
  } elsif ($op eq "is_empty") {
     @ret = ($obj->is_empty(@test));
  } elsif ($op eq "sort") {
     @ret = ($obj->sort(@test));
  } elsif ($op eq "min") {
     @ret = ($obj->min(@test));
  } elsif ($op eq "max") {
     @ret = ($obj->max(@test));
  } elsif ($op eq "fill") {
     @ret = ($obj->fill(@test));
  } elsif ($op eq "splice") {
     @ret = ($obj->splice(@test));
  } elsif ($op eq "set") {
     @ret = ($obj->set(@test));
  } elsif ($op eq "delete") {
     @ret = ($obj->delete(@test));
  } elsif ($op eq "delete_at") {
     @ret = ($obj->delete_at(@test));
  }
  $err    = $obj->err();
  return ($err,@ret);
}

$obj = new Array::AsObject;

$tests = "

length ~ 0 0

list ~ 0

list a b ~ 0

length ~ 0 2

clear 1 ~ 0

length ~ 0 2

clear ~ 0

length ~ 0 0

list a _undef_ b _undef_ a ~ 0

list ~ 0 a _undef_ b _undef_ a

length ~ 0 5

compact ~ 0

list ~ 0 a b a

unique ~ 0

list ~ 0 a b

push a c ~ 0

list ~ 0 a b a c

shift ~ 0 a

list ~ 0 b a c

unshift a a ~ 0

list ~ 0 a a b a c

pop ~ 0 c

list ~ 0 a a b a

reverse ~ 0

list ~ 0 a b a a

list a b c d ~ 0

rotate ~ 0

list ~ 0 b c d a

rotate 1 ~ 0

list ~ 0 c d a b

rotate 3 ~ 0

list ~ 0 b c d a

rotate -1 ~ 0

list ~ 0 a b c d

rotate -3 ~ 0

list ~ 0 b c d a

first ~ 0 b

last ~ 0 a

list a b _undef_ a _undef_ c a ~ 0

count ~ 0 2

count a ~ 0 3

count c ~ 0 1

count d ~ 0 0

index ~ 0 2 4

index a ~ 0 0 3 6

index d ~ 0

rindex ~ 0 4 2

rindex a ~ 0 6 3 0

exists ~ 0 1

exists a ~ 0 1

exists d ~ 0 0

exists a b ~ 0 1

exists a d ~ 0 0

is_empty ~ 0 0

is_empty 1 ~ 0 0

list _undef_ _undef_ ~ 0

is_empty ~ 0 0

is_empty 1 ~ 0 1

clear ~ 0

is_empty ~ 0 1

is_empty 1 ~ 0 1

list c a d b ~ 0

min alphabetic ~ 0 a

max alphabetic ~ 0 d

sort ~ 0

list ~ 0 a b c d

list -2 3 -11 10 5 ~ 0

min ~ 0 -11

max ~ 0 10

sort numerical ~ 0

list ~ 0 -11 -2 3 5 10

list a b c d ~ 0

fill 1 2 ~ 0

list ~ 0 a b 1 1

fill 2 -1 ~ 0

list ~ 0 a b 1 2

fill 3 1 2 ~ 0

list ~ 0 a 3 3 2

fill 4 5 ~ 1 _undef_

fill 5 4 ~ 0

list ~ 0 a 3 3 2 5

fill 6 5 2 ~ 0

list ~ 0 a 3 3 2 5 6 6

fill 7 ~ 0

list ~ 0 7 7 7 7 7 7 7

list 1 2 3 4 5 ~ 0

splice 1 2 ~ 0 2 3

list ~ 0 1 4 5

splice 1 0 a b ~ 0

list ~ 0 1 a b 4 5

splice -3 2 x y ~ 0 b 4

list ~ 0 1 a x y 5

set 2 ~ 0

list ~ 0 1 a _undef_ y 5

set -2 z ~ 0

list ~ 0 1 a _undef_ z 5

list a b a c a d a ~ 0

delete 0 0 a c ~ 0

list ~ 0 b a a d a

list a b a c a d a ~ 0

delete 0 1 a c ~ 0

list ~ 0 _undef_ b a _undef_ a d a

list a b a c a d a ~ 0

delete 1 0 a c ~ 0

list ~ 0 b d

list a b a c a d a ~ 0

delete 1 1 a c ~ 0

list ~ 0 _undef_ b _undef_ _undef_ _undef_ d _undef_

list 0 1 2 3 4 5 ~ 0

delete_at 0 0 2 4 ~ 0

list ~ 0 1 3 5

list 0 1 2 3 4 5 ~ 0

delete_at 1 0 2 4 ~ 0

list ~ 0 _undef_ 1 _undef_ 3 _undef_ 5

";

print "basic operations...\n";
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

