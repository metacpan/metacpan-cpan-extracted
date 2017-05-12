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
  return $obj->empty(@test);
}

$obj = new Data::Nested;

$tests =
[
  [
    [ ],
    [ 1 ]
  ],

  [
    [ undef ],
    [ 1 ]
  ],

  [
    [ [ "" ] ],
    [ 1 ]
  ],

  [
    [ [ "", undef ] ],
    [ 1 ]
  ],

  [
    [ [ undef, undef ] ],
    [ 1 ]
  ],

  [
    [ { 1, "", 2, undef } ],
    [ 1 ]
  ],

  [
    [ { 1, undef, 2, undef } ],
    [ 1 ]
  ],

];

print "empty...\n";
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

