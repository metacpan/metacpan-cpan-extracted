# Check float_B() output against the mpfr library.
use warnings;
use strict;
use Math::NV qw(:all);
#use Math::MPFR qw(:mpfr);

use Data::Float::DoubleDouble qw(:all);

#$Data::Float::DoubleDouble::debug = 1 if(defined($ARGV[0]) && $ARGV[0] =~ /debug/i);

my $t = 24;

print "1..$t\n";

eval {require Math::MPFR;};
if($@) {
  warn "\n Skipping all tests - couldn't load Math::MPFR.",
       "\n (02_str2mpfr_cross_checks.t requires Math::MPFR)\n";
  print "ok $_\n" for 1..$t;
  exit 0;
}

Math::MPFR::Rmpfr_set_default_prec(2100);
my $rnd = 0; # Math::MPFR's round to nearest

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
    my $str = $curr[0] . random_select($digits) . 'e' . $curr[1] . "$exp";
    my $nv = nv($str);
    my $fr = Math::MPFR->new($nv);

    next if are_inf($nv);
    my ($sign, $mant, $exp) = float_B($nv);
    my $fr_sign;
    my $nv_redone1 = Math::MPFR::Rmpfr_get_NV($fr, $rnd);

    my $nv_redone2 = Math::MPFR::Rmpfr_get_ld($fr, $rnd);



    if($nv_redone1 != $nv_redone2) {
       unless(are_nan($nv_redone1, $nv_redone2)) {
         warn "\nRmpfr_get_NV() and Rmpfr_get_ld() don't match\n",
              "  ", NV2H($nv_redone1), " versus ", NV2H($nv_redone2), "\n";
         die;
       }
    }

    if($nv != $nv_redone2) {
       unless(are_nan($nv, $nv_redone1, $nv_redone2)) {
         warn "\nNV mismatch:\n",
              "  ", NV2H($nv), " vs ", NV2H($nv_redone1), " vs ", NV2H($nv_redone2), "\n";
         die;
       }
    }

    my @out = Math::MPFR::Rmpfr_deref2($fr, 2, 0, $rnd);

    if($out[0] =~ /^\-/) {
      $fr_sign = '-';
      $out[0] =~ s/^\-//;
    }
    else {
      $fr_sign = '+';
      $out[0] =~ s/^\+//;
    }

    if($fr_sign ne $sign) {
      warn "\n$t: $str sign mismatch: $sign $fr_sign" unless $count > 10;
      $ok = 0;
      $count++;
    }

    # Number of trailing zeroes may differ, so remove them from both $mant and $out[0]
    # for comparison purposes.
    my $len = length($mant);
    $mant =~ s/0+$//;
    $mant = '0' if(!length($mant) && $len);
    $len = length($out[0]);
    $out[0] =~ s/0+$//;
    $out[0] = '0' if(!length($out[0]) && $len);

    # M::MPFR and D::F::DD position the implied radix point differently
    # (off by one), so we need to cater for that when comparing results.
    $out[1]--;

    # Also M::MPFR may have leading zeroes that D:::F::DD does not, hence:
    #if($exp > $out[1]) {
    #  $out[0] =substr($out[0], $exp - $out[1]);
    #  $out[1] = $exp;
    #}

    if($mant ne $out[0]) {
      warn "\n$t: $str\n mant mismatch: $mant $out[0]" unless $count > 10;
      $ok = 0;
      $count++;
    }

    if($exp ne $out[1]) {
      if($nv) {
        warn "\n$t: $str exp mismatch: $exp $out[1]\n" unless $count > 10;
        $ok = 0;
      }
    }
  }
}

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}

#############################
} # Close "for(@variants)" loop
#############################


# Finish tests 1-4
# Start tests  5-8


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

