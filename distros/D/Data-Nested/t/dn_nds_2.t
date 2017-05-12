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
  my ($op,$ele,$path) = @test;

  if ($op eq "copy") {
     $nds = $obj->nds($ele,"_copy");
  } else {
     $nds = $obj->nds($ele);
  }
  @ret = ();
  push(@ret,$obj->keys($nds,"/"),"--");
  $obj->erase($nds,$path);
  push(@ret,$obj->keys($nds,"/"),"--");
  $nds = $obj->nds($ele);
  push(@ret,$obj->keys($nds,"/"));
  return @ret;
}

$obj = new Data::Nested;

$nds = { "a" => [ "a1", "a2" ],
         "b" => [ "b1", "b2" ] };
$obj->nds("ele1",$nds,1);

$tests = "
copy ele1 /a ~ a b -- b -- a b

real ele1 /a ~ a b -- b -- b

";

print "nds (copy)...\n";
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

