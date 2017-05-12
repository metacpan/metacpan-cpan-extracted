use strict;
use warnings;
use Data::Float::DoubleDouble qw(:all);
no warnings 'once';

my $t = 15;

print "1..$t\n";

my $nv = 0.0;

my $max = $Data::Float::DoubleDouble::max_fin;
my $min = $Data::Float::DoubleDouble::min_fin;
my $peps = $Data::Float::DoubleDouble::pos_eps;
my $neps = $Data::Float::DoubleDouble::neg_eps;

my $pinf = H2NV('7ff00000000000000000000000000000');
my $ninf = H2NV('fff00000000000000000000000000000');
my $pnan = H2NV('7ff80000000000000000000000000000');
my $nnan = H2NV('fff80000000000008000000000000000');

if(nextup($nv) == $peps) {print "ok 1\n"}
else {
  warn "\n1: Got ", nextup($nv), "\n";
  print "not ok 1\n";
}

if(nextdown($nv) == $neps) {print "ok 2\n"}
else {
  warn "\n2: Got ", nextdown($nv), "\n";
  print "not ok 2\n";
}

if(nextafter($nv, 1.0) == 2 ** -1074) {print "ok 3\n"}
else {
  warn "\n3: Got ", nextup($nv), "\n";
  print "not ok 3\n";
}

if(nextafter($nv, -1.0) == -(2 ** -1074)) {print "ok 4\n"}
else {
  warn "\n4: Got ", nextdown($nv), "\n";
  print "not ok 4\n";
}



if(are_inf(nextup($max))) {print "ok 5\n"}
else {
  warn "\n5: ", nextup($max), "\n";
  print "not ok 5\n";
}

if(are_inf(nextdown($min))) {print "ok 6\n"}
else {
  warn "\n6: ", nextdown($min), "\n";
  print "not ok 6\n";
}


if(are_inf(nextafter($max, $pinf))) {print "ok 7\n"}
else {
  warn "\n7: ", nextafter($max, $pinf), "\n";
  print "not ok 7\n";
}

if(are_inf(nextafter($min, $ninf))) {print "ok 8\n"}
else {
  warn "\n8: ", nextafter($min, $ninf), "\n";
  print "not ok 8\n";
}

if(nextup($ninf) == $min && are_inf($ninf) && !are_inf($min)) {print "ok 9\n"}
else {
  warn "\n9: ", nextup($ninf), "\n";
  print "not ok 9\n";
}

if(nextdown($pinf) == $max && are_inf($pinf) && !are_inf($max)) {print "ok 10\n"}
else {
  warn "\n10: ", nextup($ninf), "\n";
  print "not ok 10\n";
}

if(nextafter($ninf, 0) == $min  && are_inf($ninf) && !are_inf($min)) {print "ok 11\n"}
else {
  warn "\n11: ", nextup($ninf), "\n";
  print "not ok 11\n";
}

if(nextafter($pinf, 0) == $max && are_inf($pinf) && !are_inf($max)) {print "ok 12\n"}
else {
  warn "\n12: ", nextup($ninf), "\n";
  print "not ok 12\n";
}

if(
  are_nan(
         nextup($pnan), nextdown($pnan), nextafter($pnan, 1.3),
         nextup($nnan), nextdown($nnan), nextafter($nnan, 3.4),
         nextafter($pinf, $pnan), nextafter($pnan, $pinf), nextafter($pnan, $nnan)
         )
  ) {print "ok 13\n"}
else {
  warn "\n13: ",  nextup($pnan), nextdown($pnan), nextafter($pnan, 1.3),
         nextup($nnan), nextdown($nnan), nextafter($nnan, 3.4),
         nextafter($pinf, $pnan), nextafter($pnan, $pinf), nextafter($pnan, $nnan), "\n";
  print "not ok 13\n";
}

my $cc = 2 ** 1023;
$cc += (2 ** -200) - (2 ** -1074);
$cc -= (2 ** -252) - (2 ** -1074);

my $nextup_cc = nextup($cc);

if($nextup_cc == $cc + (2 ** -253)) {print "ok 14\n"}
else {
  warn "\n14: ", $nextup_cc - $cc, "\n";
  print "not ok 14\n";
}

my $nextdown_cc = nextdown($cc);

if($nextdown_cc == $cc - (2 ** -252) + (2 ** -253)) {print "ok 15\n"}
else {
  my @bin = float_B($cc);
  warn "\n15: ", $nextdown_cc - $cc, "\n";
  print "not ok 15\n";
}
