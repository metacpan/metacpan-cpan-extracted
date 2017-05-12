# Check that infs, nans, and zeroes are being handled correctly.
use strict;
use warnings;
use Data::Float::DoubleDouble qw(:all);

my $t = 14;

print "1..$t\n";

$t = 1;

my $p_zero = 0;
my $n_zero = H2NV('80000000000000000000000000000000');

if($p_zero == $n_zero) {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

if(NV2H($p_zero) eq '00000000000000000000000000000000') {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

if(NV2H($n_zero) eq '80000000000000000000000000000000') {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

my $p_inf = 'inf' + 0;
my $n_inf = $p_inf * -1.0;

if($p_inf == $n_inf * -1) {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

if(are_inf($p_inf, $n_inf)) {print "ok $t\n"}
else {
  warn "\nNot an Inf: $p_inf $n_inf\n";
  print "not ok $t\n";
}
$t++;

if(NV2H($p_inf) eq '7ff00000000000000000000000000000') {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

if(NV2H($n_inf) eq 'fff00000000000000000000000000000') {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

my $p_nan = 'inf' / 'inf';
my $n_nan = -('inf' / 'inf');

if(are_nan($p_nan, $n_nan)) {print "ok $t\n"}
else {
  warn "\nNot a NaN: $p_nan $n_nan\n";
  print "not ok $t\n";
}
$t++;

if($p_nan != $p_nan) {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

if($p_nan != $n_nan) {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

if($n_nan != $n_nan) {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

if(NV2H($p_nan) eq '7ff80000000000000000000000000000') {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

if(NV2H($n_nan) eq 'fff80000000000008000000000000000') {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;

my $ok = 1;

for my $nv($p_zero, $n_zero, $p_inf, $n_inf, $p_nan, $n_nan) {
  my $h = float_H($nv);
  my $nv_redone = H_float($h);
  my $h_redone = float_H($nv_redone);

  unless(are_nan($nv, $nv_redone)) {
    if($nv != $nv_redone) {
      warn "\nNV mismatch: $nv $nv_redone\n";
      $ok = 0;
    }
  }

  if($h ne $h_redone) {
    warn "\nHex mismatch for $nv:\n$h\n$h_redone\n";
    $ok = 0;
  }
}

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}
$t++;
