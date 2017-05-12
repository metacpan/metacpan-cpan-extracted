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
  if ($test[0] eq "CHECK") {
    return (defined $test[1] ? $test[1] : '');
  }
  @val = $obj->get_structure(@test);
  $err = $obj->err();
  return (@val,$err);
}

$obj = new Data::Nested;

$o = { a => [ 1,2,3 ],
       b => { bb => 1 },
     };
$obj->check_structure($o,1);
$e1 = $obj->err();

$o = { a => [ 1 ] };
$obj->check_structure($o,1);
$e2 = $obj->err();

$o = { a => [ { aa => 1 } ] };
$obj->check_structure($o,1);
$e3 = $obj->err();

$o = { a => 1 };
$obj->check_structure($o,1);
$e4 = $obj->err();

$o = { b => { bb => [ 1 ] } };
$obj->check_structure($o,1);
$e5 = $obj->err();

$o = { c => 1 };
$obj->check_structure($o,0);
$e6 = $obj->err();

$o = { b => { cc => [ 1 ] } };
$obj->check_structure($o,1);
$e7 = $obj->err();

$tests = "

CHECK $e1 ~ _blank_

CHECK $e2 ~ _blank_

CHECK $e3 ~ ndschk01

CHECK $e4 ~ ndschk01

CHECK $e5 ~ ndschk01

CHECK $e6 ~ ndschk02

CHECK $e7 ~ _blank_

/a ~ list _blank_

/b ~ hash _blank_

/b/bb ~ scalar _blank_

/b/cc ~ list _blank_

";

print "check_structure...\n";
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

