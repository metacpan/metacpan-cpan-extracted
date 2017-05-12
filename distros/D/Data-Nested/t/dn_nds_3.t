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
  $ret = $obj->nds(@test);
  return ($ret,$obj->err());
}

$obj = new Data::Nested;

$nds = { "a" => [ "a1", "a2" ],
         "b" => [ "b1", "b2" ] };

$obj->nds("nds",$nds,1);

$tests = "
nds1 _delete ~ 0 _blank_

nds1 _exists ~ 0 _blank_

nds1 nds ~ _undef_ _blank_

nds1 _exists ~ 1 _blank_

nds2 nds1 ~ _undef_ _blank_

nds2 nds1 ~ _undef_ ndsnam02

nds1 _delete ~ 1 _blank_

nds4 nds3 ~ _undef_ ndsnam01

";

print "nds (ops)...\n";
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

