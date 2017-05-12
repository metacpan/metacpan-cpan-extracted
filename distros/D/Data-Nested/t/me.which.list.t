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
use Data::Nested::Multiele;

sub test {
  (@test)=@_;
  @ele = $obj->which(@test);
  return @ele;
}

$obj = new Data::Nested::Multiele;
$obj->file("$tdir/ME.DATA.which.list.yaml");

$tests = "

/h1 empty ~ 0 1 2 4 5

/h1 !empty ~ 3

/h1 empty:h1k1 ~ 0 1 2 4 5

/h1 !empty:h1k1 ~ 3

/h1 exists:h1k1 ~ 2 3

/h1 !exists:h1k1 ~ 0 1 4 5

/l1 empty ~ 0 1 2

/l1 !empty ~ 3 4 5

/l1 defined:0 ~ 3 4 5

/l1 !defined:0 ~ 0 1 2

/l1 defined:1 ~ 2 5

/l1 !defined:1 ~ 0 1 3 4

/l1 empty:0 ~ 0 1 2

/l1 !empty:0 ~ 3 4 5

/l1 contains:dl1v1 ~ 3

/l1 !contains:dl1v1 ~ 0 1 2 4 5

/l2 <:3 ~ 0 1 2 3 4

/l2 !<:3 ~ 5

/l2 <=:1 ~ 0 1 2 3

/l2 !<=:1 ~ 4 5

/l2 =:2 ~ 4

/l2 !=:2 ~ 0 1 2 3 5

/l2 contains:2 ~ 4 5

/l2 !contains:2 ~ 0 1 2 3

/s1 defined ~ 2 3 4 5

/s1 !defined ~ 0 1

/s1 empty ~ 0 1 2

/s1 !empty ~ 3 4 5

/s1 =:s1v1 ~ 3 4

/s1 !=:s1v1 ~ 0 1 2 5

/s1 member:s1v1 ~ 3 4

/s1 !member:s1v1 ~ 0 1 2 5

/s1 member/s1v1/s1v2 ~ 3 4 5

/s1 !member/s1v1/s1v2 ~ 0 1 2

";


print "which (list)...\n";
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

