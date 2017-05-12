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
  $obj->check_value(@test);
  return $obj->err();
}

$obj = new Data::Nested;

$o = { a => [ 1,2,3 ],
       b => { bb => 1 },
     };
$obj->check_structure($o,1);

$s  = "foo";
$l  = [ 4,5,6 ];
$hs = { bb => 2 };
$hl = { bb => [1] };

$tests = 
[
  [ [ "/a", $s ],
    [ "ndschk01" ] ],

  [ [ "/a", $l ],
    [ "_blank_" ] ],

  [ [ "/b", $s ],
    [ "ndschk01" ] ],

  [ [ "/b", $hs ],
    [ "_blank_" ] ],

  [ [ "/b", $hl ],
    [ "ndschk01" ] ],
];

print "check_value...\n";
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

