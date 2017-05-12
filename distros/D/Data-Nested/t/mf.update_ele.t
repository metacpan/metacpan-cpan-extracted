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
  ($ele,$path,$val) = @test;
  @ret = ();
  push(@ret,$obj->keys($ele,$path),'--',$obj->values($ele,$path),'--');
  $obj->update_ele($ele,$path,$val,1);
  push(@ret,$obj->keys($ele,$path),'--',$obj->values($ele,$path));
  return @ret;
}

$obj = new Data::Nested::Multifile;
$obj->file("FILE1","$tdir/MF.DATA.data2.1.yaml",
           "FILE2","$tdir/MF.DATA.data2.2.yaml");

%nds1 = ( x => 21, y => 22 );
%nds2 = ( x => 31, z => 33 );

$tests =
[
  [ [ "a", "/k2", \%nds1 ],
    [ qw(x y -- 1 2 -- x y -- 21 22) ] ],

  [ [ "b", "/k2", \%nds2 ],
    [ qw(x y -- 11 12 -- x z -- 31 33) ] ],
];

print "update_ele...\n";
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

