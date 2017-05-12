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
use Data::Nested;

sub test {
  (@test)=@_;
  $val = $obj->value(@test);
  return ($val,$obj->err());
}

$obj = new Data::Nested;

$nds = { "a" => [ "a1", "a2" ],
         "b" => [ "b1", "b2" ] };
$obj->nds("ele1",$nds,1);

$nds = { "a" => [ "aa1", "aa2" ],
         "b" => [ "bb1", "bb2" ] };
$obj->nds("ele2",$nds,1);

$obj->nds("ele3","ele1",1);

$tests = "
ele0 /a/0 ~ _undef_ ndsnam01

ele1 /a/0 ~ a1 _blank_

ele2 /a/0 ~ aa1 _blank_

ele3 /a/0 ~ a1 _blank_

";

print "nds...\n";
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

