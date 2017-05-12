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
  @ele = $obj->which(@test);
  return @ele;
}

$obj = new Data::Nested::Multifile;
$obj->file("FILE1","$tdir/MF.DATA.which.hash.1.yaml",
           "FILE2","$tdir/MF.DATA.which.hash.2.yaml");

$tests = "

/h1 empty ~ a b c e f

/h1 !empty ~ d

/h1 empty:h1k1 ~ a b c e f

/h1 !empty:h1k1 ~ d

/h1 exists:h1k1 ~ c d

/h1 !exists:h1k1 ~ a b e f

/l1 empty ~ a b c

/l1 !empty ~ d e f

/l1 defined:0 ~ d e f

/l1 !defined:0 ~ a b c

/l1 defined:1 ~ c f

/l1 !defined:1 ~ a b d e

/l1 empty:0 ~ a b c

/l1 !empty:0 ~ d e f

/l1 contains:dl1v1 ~ d

/l1 !contains:dl1v1 ~ a b c e f

/l2 <:3 ~ a b c d e

/l2 !<:3 ~ f

/l2 <=:1 ~ a b c d

/l2 !<=:1 ~ e f

/l2 =:2 ~ e

/l2 !=:2 ~ a b c d f

/l2 contains:2 ~ e f

/l2 !contains:2 ~ a b c d

/s1 defined ~ c d e f

/s1 !defined ~ a b

/s1 empty ~ a b c

/s1 !empty ~ d e f

/s1 =:s1v1 ~ d e

/s1 !=:s1v1 ~ a b c f

/s1 member:s1v1 ~ d e

/s1 !member:s1v1 ~ a b c f

/s1 member/s1v1/s1v2 ~ d e f

/s1 !member/s1v1/s1v2 ~ a b c

";


print "which (hash)...\n";
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

