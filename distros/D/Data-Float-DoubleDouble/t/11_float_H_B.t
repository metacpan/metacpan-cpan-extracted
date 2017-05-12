# Here we check that the hex format returned by float_H converts to binary and
# and back again correctly (using float_H2B and B2float_H).

use warnings;
use strict;
use Math::NV qw(:all);
use Data::Float::DoubleDouble qw(:all);

my $t = 12;

print "1..$t\n";

$t = 0;

my @variants = (1,2,3,4);

#################################
for my $v(@variants) {
  my($ok, $count) = (1, 0);
  $t++;
  my @curr;
  @curr = ('-', '-') if $v == 1;
  @curr = ('+', '-') if $v == 2;
  @curr = ('-', '+') if $v == 3;
  @curr = ('+', '+') if $v == 4;
#################################

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = $curr[0] . random_select($digits) . 'e' . $curr[1] . $exp;
    my $nv = nv($str);
    #next if(!$nv || are_inf($nv));
    my @bin = float_B($nv);
    my $hex = float_H($nv);

    my @check = float_H2B($hex);

    if($check[0] ne $bin[0]) {
      $ok = 0;
      $count++;
      warn "$str: sign: $bin[0] $check[0]\n"
        unless $count > 10;
    }

    if($check[1] ne $bin[1]) {
      $ok = 0;
      $count++;
      warn "$str: mant:\n$bin[1]\n$check[1]\n"
        unless $count > 10;
    }

    if($check[2] ne $bin[2]) {
      $ok = 0;
      $count++;
      warn "$str: exp: $bin[2] $check[2]\n"
        unless $count > 10;
    }

  }
}

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}

#############################
} # Close "for(@variants)" loop
#############################


# Finish tests 1-4
# Begin tests 5-6

#################################
for my $v(1 .. 2) {
  my($ok, $count) = (1, 0);
  $t++;
#################################


for my $exp(298 .. 304) {
  my $str = '0.0000000009' . "e-$exp";
  my $nv = nv($str);
  $nv *= -1.0 if $v == 2;
  #next if(!$nv || are_inf($nv));
  my @bin = float_B($nv);
  my $hex = float_H($nv);

  my @check = float_H2B($hex);

  if($check[0] ne $bin[0]) {
    $ok = 0;
    $count++;
    warn "$str: sign: $bin[0] $check[0]\n"
      unless $count > 10;
  }

  if($check[1] ne $bin[1]) {
    $ok = 0;
    $count++;
    warn "$str: mant:\n$bin[1]\n$check[1]\n"
      unless $count > 10;
  }

  if($check[2] ne $bin[2]) {
    $ok = 0;
    $count++;
    warn "$str: exp: $bin[2] $check[2]\n"
      unless $count > 10;
  }

}

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}

#############################
} # Close "for (1 .. 2)" loop
#############################

# Finish tests 5-6

##############################
##############################
# Now do the same, but don't
# assign using nv()
##############################
##############################

# Begin tests 7-10

#################################
for my $v(@variants) {
  my($ok, $count) = (1, 0);
  $t++;
  my @curr;
  @curr = ('-', '-') if $v == 1;
  @curr = ('+', '-') if $v == 2;
  @curr = ('-', '+') if $v == 3;
  @curr = ('+', '+') if $v == 4;
#################################

for my $exp(0..10, 20, 30, 280 .. 300) {
  for my $digits(1..15) {
    my $str = $curr[0] . random_select($digits) . 'e' . $curr[1] . $exp;
    my $nv = $str + 0.0;
    #next if(!$nv || are_inf($nv));
    my @bin = float_B($nv);
    my $hex = float_H($nv);

    my @check = float_H2B($hex);

    if($check[0] ne $bin[0]) {
      $ok = 0;
      $count++;
      warn "$str: sign: $bin[0] $check[0]\n"
        unless $count > 10;
    }

    if($check[1] ne $bin[1]) {
      $ok = 0;
      $count++;
      warn "$str: mant:\n$bin[1]\n$check[1]\n"
        unless $count > 10;
    }

    if($check[2] ne $bin[2]) {
      $ok = 0;
      $count++;
      warn "$str: exp: $bin[2] $check[2]\n"
        unless $count > 10;
    }

  }
}

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}

#############################
} # Close "for(@variants)" loop
#############################


# Finish tests 7-10
# Begin tests 11-12

#################################
for my $v(1 .. 2) {
  my($ok, $count) = (1, 0);
  $t++;
#################################


for my $exp(298 .. 304) {
  my $str = '0.0000000009' . "e-$exp";
  my $nv = $str + 0.0;
  $nv *= -1.0 if $v == 2;
  #next if(!$nv || are_inf($nv));
  my @bin = float_B($nv);
  my $hex = float_H($nv);

  my @check = float_H2B($hex);

  if($check[0] ne $bin[0]) {
    $ok = 0;
    $count++;
    warn "$str: sign: $bin[0] $check[0]\n"
      unless $count > 10;
  }

  if($check[1] ne $bin[1]) {
    $ok = 0;
    $count++;
    warn "$str: mant:\n$bin[1]\n$check[1]\n"
      unless $count > 10;
  }

  if($check[2] ne $bin[2]) {
    $ok = 0;
    $count++;
    warn "$str: exp: $bin[2] $check[2]\n"
      unless $count > 10;
  }

}

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}

#############################
} # Close "for (1 .. 2)" loop
#############################

#print float_H(scalar nv('602744e-4')), "\n";
#print float_H(602744e-4), "\n";
#print float_H((2 ** 1023) + (2 ** -1074)), "\n";
#print float_H((2 ** 1023) + (2 ** -1070)), "\n";
#print float_H((2 ** 1023) - (2 ** -1074)), "\n";
#print float_H((2 ** 1023) - (2 ** -1070)), "\n";

##############################
##############################

sub random_select {
  my $ret = '';
  for(1 .. $_[0]) {
    $ret .= int(rand(10));
  }
  return $ret;
}

