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
  $obj->set_merge(@test);
  return $obj->err();
}

$obj = new Data::Nested;

$obj->set_structure("type","hash","/h");

$obj->set_structure("type","scalar","/s");

$obj->set_structure("type","list","/ol");
$obj->set_structure("ordered",1,"/ol");

$obj->set_structure("type","list","/ul");
$obj->set_structure("ordered",0,"/ul");

$tests = "

merge_hash keep ~ _blank_

merge_hash append ~ ndsmer02

merge_ol keep ~ _blank_

merge_ol append ~ ndsmer03

merge_ul keep ~ _blank_

merge_ul append ~ _blank_

merge_ul merge ~ ndsmer04

merge_scalar keep ~ _blank_

merge_scalar merge ~ ndsmer05

merge /u append ~ ndsmer07

merge /h foo ~ ndsmer10

merge /h merge ~ _blank_

merge /h keep ~ ndsmer06

merge /s foo ~ ndsmer11

merge /s replace ~ _blank_

merge /ol foo ~ ndsmer08

merge /ol append ~ ndsmer08

merge /ol merge ~ _blank_

merge /ul foo ~ ndsmer09

merge /ul merge ~ ndsmer09

merge /ul append ~ _blank_

";

print "set_merge...\n";
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

