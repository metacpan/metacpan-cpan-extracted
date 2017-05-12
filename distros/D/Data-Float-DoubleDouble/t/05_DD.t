use strict;
use warnings;
use Data::Float::DoubleDouble qw(:all);

print "1..1\n";

my ($ok, $ret) = (1, 0);

eval {$ret = DD_FLT_RADIX();};
if($@) {
  warn "\nDD_FLT_RADIX: $@";
  $ok = 0;
}
else {
  print STDERR "\nFLT_RADIX: $ret";
}

eval {$ret = DD_LDBL_MAX();};
if($@) {
  warn "\nDD_LDBL_MAX: $@";
  $ok = 0;
}
else {
  print STDERR "\nLDBL_MAX: $ret";
}

eval {$ret = DD_LDBL_MIN();};
if($@) {
  warn "\nDD_LDBL_MIN: $@";
  $ok = 0;
}
else {
  print STDERR "\nLDBL_MIN: $ret";
}

eval {$ret = DD_LDBL_DIG();};
if($@) {
  warn "\nDD_LDBL_DIG: $@";
  $ok = 0;
}
else {
  print STDERR "\nLDBL_DIG: $ret";
}

eval {$ret = DD_LDBL_MANT_DIG();};
if($@) {
  warn "\nDD_LDBL_MANT_DIG: $@";
  $ok = 0;
}
else {
  print STDERR "\nLDBL_MANT_DIG: $ret";
}

eval {$ret = DD_LDBL_MIN_EXP();};
if($@) {
  warn "\nDD_LDBL_MIN_EXP: $@";
  $ok = 0;
}
else {
  print STDERR "\nLDBL_MIN_EXP: $ret";
}

eval {$ret = DD_LDBL_MAX_EXP();};
if($@) {
  warn "\nDD_LDBL_MAX_EXP: $@";
  $ok = 0;
}
else {
  print STDERR "\nLDBL_MAX_EXP: $ret";
}

eval {$ret = DD_LDBL_MIN_10_EXP();};
if($@) {
  warn "\nDD_LDBL_MIN_10_EXP: $@";
  $ok = 0;
}
else {
  print STDERR "\nLDBL_MIN_10_EXP: $ret";
}

eval {$ret = DD_LDBL_MAX_10_EXP();};
if($@) {
  warn "\nDD_LDBL_MAX_10_EXP: $@";
  $ok = 0;
}
else {
  print STDERR "\nLDBL_MAX_10_EXP: $ret";
}

eval {$ret = DD_LDBL_EPSILON();};
if($@) {
  warn "\nDD_LDBL_EPSILON: $@";
  $ok = 0;
}
else {
  print STDERR "\nLDBL_EPSILON: $ret";
}

eval {$ret = DD_LDBL_DECIMAL_DIG();};
if($@) {
  warn "\nDD_LDBL_DECIMAL_DIG: $@";
  $ok = 0;
}
else {
  defined $ret ? print STDERR "\nLDBL_DECIMAL_DIG: $ret"
               : print STDERR "\nLDBL_DECIMAL_DIG: undef";
}

eval {$ret = DD_LDBL_HAS_SUBNORM();};
if($@) {
  warn "\nDD_LDBL_HAS_SUBNORM: $@";
  $ok = 0;
}
else {
  defined $ret ? print STDERR "\nLDBL_HAS_SUBNORM: $ret"
               : print STDERR "\nLDBL_HAS_SUBNORM: undef";
}

eval {$ret = DD_LDBL_TRUE_MIN();};
if($@) {
  warn "\nDD_LDBL_TRUE_MIN: $@";
  $ok = 0;
}
else {
  defined $ret ? print STDERR "\nLDBL_TRUE_MIN: $ret"
               : print STDERR "\nLDBL_TRUE_MIN: undef";
}

print STDERR "\n";

if($ok) {print "ok 1\n"}
else {print "not ok 1\n"}