for my $exp(298 .. 304) {
  my $str =  $curr[0] . '0.0000000009' . 'e' . $curr[1] . $exp;
  my $nv = nv($str);
  my ($sign, $mant, $exp) = float_B($nv);
  my $fr_sign;

  my $fr = Math::MPFR->new($nv);

  my $nv_redone1 = Math::MPFR::Rmpfr_get_NV($fr, $rnd);
  my $nv_redone2 = Math::MPFR::Rmpfr_get_ld($fr, $rnd);

  if($nv_redone1 != $nv_redone2) {
     unless(are_nan($nv_redone1, $nv_redone2)) {
       warn "\nRmpfr_get_NV() and Rmpfr_get_ld() don't match\n",
            "  ", NV2H($nv_redone1), " versus ", NV2H($nv_redone2), "\n";
       die;
     }
  }

  if($nv != $nv_redone2) {
     unless(are_nan($nv, $nv_redone1, $nv_redone2)) {
       warn "\nNV mismatch:\n",
            "  ", NV2H($nv), " vs ", NV2H($nv_redone1), " vs ", NV2H($nv_redone2), "\n";
       die;
     }
  }

  my @out = Math::MPFR::Rmpfr_deref2($fr, 2, 0, $rnd);
    if($out[0] =~ /^\-/) {
    $fr_sign = '-';
    $out[0] =~ s/^\-//;
  }
  else {
    $fr_sign = '+';
    $out[0] =~ s/^\+//;
  }

  if($fr_sign ne $sign) {
    warn "\n $t: sign mismatch: $sign $fr_sign" unless $count > 10;
    $ok = 0;
    $count++;
  }

  # Number of trailing zeroes may differ, so remove them from both $mant and $out[0]
  # for comparison purposes.
  my $len = length($mant);
  $mant =~ s/0+$//;
  $mant = '0' if(!length($mant) && $len);
  $len = length($out[0]);
  $out[0] =~ s/0+$//;
  $out[0] = '0' if(!length($out[0]) && $len);

  # M::MPFR and D::F::DD position the implied radix point differently
  # (off by one), so we need to cater for that when comparing results.
  # But we need to apply a different adjustment, depending upon whether
  # the most siginifcant NV is de-normalised or not.
  if($exp =~ /^1/) {
    $out[1]--;
  }
  else {
    my $zeroes = $exp - $out[1] + 1;
    $out[0] = ('0' x $zeroes) . $out[0];
    $out[1] = $exp;
  }

  # Also M::MPFR may have leading zeroes that D:::F::DD does not, hence:
  #if($exp > $out[1]) {
  #  warn "\n$str\n\$exp: $exp \$out[1]: $out[1]\n";
  #  $out[0] =substr($out[0], $exp - $out[1]);
  #  $out[1] = $exp;
  #}

  if($mant ne $out[0]) {
    warn "\n$t: $str mant mismatch:\n$mant\n$out[0]" unless $count > 10;
    $ok = 0;
    $count++;
  }

  if($exp ne $out[1]) {
    if($nv) {
      warn "\n$t: exp mismatch: $exp $out[1]\n" unless $count > 10;
      $ok = 0;
    }
  }
}

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}

#############################
} # Close "for(@variants)" loop
#############################


# Finish test 5-8
# Start tests 9-12.


my($nv1, $nv2, $nv3, $nv4) = (2 ** 1023, 2 ** 1000, 2 ** - 1074, 2 ** -1054);

#################################
for my $v(@variants) {
  my($ok, $count) = (1, 0);
  $t++;
  my @curr;
  @curr = ('-1', '-1') if $v == 4;
  @curr = ('+1', '-1') if $v == 2;
  @curr = ('-1', '+1') if $v == 3;
  @curr = ('+1', '+1') if $v == 1;
#################################

  my $nv = ($nv2 + ($nv1 * $curr[0])) + ($nv4 + ($nv3 * $curr[1]));

  my ($sign, $mant, $exp) = float_B($nv);
  my $fr_sign;

  my $fr = Math::MPFR->new($nv);

  # MPFR doesn't reproduce the original value.
  #my $nv_redone1 = Math::MPFR::Rmpfr_get_NV($fr, $rnd);
  #my $nv_redone2 = Math::MPFR::Rmpfr_get_ld($fr, $rnd);
  #
  #if($nv_redone1 != $nv_redone2) {
  #   unless(are_nan($nv_redone1, $nv_redone2)) {
  #     warn "\nRmpfr_get_NV() and Rmpfr_get_ld() don't match\n",
  #          "  ", NV2H($nv_redone1), " versus ", NV2H($nv_redone2), "\n";
  #     die;
  #   }
  #}
  #
  #if($nv != $nv_redone2) {
  #   unless(are_nan($nv, $nv_redone1, $nv_redone2)) {
  #     warn "\nNV mismatch: $curr[0] $curr[1]\n",
  #          "  ", NV2H($nv), " vs ", NV2H($nv_redone1), " vs ", NV2H($nv_redone2), "\n";
  #     die;
  #   }
  #}

  my @out = Math::MPFR::Rmpfr_deref2($fr, 2, 0, $rnd);
    if($out[0] =~ /^\-/) {
    $fr_sign = '-';
    $out[0] =~ s/^\-//;
  }
  else {
    $fr_sign = '+';
    $out[0] =~ s/^\+//;
  }

  if($fr_sign ne $sign) {
    warn "\n $t: sign mismatch: $sign $fr_sign" unless $count > 10;
    $ok = 0;
    $count++;
  }

  # Number of trailing zeroes may differ, so remove them from both $mant and $out[0]
  # for comparison purposes.
  my $len = length($mant);
  $mant =~ s/0+$//;
  $mant = '0' if(!length($mant) && $len);
  $len = length($out[0]);
  $out[0] =~ s/0+$//;
  $out[0] = '0' if(!length($out[0]) && $len);

  # M::MPFR and D::F::DD position the implied radix point differently
  # (off by one), so we need to cater for that when comparing results.
  # But we need to apply a different adjustment, depending upon whether
  # the most siginifcant NV is de-normalised or not.
  if($exp =~ /^1/) {
    $out[1]--;
  }
  else {
    my $zeroes = $exp - $out[1] + 1;
    $out[0] = ('0' x $zeroes) . $out[0];
    $out[1] = $exp;
  }

  # Also M::MPFR may have leading zeroes that D:::F::DD does not, hence:
  #if($exp > $out[1]) {
  #  warn "\n$str\n\$exp: $exp \$out[1]: $out[1]\n";
  #  $out[0] =substr($out[0], $exp - $out[1]);
  #  $out[1] = $exp;
  #}

  if($mant ne $out[0]) {
    warn "\n$t: $nv mant mismatch:\n$mant\n$out[0]" unless $count > 10;
    $ok = 0;
    $count++;
  }

  if($exp ne $out[1]) {
    if($nv) {
      warn "\n$t: exp mismatch: $exp $out[1]\n" unless $count > 10;
      $ok = 0;
    }
  }

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}

