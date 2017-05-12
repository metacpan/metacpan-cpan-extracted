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
  my($ele,$delpath,$keyspath,$vals) = @test;

  my @out  = $obj->keys($ele,$keyspath);
  push(@out,"--");
  $obj->erase($ele,$delpath);
  push(@out,$obj->err());
  push(@out,"--");
  push(@out,$obj->keys($ele,$keyspath));
  push(@out,"--");
  push(@out,$obj->values($ele,$keyspath))  if ($vals);
  return @out;
}

$obj = new Data::Nested;

$obj->set_structure("type","list","/c");
$obj->set_structure("ordered","0","/c");
$obj->set_structure("type","list","/d");
$obj->set_structure("ordered","1","/d");

$nds = { "a" => 1,
         "b" => { "x" => 11, "y" => 22 },
         "c" => [ qw(alpha beta gamma delta) ],
         "d" => [ qw(alpha beta gamma delta) ],
       };
$obj->nds("ele",$nds,1);

$tests =
[
  [
    [ qw(ele /a / 0) ],
    [ qw(a b c d -- _blank_ -- b c d -- ) ]
  ],

  [
    [ qw(ele /b/x /b 1) ],
    [ qw(x y -- _blank_ -- y -- 22) ]
  ],

  [
    [ qw(ele /c/1 /c 1) ],
    [ qw(0 1 2 3 -- _blank_ -- 0 1 2 -- alpha gamma delta) ]
  ],

  [
    [ qw(ele /d/1 /d 1) ],
    [ qw(0 1 2 3 -- _blank_ -- 0 2 3 -- alpha gamma delta) ]
  ],

];

print "erase...\n";
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

