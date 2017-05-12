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

$nds = { "a"  => {aa => 1},
         "b"  => {},
         "c"  => 0,
         "d"  => undef,
         "e"  => ""
       };
$obj->nds("ele1",$nds,1);

$tests = "

ele1 / exists:a ~ 1 _blank_

ele1 / exists:b ~ 1 _blank_

ele1 / exists:c ~ 1 _blank_

ele1 / exists:d ~ 1 _blank_

ele1 / exists:e ~ 1 _blank_

ele1 / exists:z ~ 0 _blank_

ele1 / !exists:a ~ 0 _blank_

ele1 / !exists:b ~ 0 _blank_

ele1 / !exists:c ~ 0 _blank_

ele1 / !exists:d ~ 0 _blank_

ele1 / !exists:e ~ 0 _blank_

ele1 / !exists:z ~ 1 _blank_


ele1 / empty:a ~ 0 _blank_

ele1 / empty:b ~ 1 _blank_

ele1 / empty:c ~ 0 _blank_

ele1 / empty:d ~ 1 _blank_

ele1 / empty:e ~ 1 _blank_

ele1 / empty:z ~ 1 _blank_

ele1 / !empty:a ~ 1 _blank_

ele1 / !empty:b ~ 0 _blank_

ele1 / !empty:c ~ 1 _blank_

ele1 / !empty:d ~ 0 _blank_

ele1 / !empty:e ~ 0 _blank_

ele1 / !empty:z ~ 0 _blank_


ele1 / empty  ~ 0 _blank_

ele1 /a empty  ~ 0 _blank_

ele1 /b empty  ~ 1 _blank_

ele1 /d empty  ~ 1 _blank_

ele1 /z empty  ~ 1 _blank_

ele1 / !empty  ~ 1 _blank_

ele1 /a !empty  ~ 1 _blank_

ele1 /b !empty  ~ 0 _blank_

ele1 /d !empty  ~ 0 _blank_

ele1 /z !empty  ~ 0 _blank_

ele1 / foobar ~ _undef_ ndscon01

";

print "test_conditions (hash)...\n";
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