#############################
} # Close "for(@variants)" loop
#############################


# Finish tests 9-12
# Start tests 13-16.

#################################
for my $v(@variants) {
  my($ok, $count) = (1, 0);
  $t++;
  my @curr;
  @curr = ('-1', '-1') if $v == 4;
  @curr = ('+1', '-1') if $v == 2;
  @curr = ('-1', '+1') if $v == 3;
  @curr = ('+1', '+1') if $v == 1;
#################################

  my $nv = ($nv2 + ($nv1 * $curr[0])) - ($nv4 + ($nv3 * $curr[1]));

  my ($sign, $mant, $exp) = float_B($nv);
  my $fr_sign;

  my $fr = Math::MPFR->new($nv);

  # MPFR doesn't reproduce the original value.
  #my $nv_redone1 = Math::MPFR::Rmpfr_get_NV($fr, $rnd);
  #my $nv_redone2 = Math::MPFR::Rmpfr_get_ld($fr, $rnd);
  #
  #if($nv_redone1 != $nv_redone2) {
  #   unless(are_nan($nv_redone1, $nv_redone2)) {
  #     warn "\nRmpfr_get_NV() and Rmpfr_get_ld() don't match\n",
  #          "  ", NV2H($nv_redone1), " versus ", NV2H($nv_redone2), "\n";
  #     die;
  #   }
  #}
  #
  #if($nv != $nv_redone2) {
  #   unless(are_nan($nv, $nv_redone1, $nv_redone2)) {
  #     warn "\nNV mismatch: $curr[0] $curr[1]\n",
  #          "  ", NV2H($nv), " vs ", NV2H($nv_redone1), " vs ", NV2H($nv_redone2), "\n";
  #     die;
  #   }
  #}

  my @out = Math::MPFR::Rmpfr_deref2($fr, 2, 0, $rnd);
    if($out[0] =~ /^\-/) {
    $fr_sign = '-';
    $out[0] =~ s/^\-//;
  }
  else {
    $fr_sign = '+';
    $out[0] =~ s/^\+//;
  }

  if($fr_sign ne $sign) {
    warn "\n $t: sign mismatch: $sign $fr_sign" unless $count > 10;
    $ok = 0;
    $count++;
  }

  # Number of trailing zeroes may differ, so remove them from both $mant and $out[0]
  # for comparison purposes.
  my $len = length($mant);
  $mant =~ s/0+$//;
  $mant = '0' if(!length($mant) && $len);
  $len = length($out[0]);
  $out[0] =~ s/0+$//;
  $out[0] = '0' if(!length($out[0]) && $len);

  # M::MPFR and D::F::DD position the implied radix point differently
  # (off by one), so we need to cater for that when comparing results.
  # But we need to apply a different adjustment, depending upon whether
  # the most siginifcant NV is de-normalised or not.
  if($exp =~ /^1/) {
    $out[1]--;
  }
  else {
    my $zeroes = $exp - $out[1] + 1;
    $out[0] = ('0' x $zeroes) . $out[0];
    $out[1] = $exp;
  }

  # Also M::MPFR may have leading zeroes that D:::F::DD does not, hence:
  #if($exp > $out[1]) {
  #  warn "\n$str\n\$exp: $exp \$out[1]: $out[1]\n";
  #  $out[0] =substr($out[0], $exp - $out[1]);
  #  $out[1] = $exp;
  #}

  if($mant ne $out[0]) {
    warn "\n$t: $nv mant mismatch:\n$mant\n$out[0]" unless $count > 10;
    $ok = 0;
    $count++;
  }

  if($exp ne $out[1]) {
    if($nv) {
      warn "\n$t: exp mismatch: $exp $out[1]\n" unless $count > 10;
      $ok = 0;
    }
  }

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}

