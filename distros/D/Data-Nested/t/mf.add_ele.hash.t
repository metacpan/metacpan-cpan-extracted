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
  @ele = $obj->eles();
  foreach $t (@test) {
    if ($t =~ /^=(.*)/) {
       $t = $nds{$1};
    }
  }
  $obj->add_ele(@test,1);
  $err = $obj->err();
  @el2 = $obj->eles();
  return (@ele,'--',@el2,'--',$err);
}

$obj = new Data::Nested::Multifile;
$obj->file("FILE1","$tdir/MF.DATA.file.hash.1.yaml",
           "FILE2","$tdir/MF.DATA.file.hash.2.yaml");

%nds = ( "nds1" => { x => 11, y => 12 } );

$tests = "
=nds1 ~ a b c -- a b c -- nmfele04

x =nds1 ~ a b c -- a b c x -- _blank_

b =nds1 ~ a b c x -- a b c x -- nmfele02

FILE1 y =nds1 ~ a b c x -- a b c x y -- _blank_

FILE2 z =nds1 ~ a b c x y -- a b c x y z -- _blank_

";

print "add_ele (hash)...\n";
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

