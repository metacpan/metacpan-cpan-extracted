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
  my $nds = pop(@test);
  return $obj->values($nds,@test);
}

$obj = new Data::Nested;
$nds = { "b" => "foo",
         "c" => [ "c1", "c2" ],
         "d" => { "d1k" => "d1v", "d2k" => "d2v" },
       };

$tests = "

/b ~ foo

/c ~ c1 c2

/d ~ d1v d2v

";

print "values...\n";
test_Func(\&test,$tests,$runtests,$nds);

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