#############################
} # Close "for(@variants)" loop
#############################


# Finish tests 13-16
# Start tests 17-20

#################################
for my $v(@variants) {
  my($ok, $count) = (1, 0);
  $t++;
  my @curr;
  @curr = ('-1', '-1') if $v == 4;
  @curr = ('+1', '-1') if $v == 2;
  @curr = ('-1', '+1') if $v == 3;
  @curr = ('+1', '+1') if $v == 1;
#################################

  my $nv = ($nv1 * $curr[0]) + ($nv3 * $curr[1]);

  my ($sign, $mant, $exp) = float_B($nv);
  my $fr_sign;

  my $fr = Math::MPFR->new($nv);

  # MPFR doesn't reproduce the original value.
  #my $nv_redone1 = Math::MPFR::Rmpfr_get_NV($fr, $rnd);
  #my $nv_redone2 = Math::MPFR::Rmpfr_get_ld($fr, $rnd);
  #
  #if($nv_redone1 != $nv_redone2) {
  #   unless(are_nan($nv_redone1, $nv_redone2)) {
  #     warn "\nRmpfr_get_NV() and Rmpfr_get_ld() don't match\n",
  #          "  ", NV2H($nv_redone1), " versus ", NV2H($nv_redone2), "\n";
  #     die;
  #   }
  #}
  #
  #if($nv != $nv_redone2) {
  #   unless(are_nan($nv, $nv_redone1, $nv_redone2)) {
  #     warn "\nNV mismatch: $curr[0] $curr[1]\n",
  #          "  ", NV2H($nv), " vs ", NV2H($nv_redone1), " vs ", NV2H($nv_redone2), "\n";
  #     die;
  #   }
  #}

  my @out = Math::MPFR::Rmpfr_deref2($fr, 2, 0, $rnd);
    #if($t == 18 || $t == 19) {
    #  print "\n$sign $exp\n$mant\n$out[0]\n$out[1]\n";
    #}
    if($out[0] =~ /^\-/) {
    $fr_sign = '-';
    $out[0] =~ s/^\-//;
  }
  else {
    $fr_sign = '+';
    $out[0] =~ s/^\+//;
  }

  if($fr_sign ne $sign) {
    warn "\n $t: sign mismatch: $sign $fr_sign" unless $count > 10;
    $ok = 0;
    $count++;
  }

  # Number of trailing zeroes may differ, so remove them from both $mant and $out[0]
  # for comparison purposes.
  my $len = length($mant);
  $mant =~ s/0+$//;
  $mant = '0' if(!length($mant) && $len);
  $len = length($out[0]);
  $out[0] =~ s/0+$//;
  $out[0] = '0' if(!length($out[0]) && $len);

  # M::MPFR and D::F::DD position the implied radix point differently
  # (off by one), so we need to cater for that when comparing results.
  # But we need to apply a different adjustment, depending upon whether
  # the most siginifcant NV is de-normalised or not.
  if($exp =~ /^1/) {
    $out[1]--;
  }
  else {
    my $zeroes = $exp - $out[1] + 1;
    $out[0] = ('0' x $zeroes) . $out[0];
    $out[1] = $exp;
  }

  # Also M::MPFR may have leading zeroes that D:::F::DD does not, hence:
  #if($exp > $out[1]) {
  #  warn "\n$str\n\$exp: $exp \$out[1]: $out[1]\n";
  #  $out[0] =substr($out[0], $exp - $out[1]);
  #  $out[1] = $exp;
  #}

  if($mant ne $out[0]) {
    warn "\n$t: $nv mant mismatch:\n$mant\n$out[0]" unless $count > 10;
    $ok = 0;
    $count++;
  }

  if($exp ne $out[1]) {
    if($nv) {
      warn "\n$t: exp mismatch: $exp $out[1]\n" unless $count > 10;
      $ok = 0;
    }
  }

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}

