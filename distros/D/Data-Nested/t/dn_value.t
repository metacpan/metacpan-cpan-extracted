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
  $val    = $obj->value($nds,@test);
  $err    = $obj->err();
  return($err,$val);
}

$obj = new Data::Nested;
$nds = { "a" => undef,
         "b" => "foo",
         "c" => [ "c1", "c2" ],
         "d" => { "d1k" => "d1v", "d2k" => "d2v" },
         "e" => \&foo,
         "g" => [ undef ],
       };

$tests = "
/a ~ _blank_ _undef_

/a/b ~ ndsdat01 _undef_

/x ~ ndsdat02 _undef_

/d/d3k ~ ndsdat02 _undef_

/c/2 ~ ndsdat03 _undef_

/b/x ~ ndsdat04 _undef_

/e/x ~ ndsdat05 _undef_

/c/x ~ ndsdat06 _undef_

/b ~ _blank_ foo

/c/1 ~ _blank_ c2

/d/d2k ~ _blank_ d2v

/f/1/2 ~ ndsdat02 _undef_

/g/0 ~ _blank_ _undef_

";

print "value...\n";
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

