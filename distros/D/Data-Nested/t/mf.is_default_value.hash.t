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
  return $obj->is_default_value(@test);
}

$obj = new Data::Nested::Multifile;
$obj->file("FILE1","$tdir/MF.DATA.def.hash.1.yaml",
           "FILE2","$tdir/MF.DATA.def.hash.2.yaml");
$obj->default_element("def11");
$obj->default_element("def21");
$obj->default_element("def31","/c","c4");
$obj->default_element("def12");
$obj->default_element("def22");
$obj->default_element("def32","/c","c4");

$tests = "
ele1 /a ~ 0

ele1 /b ~ 0

ele1 /c ~ 0

ele2 /a ~ 0

ele2 /b ~ 1

ele2 /c ~ 0

ele3 /a ~ 1

ele3 /b ~ 0

ele3 /c ~ 0

ele3 /d ~ 0

ele4 /a ~ 1

ele4 /b ~ 1

ele4 /c ~ 0

ele4 /d ~ 1

";

print "is_default_value (hash)...\n";
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