#############################
} # Close "for(@variants)" loop
#############################


# Finish tests 17-20
# Start tests 21-24

#################################
for my $v(@variants) {
  my($ok, $count) = (1, 0);
  $t++;
  my @curr;
  @curr = ('-1', '-1') if $v == 4;
  @curr = ('+1', '-1') if $v == 2;
  @curr = ('-1', '+1') if $v == 3;
  @curr = ('+1', '+1') if $v == 1;
#################################

  my $nv = ($nv2 * $curr[0]) + ($nv4 * $curr[1]);

  my ($sign, $mant, $exp) = float_B($nv);
  my $fr_sign;

  my $fr = Math::MPFR->new($nv);

  # MPFR doesn't reproduce the original value.
  #my $nv_redone1 = Math::MPFR::Rmpfr_get_NV($fr, $rnd);
  #my $nv_redone2 = Math::MPFR::Rmpfr_get_ld($fr, $rnd);
  #
  #if($nv_redone1 != $nv_redone2) {
  #   unless(are_nan($nv_redone1, $nv_redone2)) {
  #     warn "\nRmpfr_get_NV() and Rmpfr_get_ld() don't match\n",
  #          "  ", NV2H($nv_redone1), " versus ", NV2H($nv_redone2), "\n";
  #     die;
  #   }
  #}
  #
  #if($nv != $nv_redone2) {
  #   unless(are_nan($nv, $nv_redone1, $nv_redone2)) {
  #     warn "\nNV mismatch: $curr[0] $curr[1]\n",
  #          "  ", NV2H($nv), " vs ", NV2H($nv_redone1), " vs ", NV2H($nv_redone2), "\n";
  #     die;
  #   }
  #}

  my @out = Math::MPFR::Rmpfr_deref2($fr, 2, 0, $rnd);
    #if($t == 22 || $t == 23) {
    #  print "\n$sign $exp\n$mant\n$out[0]\n$out[1]\n";
    #}
    if($out[0] =~ /^\-/) {
    $fr_sign = '-';
    $out[0] =~ s/^\-//;
  }
  else {
    $fr_sign = '+';
    $out[0] =~ s/^\+//;
  }

  if($fr_sign ne $sign) {
    warn "\n $t: sign mismatch: $sign $fr_sign" unless $count > 10;
    $ok = 0;
    $count++;
  }

  # Number of trailing zeroes may differ, so remove them from both $mant and $out[0]
  # for comparison purposes.
  my $len = length($mant);
  $mant =~ s/0+$//;
  $mant = '0' if(!length($mant) && $len);
  $len = length($out[0]);
  $out[0] =~ s/0+$//;
  $out[0] = '0' if(!length($out[0]) && $len);

  # M::MPFR and D::F::DD position the implied radix point differently
  # (off by one), so we need to cater for that when comparing results.
  # But we need to apply a different adjustment, depending upon whether
  # the most siginifcant NV is de-normalised or not.
  if($exp =~ /^1/) {
    $out[1]--;
  }
  else {
    my $zeroes = $exp - $out[1] + 1;
    $out[0] = ('0' x $zeroes) . $out[0];
    $out[1] = $exp;
  }

  # Also M::MPFR may have leading zeroes that D:::F::DD does not, hence:
  #if($exp > $out[1]) {
  #  warn "\n$str\n\$exp: $exp \$out[1]: $out[1]\n";
  #  $out[0] =substr($out[0], $exp - $out[1]);
  #  $out[1] = $exp;
  #}

  if($mant ne $out[0]) {
    warn "\n$t: $nv mant mismatch:\n$mant\n$out[0]" unless $count > 10;
    $ok = 0;
    $count++;
  }

  if($exp ne $out[1]) {
    if($nv) {
      warn "\n$t: exp mismatch: $exp $out[1]\n" unless $count > 10;
      $ok = 0;
    }
  }

if($ok) {print "ok $t\n"}
else {print "not ok $t\n"}

#############################
} # Close "for(@variants)" loop
#############################


# Finish tests 21-24

sub random_select {
  my $ret = '';
  for(1 .. $_[0]) {
    $ret .= int(rand(10));
  }
  return $ret;
}

__END__

