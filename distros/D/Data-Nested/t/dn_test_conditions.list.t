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

$nds = { "a"  => [],
         "b"  => undef,
         "c"  => [ undef, "" ],
         "d"  => [ qw(xx yy) ],
         "e"  => [ undef, qw(aa bb cc) ],
       };
$obj->nds("ele2",$nds,1);

$tests = "

ele2 /a empty ~ 1 _blank_

ele2 /b empty ~ 1 _blank_

ele2 /c empty ~ 1 _blank_

ele2 /d empty ~ 0 _blank_

ele2 /a !empty ~ 0 _blank_

ele2 /b !empty ~ 0 _blank_

ele2 /c !empty ~ 0 _blank_

ele2 /d !empty ~ 1 _blank_


ele2 /a defined:0 ~ 0 _blank_

ele2 /c defined:0 ~ 0 _blank_

ele2 /c defined:1 ~ 1 _blank_

ele2 /d defined:0 ~ 1 _blank_

ele2 /a !defined:0 ~ 1 _blank_

ele2 /c !defined:0 ~ 1 _blank_

ele2 /c !defined:1 ~ 0 _blank_

ele2 /d !defined:0 ~ 0 _blank_


ele2 /a empty:0 ~ 1 _blank_

ele2 /c empty:0 ~ 1 _blank_

ele2 /c empty:0 ~ 1 _blank_

ele2 /d empty:0 ~ 0 _blank_

ele2 /a !empty:0 ~ 0 _blank_

ele2 /c !empty:0 ~ 0 _blank_

ele2 /c !empty:0 ~ 0 _blank_

ele2 /d !empty:0 ~ 1 _blank_


ele2 /d contains:xx ~ 1 _blank_

ele2 /d contains:zz ~ 0 _blank_

ele2 /d !contains:xx ~ 0 _blank_

ele2 /d !contains:zz ~ 1 _blank_

ele2 /d xx ~ 1 _blank_

ele2 /d zz ~ 0 _blank_

ele2 /d !xx ~ 0 _blank_

ele2 /d !zz ~ 1 _blank_


ele2 /a <:2 ~ 1 _blank_

ele2 /d <:2 ~ 0 _blank_

ele2 /e <:4 ~ 1 _blank_

ele2 /a <=:2 ~ 1 _blank_

ele2 /d <=:2 ~ 1 _blank_

ele2 /d <=:1 ~ 0 _blank_

ele2 /d =:1 ~ 0 _blank_

ele2 /d =:2 ~ 1 _blank_

ele2 /c >:0 ~ 0 _blank_

ele2 /d >:1 ~ 1 _blank_

ele2 /d >:2 ~ 0 _blank_

ele2 /c >=:0 ~ 1 _blank_

ele2 /d >=:1 ~ 1 _blank_

ele2 /d >=:2 ~ 1 _blank_

ele2 /d >=:3 ~ 0 _blank_


ele2 /a !<:2 ~ 0 _blank_

ele2 /d !<:2 ~ 1 _blank_

ele2 /e !<:4 ~ 0 _blank_

ele2 /a !<=:2 ~ 0 _blank_

ele2 /d !<=:2 ~ 0 _blank_

ele2 /d !<=:1 ~ 1 _blank_

ele2 /d !=:1 ~ 1 _blank_

ele2 /d !=:2 ~ 0 _blank_

ele2 /c !>:0 ~ 1 _blank_

ele2 /d !>:1 ~ 0 _blank_

ele2 /d !>:2 ~ 1 _blank_

ele2 /c !>=:0 ~ 0 _blank_

ele2 /d !>=:1 ~ 0 _blank_

ele2 /d !>=:2 ~ 0 _blank_

ele2 /d !>=:3 ~ 1 _blank_

";

print "test_conditions (list)...\n";
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

