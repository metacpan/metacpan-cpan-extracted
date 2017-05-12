use warnings;
use strict;
use Data::Float::DoubleDouble qw(:all);

my $t = 12;
print "1..$t\n";

my $in;

############################

$in = +(2**200) + (2**-100);

if(express($in) eq '1.606938044258990275541962092341e+60 + 7.888609052210118054117285652828e-31' ) {
  print "ok 1\n";
}
else {
  warn "\n1: ", express($in), "\n";
  print "not ok 1\n";
}

if(express($in, 'h') eq '+0x1p200 + 0x1p-100' ) {
  print "ok 2\n";
}
else {
  warn "\n2: ", express($in, 'h'), "\n";
  print "not ok 2\n";
}

if(express($in, 'H') eq '+0X1P200 + 0X1P-100' ) {
  print "ok 3\n";
}
else {
  warn "\n3: ", express($in, 'h'), "\n";
  print "not ok 3\n";
}

############################
############################

$in = -(2**200) + (2**-100);

if(express($in) eq '-1.606938044258990275541962092341e+60 + 7.888609052210118054117285652828e-31' ) {
  print "ok 4\n";
}
else {
  warn "\n4: ", express($in), "\n";
  print "not ok 4\n";
}

if(express($in, 'h') eq '-0x1p200 + 0x1p-100' ) {
  print "ok 5\n";
}
else {
  warn "\n5: ", express($in, 'h'), "\n";
  print "not ok 5\n";
}

if(express($in, 'H') eq '-0X1P200 + 0X1P-100' ) {
  print "ok 6\n";
}
else {
  warn "\n6: ", express($in, 'h'), "\n";
  print "not ok 6\n";
}

############################
############################

$in = -(2**200) - (2**-100);

if(express($in) eq '-1.606938044258990275541962092341e+60 - 7.888609052210118054117285652828e-31' ) {
  print "ok 7\n";
}
else {
  warn "\n7: ", express($in), "\n";
  print "not ok 7\n";
}

if(express($in, 'h') eq '-0x1p200 - 0x1p-100' ) {
  print "ok 8\n";
}
else {
  warn "\n8: ", express($in, 'h'), "\n";
  print "not ok 8\n";
}

if(express($in, 'H') eq '-0X1P200 - 0X1P-100' ) {
  print "ok 9\n";
}
else {
  warn "\n9: ", express($in, 'h'), "\n";
  print "not ok 9\n";
}

############################
############################

$in = +(2**200) - (2**-100);

if(express($in) eq '1.606938044258990275541962092341e+60 - 7.888609052210118054117285652828e-31' ) {
  print "ok 10\n";
}
else {
  warn "\n10: ", express($in), "\n";
  print "not ok 10\n";
}

if(express($in, 'h') eq '+0x1p200 - 0x1p-100' ) {
  print "ok 11\n";
}
else {
  warn "\n11: ", express($in, 'h'), "\n";
  print "not ok 11\n";
}

if(express($in, 'H') eq '+0X1P200 - 0X1P-100' ) {
  print "ok 12\n";
}
else {
  warn "\n12: ", express($in, 'h'), "\n";
  print "not ok 12\n";
}

############################
