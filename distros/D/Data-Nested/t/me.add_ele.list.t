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
use Data::Nested::Multiele;

sub test {
  (@test)=@_;
  foreach $t (@test) {
    if ($t =~ /^=(.*)/) {
       $t = $nds{$1};
    }
  }

  @ele = $obj->eles();
  $obj->add_ele(@test,1);
  $err = $obj->err();

  @el2 = $obj->eles();
  @val = ();
  foreach $el (@el2) {
    $val = $obj->value($el,"/x");
    push(@val,$val);
  }

  return (@ele,'--',@el2,'--',$err,'--',@val);
}

$obj = new Data::Nested::Multiele;
$obj->file("$tdir/ME.DATA.file.list.yaml");

# x values are a=1, b=3, c=5

%nds = ( "nds1" => { x => 11, y => 12 },
         "nds2" => { x => 21, y => 22 },
         "nds3" => { x => 31, y => 32 } );

$tests = "
=nds1 ~ 0 1 2 -- 0 1 2 3 -- _blank_ -- 1 3 5 11

2 =nds2 ~ 0 1 2 3 -- 0 1 2 3 4 -- _blank_ -- 1 3 21 5 11

5 =nds3 ~ 0 1 2 3 4 -- 0 1 2 3 4 -- nmeele04 -- 1 3 21 5 11
";

print "add_ele (list)...\n";
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

