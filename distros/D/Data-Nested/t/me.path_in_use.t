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
  @val = $obj->path_in_use(@test);
  $err = $obj->err();
  return (@val,$err);
}

$obj = new Data::Nested::Multiele;
$obj->file("$tdir/ME.DATA.data.yaml");
$obj->default_element("def1","/usedef1","1");
$obj->default_element("def2","/usedef2","1");
$obj->default_element("def3","/usedef3","1");

$tests = "

/l1/0 ~ 1 _blank_

/l1/1 ~ 0 _blank_

";


print "path_in_use...\n";
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

