use strict;
use warnings;
use Data::Float::DoubleDouble qw(:all);

print "1..2\n";

my($d1, $d2) = get_doubles((2 ** 1023) + (2 ** -1074));

if($d1 == 2 ** 1023) {print "ok 1\n"}
else {
  warn "Most significant double: $d1\n";
  print "not ok 1\n";
}

if($d2 == 2 ** -1074) {print "ok 2\n"}
else {
  warn "Least significant double: $d2\n";
  print "not ok 2\n";
}
