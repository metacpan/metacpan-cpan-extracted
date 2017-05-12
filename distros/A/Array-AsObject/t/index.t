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
use Array::AsObject;

sub test {
  ($o,$val) = @_;
  $o = $obj{$o};

  @ret = ();
  @idx = $o->index($val);
  $idx = $o->index($val);
  push(@ret,@idx,'--',$idx,'--');
  @idx = $o->rindex($val);
  $idx = $o->rindex($val);
  push(@ret,@idx,'--',$idx);
  return @ret;
}

%obj       = ();
$o         = new Array::AsObject qw( a b c a b );
$obj{'01'} = $o;

$i         = [ qw(a b) ];
$o         = new Array::AsObject ('a', $i, $i, 'b', undef, 'a');
$obj{'02'} = $o;

$j         = [ qw(a b) ];
$o         = new Array::AsObject ('a', $i, $j, undef, 'b', undef, 'a');
$obj{'03'} = $o;


$tests = [
           [
             [ qw(01) ],
             [ qw(-- -1 -- -- -1) ],
           ],

           [
             [ qw(01 a) ],
             [ qw(0 3 -- 0 -- 3 0 -- 3) ],
           ],

           [
             [ qw(01 z) ],
             [ qw(-- -1 -- -- -1) ],
           ],

           [
             [ qw(02) ],
             [ qw(4 -- 4 -- 4 -- 4) ],
           ],

           [
             [ qw(02 a) ],
             [ qw(0 5 -- 0 -- 5 0 -- 5) ],
           ],

           [
             [ '02', $i ],
             [ qw(1 2 -- 1 -- 2 1 -- 2) ],
           ],

           [
             [ qw(02 z) ],
             [ qw(-- -1 -- -- -1) ],
           ],

           [
             [ qw(03) ],
             [ qw(3 5 -- 3 -- 5 3 -- 5) ],
           ],
         ];

print "index/rindex...\n";
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

