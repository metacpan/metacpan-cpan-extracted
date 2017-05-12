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
use Data::Nested::Multifile;

sub test {
  (@test)=@_;
  @val = $obj->values(@test);
  $err = $obj->err();
  return (@val,$err);
}

$obj = new Data::Nested::Multifile;
$obj->file("FILE1","$tdir/MF.DATA.data.1.yaml",
           "FILE2","$tdir/MF.DATA.data.2.yaml");
$obj->default_element("def11","/usedef1","1");
$obj->default_element("def21","/usedef2","1");
$obj->default_element("def31","/usedef3","1");
$obj->default_element("def12","/usedef1","1");
$obj->default_element("def22","/usedef2","1");
$obj->default_element("def32","/usedef3","1");

$tests = "

a /dh1 ~ _undef_ nmeacc04

b /dh1 ~ valBa _blank_

c /dh1 ~ valCb _blank_

d /dh1 ~ valDa valDb _blank_

e /dh1 ~ def1a def1b _blank_

f /dh1 ~ valFa def1b _blank_

g /dh1 ~ def1a valGb _blank_

h /dh1 ~ valHa valHb _blank_

a /h1 ~ _blank_

b /h1 ~ _blank_

c /h1 ~ valCh1a _blank_

a /l1 ~ _blank_

b /l1 ~ _blank_

c /l1 ~ _blank_

d /l1 ~ valDl1_0 _blank_

a /l1 1 ~ _blank_

b /l1 1 ~ _undef_ _blank_

c /l1 1 ~ _blank_ _blank_

d /l1 1 ~ valDl1_0 _blank_

";


print "values...\n";
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

