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
  $val = $obj->test_conditions(@test);
  return ($val,$obj->err());
}

$obj = new Data::Nested;

$nds = { "a"  => 0,
         "b"  => "",
         "c"  => undef,
         "d"  => 1,
       };
$obj->nds("ele3",$nds,1);

$tests = "

ele3 /a defined ~ 1 _blank_

ele3 /b defined ~ 1 _blank_

ele3 /c defined ~ 0 _blank_

ele3 /d defined ~ 1 _blank_

ele3 /a !defined ~ 0 _blank_

ele3 /b !defined ~ 0 _blank_

ele3 /c !defined ~ 1 _blank_

ele3 /d !defined ~ 0 _blank_


ele3 /a empty ~ 0 _blank_

ele3 /b empty ~ 1 _blank_

ele3 /c empty ~ 1 _blank_

ele3 /d empty ~ 0 _blank_

ele3 /a !empty ~ 1 _blank_

ele3 /b !empty ~ 0 _blank_

ele3 /c !empty ~ 0 _blank_

ele3 /d !empty ~ 1 _blank_


ele3 /a zero ~ 1 _blank_

ele3 /b zero ~ 1 _blank_

ele3 /c zero ~ 0 _blank_

ele3 /d zero ~ 0 _blank_

ele3 /a !zero ~ 0 _blank_

ele3 /b !zero ~ 0 _blank_

ele3 /c !zero ~ 1 _blank_

ele3 /d !zero ~ 1 _blank_


ele3 /a true ~ 0 _blank_

ele3 /b true ~ 0 _blank_

ele3 /c true ~ 0 _blank_

ele3 /d true ~ 1 _blank_

ele3 /a !true ~ 1 _blank_

ele3 /b !true ~ 1 _blank_

ele3 /c !true ~ 1 _blank_

ele3 /d !true ~ 0 _blank_


ele3 /a =:0 ~ 1 _blank_

ele3 /d =:0 ~ 0 _blank_

ele3 /d =:1 ~ 1 _blank_

ele3 /a !=:0 ~ 0 _blank_

ele3 /d !=:0 ~ 1 _blank_

ele3 /d !=:1 ~ 0 _blank_

ele3 /a 0 ~ 1 _blank_

ele3 /d 0 ~ 0 _blank_

ele3 /d 1 ~ 1 _blank_

ele3 /a !0 ~ 0 _blank_

ele3 /d !0 ~ 1 _blank_

ele3 /d !1 ~ 0 _blank_


ele3 /d member:1:2:3 ~ 1 _blank_

ele3 /d member+1+2+3 ~ 1 _blank_

ele3 /d member:2:3 ~ 0 _blank_

ele3 /d member+2+3 ~ 0 _blank_

ele3 /d !member:1:2:3 ~ 0 _blank_

ele3 /d !member+1+2+3 ~ 0 _blank_

ele3 /d !member:2:3 ~ 1 _blank_

ele3 /d !member+2+3 ~ 1 _blank_

";

print "test_conditions (scalar)...\n";
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

