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
  return $obj->get_merge(@test);
}

$obj = new Data::Nested;
$obj->ruleset("REPL");

$obj->set_structure("type","hash","/h");
$obj->set_merge    ("merge","/h","keep");
$obj->set_merge    ("merge","/h","replace","REPL");

$obj->set_structure("type","scalar","/s");

$tests = "

/h ~ keep

/h REPL ~ replace

/s ~ keep

/s REPL ~ keep

";

print "get_merge...\n";
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

