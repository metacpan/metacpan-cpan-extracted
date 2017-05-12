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
  $obj->set_structure(@test);
  return $obj->err();
}

$obj = new Data::Nested;

$$obj{"struct"} = { "/z"  => { "type"    => "list/hash",
                             },
                  };

$tests = "

type hash / ~ _blank_

type foo /a ~ ndsstr01

type hash /a ~ _blank_

type scalar /a ~ ndsstr02

type scalar /z ~ ndsstr03

type list /z ~ _blank_

foo keep ~ ndsstr99

foo x /a ~ ndsstr98

type list /b ~ _blank_

ordered x /b ~ ndsstr06

ordered 1 /a ~ ndsstr05

ordered 1 /b ~ _blank_

ordered 0 /b ~ ndsstr04

type list /c ~ _blank_

uniform 0 /c ~ _blank_

ordered 0 /c ~ ndsstr04

type list /d ~ _blank_

uniform x /d ~ ndsstr09

type scalar f ~ _blank_

uniform 1 /f ~ ndsstr08

uniform 1 /d ~ _blank_

uniform 0 /d ~ ndsstr07

type list /e ~ _blank_

ordered 0 /e ~ _blank_

uniform 0 /e ~ ndsstr07

type scalar /k ~ _blank_

type hash /k/l/m ~ ndsstr10

type list /g ~ _blank_

uniform 1 /g ~ _blank_

type list /g/1 ~ ndsstr11

type list /g/* ~ _blank_

type list /h ~ _blank_

uniform 0 /h ~ _blank_

type list /h/1 ~ _blank_

type list /h/* ~ ndsstr12

type list /h/foo ~ ndsstr13

type hash /i ~ _blank_

uniform 1 /i ~ _blank_

type list /i/x ~ ndsstr14

type list /i/* ~ _blank_

type hash /j ~ _blank_

uniform 0 /j ~ _blank_

type list /j/x ~ _blank_

type list /j/* ~ ndsstr15

ordered 2 ~ ndsstr16

uniform_hash 2 ~ ndsstr17

uniform_ol 2 ~ ndsstr18

";

print "set_structure...\n";
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

