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
  $obj->default_element(@test);
  return $obj->err();
}

$obj = new Data::Nested::Multifile;
$obj->file("FILE1","$tdir/MF.DATA.def.list.1.yaml",
           "FILE2","$tdir/MF.DATA.def.list.2.yaml");

$tests = "
FILE1 ~ _blank_

FILE1 keep ~ _blank_

FILE1 /c c4 ~ _blank_

FILE2 ~ _blank_

FILE2 keep ~ _blank_

FILE2 /c c4 ~ _blank_

";

print "default_element (list)...\n";
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

