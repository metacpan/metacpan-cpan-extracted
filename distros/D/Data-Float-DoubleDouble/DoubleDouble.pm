package Data::Float::DoubleDouble;
use warnings;
use strict;
use Config;

require 5.010;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

use subs qw(DD_FLT_RADIX DD_LDBL_MAX DD_LDBL_MIN DD_LDBL_DIG DD_LDBL_MANT_DIG
            DD_LDBL_MIN_EXP DD_LDBL_MAX_EXP DD_LDBL_MIN_10_EXP DD_LDBL_MAX_10_EXP
            DD_LDBL_EPSILON DD_LDBL_DECIMAL_DIG DD_LDBL_HAS_SUBNORM DD_LDBL_TRUE_MIN);

@Data::Float::DoubleDouble::EXPORT_OK = qw(
 DD_FLT_RADIX DD_LDBL_MAX DD_LDBL_MIN DD_LDBL_DIG DD_LDBL_MANT_DIG
 DD_LDBL_MIN_EXP DD_LDBL_MAX_EXP DD_LDBL_MIN_10_EXP DD_LDBL_MAX_10_EXP
 DD_LDBL_EPSILON DD_LDBL_DECIMAL_DIG DD_LDBL_HAS_SUBNORM DD_LDBL_TRUE_MIN
 NV2H H2NV D2H H2D DD2HEX std_float_H LD2H H2LD
 get_sign get_exp get_doubles get_mant_H float_H H_float inter_zero are_inf are_nan
 float_H2B B2float_H standardise_bin_mant hex_float float_hex float_B B_float
 valid_hex valid_bin valid_unpack express NV2binary
 float_is_infinite float_is_nan float_is_finite float_is_zero float_is_nzfinite
 float_is_normal float_is_subnormal float_class dd_bytes
 nextafter nextup nextdown);

%Data::Float::DoubleDouble::EXPORT_TAGS = (all =>[qw(
 DD_FLT_RADIX DD_LDBL_MAX DD_LDBL_MIN DD_LDBL_DIG DD_LDBL_MANT_DIG
 DD_LDBL_MIN_EXP DD_LDBL_MAX_EXP DD_LDBL_MIN_10_EXP DD_LDBL_MAX_10_EXP
 DD_LDBL_EPSILON DD_LDBL_DECIMAL_DIG DD_LDBL_HAS_SUBNORM DD_LDBL_TRUE_MIN
 NV2H H2NV D2H H2D DD2HEX std_float_H LD2H H2LD
 get_sign get_exp get_doubles get_mant_H float_H H_float inter_zero are_inf are_nan
 float_H2B B2float_H standardise_bin_mant float_hex hex_float float_B B_float
 valid_hex valid_bin valid_unpack express NV2binary
 float_is_infinite float_is_nan float_is_finite float_is_zero float_is_nzfinite
 float_is_normal float_is_subnormal float_class dd_bytes
 nextafter nextup nextdown)]);

# Maximum finite ($max_fin) is actually:
#   2**1023 + 2**1022 + 2**1021 ....  + 2**919 + 2**918 + 2**917 - 2 ** 970
# but you can't calcualte it that way. (See _get_biggest() for the calculation.)
# On my machine this equals LDBL_MAX + 2**917.
# LDBL_MAX is set to the biggest representable 106-bit number,
# whereas $max_fin is a 107-bit value. Certainly, if we increment $max_fin by
# the smallest amount that will actually alter it (ie by 2**916), then we get Inf.

$Data::Float::DoubleDouble::pos_eps = 2 ** -1074;
$Data::Float::DoubleDouble::neg_eps = -(2 ** -1074);
$Data::Float::DoubleDouble::max_fin =  H2NV('7fefffffffffffff7c8fffffffffffff');
$Data::Float::DoubleDouble::min_fin = $Data::Float::DoubleDouble::max_fin * -1;

our $VERSION = '1.09';
#$VERSION = eval $VERSION;
DynaLoader::bootstrap Data::Float::DoubleDouble $VERSION;

#$Data::Float::DoubleDouble::debug = 0;
#$Data::Float::DoubleDouble::pack = $Config{nvtype} eq 'double' ? "F<" : "D<";

### NOTE ###
# The biggest representable power of 2 in a double is 2 **  1023  ('1' followed by '0' x 1023)
# The least representable power of 2 in a double is   2 **  -1074 ('1' preceded by '0' x 1073)
# The double-double is capable of exactly encapsulating the sum of those 2 values
# Binary representation is '1' . '0' x 2096 . '1', with implied radix point after the 1023rd '0'.
# inter_zero() for such a number returns 1992, which is 2096 - (2 * 52).

##############################
##############################
# A function to return the hex representation of the NV:

sub NV2H {

  return scalar reverse unpack "h*", pack "F<", $_[0];

}

##############################
##############################
# A function to return an NV from the hex representation provided by NV2H().

sub H2NV {

  return unpack "F<", pack "h*", scalar reverse $_[0];

}

##############################
##############################
# A function to return the hex representation of a double:

sub D2H {

  return scalar reverse unpack "h*", pack "d<", $_[0];

}

##############################
##############################
# A function to return a double from the hex representation provided by D2H().

sub H2D {

  return unpack "d<", pack "h*", scalar reverse $_[0];

}

##############################
##############################
# A function to return the hex representation of a long double.
# Works only if the NV is of type long double, whereupon it returns the same as NV2H().

sub LD2H {

  return scalar reverse unpack "h*", pack "D<", $_[0];

}

##############################
##############################
# A function to return a long double from the hex representation provided by LD2H().
# works only if the NV is of type long double, whereupon it returns the same as H2NV().

sub H2LD {

  return unpack "D<", pack "h*", scalar reverse $_[0];

}

##############################
##############################
# A function to return the signs of the NV

sub get_sign {

  my $hex = NV2H($_[0]);

  my $sign1 = hex(substr($hex,  0, 1)) >= 8 ? '-' : '+';
  my $sign2 = hex(substr($hex, 16, 1)) >= 8 ? '-' : '+';
  return ($sign1, $sign2);

}

##############################
##############################
# A function to return the exponents of the NV

sub get_exp {

  my $hex = NV2H($_[0]);

  my $exp1 = hex(substr($hex, 0, 3));
  my $exp2 = hex(substr($hex, 16, 3));

  $exp1 -= 2048 if $exp1 > 2047; # Remove sign bit
  $exp2 -= 2048 if $exp2 > 2047; # Remove sign bit

  $exp1++ unless $exp1; # increment if 0
  $exp2++ unless $exp2; # increment if 0

  return ($exp1 - 1023, $exp2 - 1023);

}

##############################
##############################
# Return the 2 doubles encapsulated in the given doubledouble.

sub get_doubles {
  my $ld_hex = NV2H($_[0]);
  return (H2D(substr($ld_hex, 0, 16)), H2D(substr($ld_hex, 16, 16)));
}

##############################
##############################
# Return the (hex) mantissas of the 2 doubles.
# Does not return the leading (implied) bit, but
# returns the hex representation of the next 52 bits.

sub get_mant_H {

  my $hex = shift;
  return (substr($hex, 3, 13), substr($hex,19, 13));

}

##############################
##############################
# Return a 3-element list for the given double-double:
# 1) sign
# 2) mantissa (in binary, implicit radix point after first digit)
# 3) exponent
# For nan/inf, the mantissa is 'nan' or 'inf' respectively unless
# 2nd arg is literally 'raw'.

sub float_B {
  my $hex = NV2H($_[0]);

  my $raw = @_ == 2 && $_[1] eq 'raw' ? 1 : 0;

  # If the 2nd arg is 'raw' we do the calculations for the arg
  # even if it is an Inf/NaN.
  unless($raw) {
    if($hex eq '7ff00000000000000000000000000000') { # +inf
      return ('+', 'inf', 1024);
    }
    if($hex eq 'fff00000000000000000000000000000') { # -inf
      return ('-', 'inf', 1024);
    }
    if($hex eq '7ff80000000000000000000000000000') { # + nan
      return ('+', 'nan', 1024);
    }
    if($hex eq 'fff80000000000008000000000000000') { # - nan
      return ('-', 'nan', 1024);
    }
  }

  my $pre1 = hex(substr($hex, 0, 3));
  my $pre2 = hex(substr($hex, 16, 3));
  my $discard = 0;

  my ($sign1, $sign2) = ('+', '+');

  if($pre1 > 2047) {
    $pre1 -= 2048;
    $sign1 = '-';
  }

  my $single_sign = $sign1;

  if($pre2 > 2047) {
    $pre2 -= 2048;
    $sign2 = '-';
  }

  my($s1, $s2) = get_mant_H($hex);

  die "\$s1 is too long: ", length($s1)
    if length $s1 > 13;

  die "\$s2 is too long: ", length($s2)
    if length $s2 > 13;

  my $bin_str1 = unpack("B52", (pack "H*", $s1));
  my $bin_str2 = unpack("B52", (pack "H*", $s2));

  my $sign_compare;

  # Check whether either string is zero and modify signs accordingly
  # Check $bin_str2 *first*
  $sign2 = $sign1 if ($bin_str2 !~ /1/ && !$pre2);
  $sign1 = $sign2 if ($bin_str1 !~ /1/ && !$pre1);

  my $bin_pre1 = $pre1 ? '1' : '0';

  $pre1++ unless $pre1;

  my $bin_pre2 = $pre2 ? '1' : '0';
  $pre2++ unless $pre2;

  my($exp1, $exp2) = ($pre1 - 1023, $pre2 - 1023);
  my $inter_zero = inter_zero($exp1, $exp2);
  # Need to avoid warning here with 5.22 if $inter_zero < 0.
  my $zeroes = $inter_zero > 0 ? '0' x $inter_zero
                               : '';

  if($inter_zero < 0) {
    $bin_pre2 = '';
    $inter_zero++;
    $bin_str2 = substr($bin_str2, $inter_zero * -1);
  }

  my($bin, $pow_adjust);

  if($sign1 eq $sign2) {
    $pow_adjust = 0;
    $bin = $bin_pre1 . $bin_str1 . $zeroes . $bin_pre2 . $bin_str2;
  }
  else {
    ($bin, $pow_adjust) = _subtract_p($bin_pre1 . $bin_str1, $zeroes . $bin_pre2 . $bin_str2);
  }

  my $single_exp = $pre1 - 1023 - $pow_adjust;

  $bin =~ s/0+$//; # Remove trailing zeroes
  $bin .= '0' while length($bin) < 108; # Make sure the mantissa of $hex is always at least 108 bits.
  $bin .= '0' while length($bin) % 4;

  return($single_sign, $bin, $single_exp);

}

##############################
##############################
# Return a 3-element list for the given double-double:
# 1) sign
# 2) mantissa (in binary, implicit radix point after first digit)
# 3) exponent
# For nan/inf, the mantissa is 'nan' or 'inf' respectively.

sub NV2binary {
  my @ret = _NV2binary($_[0]);
  my $prec = pop(@ret);
  my $exp = pop(@ret);
  my $mantissa = join '', @ret;
  my $sign = substr($mantissa, 0, 1, '');
  $mantissa =~ s/0\.//;
  $exp--; # because we've right shifted the radix point by one place.
  return ($sign, $mantissa, $exp);
}

##############################
##############################
# Return the NV from the binary representation (sign, mantissa, exponent).

sub B_float {
  die "Wrong number of args to B_float (", scalar @_, ")"
    unless @_ == 3;

  my $hex = B2float_H(@_);
  return H_float($hex);
}

##############################
##############################
# Return a hex string representation as per perl Data::Float
# For NaN and Inf returns 'nan' or 'inf' (prefixed with either
# '+' or '-' as appropriate) unless an additional arg of 'raw'
# has been provided - in which case it does the calculations
# and returns the hex string it has calculated.
# This function returns a hex representation of the *actual*
# value - even if that value requires more than 106 bits.

sub float_H {
  my ($sign, $mant, $exp);

  if(@_ == 1)            {($sign, $mant, $exp) = float_B($_[0])}
  elsif(@_ == 2) {
    if($_[1] eq 'raw') {
      ($sign, $mant, $exp) = float_B($_[0], 'raw');
    }
    else {
      ($sign, $mant, $exp) = float_B($_[0]);
    }
  }
  else { die "Expected either 1 or 2 args to float_H() - received ", scalar @_}

  if($mant eq 'nan') {
    $sign eq '-' ? return '-nan'
                 : return '+nan';
  }
  if($mant eq 'inf') {
    $sign eq '-' ? return '-inf'
                 : return '+inf';
  }

  my $mant_len = length $mant;

  # Mantissa returned by float_B is at least 108 bits
  die "Mantissa calculated by float_H() is too short ($mant_len)"
    if $mant_len < 108;

  # Length of mantissa returned by float_B() is always
  # evenly divisible by 4
  die "Mantissa calculated by float_H() is not divisible by 4 ($mant_len)"
    if $mant_len % 4;

  my $prefix = $sign . '0x' . substr($mant, 0, 1, '') . '.';


  $mant .= '0' while length($mant) % 4;

  my $middle = _bin2hex($mant);

  my $suffix = "p$exp";

  return $prefix . $middle . $suffix;
}

##############################
##############################
# Standardise the float_H output to match the "%La" or "%LA" format
# that C provides on my machine.

sub std_float_H {
  my $str = float_H($_[0]);
  $str =~ s/^\+//;

  if($_[1] eq "%La") {
    $str =~ s/p/p\+/ unless $str =~ /p\-/;
    $str =~ s/0+p/p/;
    $str =~ s/\.p/p/;
    $str =~ s/0x0p.+/0x0p+0/; # for zero, replace existing exponent with '+0'
    return $str;
  }
  if($_[1] eq "%LA") {
    $str = uc($str);
    $str =~ s/P/P\+/ unless $str =~ /P\-/;
    $str =~ s/0+P/P/;
    $str =~ s/\.P/P/;
    $str =~ s/0X0P.+/0X0P+0/; # for zero, replace existing exponent with '+0'
    return $str;
  }
  die "Second arg to std_float_H is $_[1] but needs to be either \"%La\" or \"%LA\"";
}

##############################
##############################
# Receive the hex argument returned by float_H(), and return the original NV.

sub H_float {

  if($_[0] eq '+inf'
     ||
     $_[0] eq '+0x1.000000000000000000000000000p1024'
     ) {return H2NV('7ff00000000000000000000000000000')} # +inf

  if($_[0] eq '-inf'
     ||
     $_[0] eq '-0x1.000000000000000000000000000p1024'
     ) {return H2NV('fff00000000000000000000000000000')} # -inf

  if($_[0] eq '+nan'
     ||
     $_[0] eq '+0x1.800000000000000000000000000p1024'
     ) {return H2NV('7ff80000000000000000000000000000')} # + nan

  if($_[0] eq '-nan'
     ||
     $_[0] eq '-0x1.800000000000000000000000000p1024'
     ) {return H2NV('fff80000000000008000000000000000')} # - nan

  my($sign, $mant, $exp) = float_H2B($_[0]);
  my $overflow = 0;
  my $overflow_exp = $exp + 1;

  my ($d1_bin, $roundup) = _trunc_rnd($mant, 53);

  if(!$roundup) {
    my $s = $sign eq '-' ? -1.0 : 1.0;
    my @mant = split //, $mant;
    my @d = _calculate(\@mant, $exp);
    if($d[0] == 0 && $sign eq '-') {
      # return -ve zero ... but "return -0.0;" might not work,
      # on all perls so we do it this way:
      return H2NV('80000000000000000000000000000000');
    }
    return $d[0] * $s;
  }
  else {
    my $s = $sign eq '-' ? -1.0 : 1.0;
    my $binlen = length $mant;

    if(length($d1_bin) == 54) { # overflow when doing _trunc_rnd()
      $overflow = 1;
      $mant = '0' . $mant;
      $exp++;
    }

    my $subtract_from = $d1_bin . '0' x ($binlen - 53);
    #warn "\n$binlen ", length($d1_bin), " ", length($subtract_from), "\n";

    my $m = _subtract_b($subtract_from, $mant);

    $m = substr($m, 53) unless $overflow;

    my @d1_bin = split //, $d1_bin;
    my @m = split //, $m;

    my ($d1, $exponent) = _calculate(\@d1_bin, $exp);
    $exponent = $overflow_exp if $overflow;
    my ($d2, $discard) = _calculate(\@m, $exponent);

    if($d1 - $d2 == 0 && $sign eq '-') {
      # return -ve zero ... but "return -0.0;" might not work
      # on all perls so we do it this way:
      return H2NV('80000000000000000000000000000000');
    }
    return ($d1 - $d2) * $s;
  }
}

##############################
##############################
# Convert the hex format returned by float_H to binary.
# An array of 3 elements is returned - sign, mantissa, exponent.
# For nan/inf the mantissa is set to 'nan' or 'inf' respectively
# unless a second arg of literally 'raw' is provided.

sub float_H2B {

  my $raw = @_ == 2 && $_[1] eq 'raw' ? 1 : 0;

  if($_[0] eq '+inf'
     ||
     $_[0] eq '+0x1.000000000000000000000000000p1024') {
      $raw == 0 ? return ('+', 'inf', 1024)
                : return ('+', '1' . '0' x 107, 1024);
  }
  if($_[0] eq '-inf'
     ||
     $_[0] eq '-0x1.000000000000000000000000000p1024') {
      $raw == 0 ? return ('-', 'inf', 1024)
                : return ('-', '1' . '0' x 107, 1024);
  }
  if($_[0] eq '+nan'
     ||
     $_[0] eq '+0x1.800000000000000000000000000p1024') {
      $raw == 0 ? return ('+', 'nan', 1024)
                : return ('+', '11' . '0' x 106, 1024);
  }
  if($_[0] eq '- nan'
     ||
     $_[0] eq '-0x1.800000000000000000000000000p1024') {
      $raw == 0 ? return ('-', 'nan', 1024)
                : return ('-', '11' . '0' x 106, 1024)
  }

  my $sign = $_[0] =~ /^\-/ ? '-' : '+';
  my @split = split /p/, $_[0];
  my $exp = $split[1];
  my $lead = substr($_[0], 3, 1);
  die "Wrong leading digit" unless $lead =~ /[01]/;
  my $hex = (split /\./, $split[0])[1];
  die "Wrong number of hex chars" unless length($hex) >= 27;
  my $bin = $lead . _hex2bin($hex);
  $bin =~ s/0$//;
  return ($sign, $bin, $exp);
}


##############################
##############################
# Convert from binary representation to the hex representation
# returned by float_H.
# For inf and nan, return '+' or '-' 'inf' or 'nan' (respectively)
# unless a 4th arg of 'raw' is provided.

sub B2float_H {

  my $sign = shift;
  my $mant = shift;
  my $exp = shift;

  my $raw = @_ == 1 && $_[0] eq 'raw' ? 1 : 0;

  if($mant eq 'inf'
     ||
     ($mant eq '1' . '0' x 107 && $exp == 1024)) {
    $sign eq '-' ? !$raw ? return '-inf'
                             : return '-0x1.000000000000000000000000000p1024'
                 : !$raw ? return '+inf'
                         : return '+0x1.000000000000000000000000000p1024';
  }
  if($mant eq 'nan'
     ||
     ($mant eq '11' . '0' x 106 && $exp == 1024)) {
    $sign eq '-' ? !$raw ? return '-nan'
                         : return '-0x1.800000000000000000000000000p1024'
                 : !$raw ? return '+nan'
                         : return '+0x1.800000000000000000000000000p1024';
  }

  my $lead = substr($mant, 0, 1, '');
  $mant .= '0' while (length($mant) % 4); # _bin2hex() expects length($mant) to be divisible by 4.
  $mant = _bin2hex($mant);

  return $sign . '0x' . $lead . '.' . $mant . 'p' . $exp;
}

##############################
##############################

##############################
##############################
# A function to return the number of zeroes between the 2 doubles.
# Takes the 2 exponents (eg, as provided by get_exp) as args.

sub inter_zero {

  die "inter_zero() takes 2 arguments"
   unless @_ == 2;

  my($exp1, $exp2) = (shift, shift);

  return $exp1 - 53 - $exp2;

}

##############################
##############################
# Return true iff at least one argument is infinite.

sub are_inf {

  for(@_) {
    if($_ == 0 || $_ / $_ == 1 || $_ != $_) {
      return 0;
    }
  }

  return 1;

}

##############################
##############################
# Return true iff at least one argument is a NaN.

sub are_nan {

  for(@_) {
    return 0 if $_ == $_;
  }

  return 1;

}

##############################
##############################
##############################
##############################
##############################
##############################
##############################
# Binary subtract second arg from first arg - args must be of same length.

sub _subtract_b {

    my($bin_str1, $bin_str2) = (shift, shift);
    my($len1, $len2) = (length $bin_str1, length $bin_str2);
    if($len1 != $len2) {
      warn "\n$bin_str1\n$bin_str2\n";
      die "Binary strings must be of same length - we have lengths $len1 & $len2";
    }

    my $ret = '';
    my $borrow = 0;

    for(my $i = -1; $i >= -$len1; $i--) {
      my $bottom = substr($bin_str2, $i, 1);
      if($borrow) {
        $bottom++;
        $borrow = 0;
      }

      my $top = substr($bin_str1, $i, 1);
      if($bottom > $top) {
         $top += 2;
         $borrow = 1;
      }

      $ret = ($top - $bottom) . $ret;
    }

    die "_subtract_b returned wrong value: $ret"
      if length $ret != $len1;

    return $ret;

}

##############################
##############################
# Binary-subtract the second arg from the first arg.
# This sub written specifically for float_B() the output of which,
# is, in turn, needed for float_H().

sub _subtract_p {

    my($bin_str1, $bin_str2) = (shift, shift);
    my($len1, $len2) = (length $bin_str1, length $bin_str2);
    my $len3 = $len1 + $len2;
    my $overflow = 0;

    if($bin_str1 eq '1'. ('0' x 52)) {$overflow = 1}

    $bin_str1 .= '0' x $len2;
    $bin_str2 = 0 x $len1 . $bin_str2;

    my $ret = '';
    my($borrow, $payback) = (0, 0);

    for(my $i = -1; $i >= -$len3; $i--) {
      my $bottom = substr($bin_str2, $i, 1);
      if($borrow) {
        $bottom++;
        $borrow = 0;
      }

      my $top = substr($bin_str1, $i, 1);
      if($bottom > $top) {
         $top += 2;
         $borrow = 1;
      }

      $ret = ($top - $bottom) . $ret;
    }

    die "_subtract_p returned wrong value: $ret"
      if length $ret != $len3;


    if($overflow && $ret =~ /^01111111111111111111111111111111111111111111111111111/) {
      return (substr($ret, 1), 1);
    }

    return ($ret, 0);

}

##############################
##############################
# Convert a binary string to a hex string.
# Length of string must be a multiple of 4

sub _bin2hex {
  my $len = length($_[0]);
  die "_bin2hex() has been passed an empty string"
    unless $len;
  die "Wrong length ($len) supplied to _bin2hex()"
    if $len % 4;
  $len /=  4;
  return unpack "H$len", pack "B*", $_[0];
}

##############################
##############################
# Convert a hex string to a binary string.

sub _hex2bin {
  my $H_len = length($_[0]);
  my $B_len = $H_len * 4;
  return unpack "B$B_len", pack "H$H_len", $_[0];
  #return unpack "B*", pack "H*", $_[0];
}

##############################
##############################
# Moved to an XSub of the same name.
# Calculate the value of the double-double using the
# base 2 representation. (Used by H_float.)

#sub _calculate {
#    my $bin = $_[0];
#    my $exp = $_[1];
#    my $ret = 0;
#
#    my $binlen = length($bin) - 1;
#
#    for my $pos(0 .. $binlen) {
#      $ret += substr($bin, $pos, 1) ? 2 ** $exp : 0;
#      $exp--;
#    }
#
#    return ($ret, $exp);
#}

##############################
##############################
# Increment a binary string.
# Length of returned string will be either $len or $len+1

sub _add_1 {
  my $mant = shift;
  my $len = length $mant;
  my $ret = '';

  my $carry = 0;

  for(my $i = -1; $i >= -$len; $i--) {
    my $top = substr($mant, $i, 1);
    my $bottom = $i == -1 ? 1 : 0;
    my $sum = $top + $bottom + $carry;

    $ret = ($sum % 2) . $ret;

    $carry = $sum >= 2 ? 1 : 0;
  }

  $ret = '1' . $ret if $carry;

  return $ret;
}

##############################
##############################
# Set a binary string (1st arg) to a specified no. of bits (2nd arg), rounding
# to nearest (ties to even) if the string needs to be truncated.
# If the string is shorter than the number of bits specified then zeroes are
# appended until the string reaches the required length.
# Returns a list of 2 values - first element is the truncated/rounded/extended
# string (or the original string if no truncation/rounding/extension was needed).
# Second element is 'true' iff rounding up occurred, else second element is false.
# This function is a key to determining the value of the double-double's
# two doubles, from the entire binary representation of the mantissa.

sub _trunc_rnd {

  my $bin = shift;
  my $binlen = shift;
  my $binlen_plus_1 = $binlen + 1;

  die "Wrong string in _trunc_rnd"
    if $bin =~ /[^01]/;

  $bin .= '0' while length($bin) < $binlen;

  my $len = length $bin;

  return ($bin, 0) if $len == $binlen; # '0' signifies that returned value was *not* rounded up.

  my $first = substr($bin, 0, $binlen);
  my $remain = substr($bin, $binlen, $len - $binlen);

  return ($first, 0) unless $remain =~ /^1/;

  if($len > $binlen_plus_1 && substr($bin, $binlen_plus_1, $len - $binlen_plus_1) =~ /1/) {
    return (Data::Float::DoubleDouble::_add_1($first), 1); # '1' signifies that returned vale *was* rounded up.
  }

  if(substr($first, -1, 1) eq '0') {return ($first, 0)}
  return (_add_1($first), 1);
}

##############################
##############################
# Returns the largest representable finite number.

sub _get_biggest {
  my $nv1 = 0;

  # The order is important !!
  # Doing (917 .. 969, 971 .. 1023) will not work
  for(971 .. 1023, 917 .. 969) {
    $nv1 += 2 ** $_;
  }

  return $nv1;

}

##############################
##############################
# An alternative way of assessing the value of the double-double.
# Express the double as msd + lsd, where the 2 doubles (msd and lsd)
# are written in scientic notation. The doubles will be written in
# decimal format unless a second arg of 'h' or 'H' is provided - in
# which case they will be written in hex format.

sub express {
  my $do_hex = @_ == 2 ? lc($_[1]) eq 'h' ? $_[1]
                                          : undef
                       : @_ == 1 ? 0
                                 : undef;

  die "Bad arg(s) supplied to express(): @_" unless defined $do_hex;

  my($ret1, $ret2);
  my($m1, $m2, $m3) = ('0+e', '\.e', 'e');
  if($do_hex) {
    $m1 = '0+p';
    $m2 = '\.p';
    $m3 = 'p';
  }
  my $hex = NV2H(shift);
  my $lsd = '0' x 16;
  my $msdd = substr($hex, 0, 16) . $lsd;
  my $lsdd = substr($hex, 16, 16) . $lsd;

  if($do_hex) {
    $ret1 = float_H(H2NV($msdd));
    $ret2 = float_H(H2NV($lsdd));
  }
  else {
    $ret1 = H2NV($msdd);
    $ret2 = H2NV($lsdd);
  }

  my $sign = H2NV($lsdd) >= 0 ? ' + ' : '';
  $ret2 =~ s/^\-/ - /;
  $ret2 =~ s/^\+//;
  $ret1 =~ s/$m1/$m3/;
  $ret2 =~ s/$m1/$m3/;
  $ret1 =~ s/$m2/$m3/;
  $ret2 =~ s/$m2/$m3/;
  my $ret = $do_hex eq 'H' ? uc("$ret1$sign$ret2")
                           : "$ret1$sign$ret2";
  return $ret;
}

##############################
##############################
# Returns same as NV2H()

sub dd_bytes {
  my @ret = _dd_bytes($_[0]);
  return join '', @ret;
}

##############################
##############################

# For compatibility with Data::Float:

sub float_class {
  return "NAN" if float_is_nan($_[0]);
  return "INFINITE" if float_is_infinite($_[0]);
  return "ZERO" if $_[0] == 0;
  return "SUBNORMAL" if float_is_subnormal($_[0]);
  return "NORMAL" if float_is_normal($_[0]);
  die "Cannot determine class of float";
}

sub float_is_finite {
  !are_inf($_[0]) && !are_nan($_[0]) ? return 1
                                     : return 0;
}

sub float_is_zero {
  return 1 if $_[0] == 0;
  return 0;
}

sub float_is_nzfinite {
  return 1 if (float_is_finite($_[0]) && $_[0] != 0);
  return 0;
}

sub float_is_normal {
  return 1 if(float_is_nzfinite($_[0]) && float_hex($_[0]) =~ /1\./);
  return 0;
}

sub float_is_subnormal {
  return 1 if(float_is_nzfinite($_[0]) && float_hex($_[0]) =~ /0\./);
  return 0;
}

sub nextafter {
  if(are_nan($_[0])) {return $_[0]}
  if(are_nan($_[1])) {return $_[1]}
  if($_[0] == $_[1])    {return $_[1]}
  elsif($_[0] > $_[1])  {return nextdown($_[0])}
  else                  {return nextup($_[0])}
}

sub nextup {
  return $_[0] if (are_nan($_[0]) || (are_inf($_[0]) && $_[0] > 0));
  return $Data::Float::DoubleDouble::min_fin
    if (are_inf($_[0]) && $_[0] < 0);
  for(-1074 .. 1024) {
    my $candidate = $_[0] + (2 ** $_);
    if($candidate > $_[0]) {
      return H2NV('80000000000000000000000000000000')
        if $candidate == 0;
      return $candidate;
    }
  }
  # We shouldn't get to here
  die "nextup() failed to terminate in an expected manner";
}

sub nextdown {
  return $_[0] if (are_nan($_[0]) || (are_inf($_[0]) && $_[0] < 0));
  return $Data::Float::DoubleDouble::max_fin
    if (are_inf($_[0]) && $_[0] > 0);
  for(-1074 .. 1024) {
    my $candidate = $_[0] - (2 ** $_);
    return $candidate if $candidate < $_[0];
  }
  # We shouldn't get to here
  die "nextdown() failed to terminate in an expected manner";
}


*float_hex = \&float_H;
*hex_float = \&H_float;
*float_is_infinite = \&are_inf;
*float_is_nan = \&are_nan;

sub DD_FLT_RADIX {            # 2
 return _FLT_RADIX();
}

sub DD_LDBL_MAX {             # 1.797693134862315807937289714053e+308
 return _LDBL_MAX();
}

sub DD_LDBL_MIN {             # 2.00416836000897277799610805135e-292
 return _LDBL_MIN();
}

sub DD_LDBL_DIG {             # 31
 return _LDBL_DIG();
}

sub DD_LDBL_MANT_DIG {        # 106
 return _LDBL_MANT_DIG();
}

sub DD_LDBL_MIN_EXP {         # -968
 return _LDBL_MIN_EXP();
}

sub DD_LDBL_MAX_EXP {         # 1024
 return _LDBL_MAX_EXP();
}

sub DD_LDBL_MIN_10_EXP {      # -291
 return _LDBL_MIN_10_EXP();
}

sub DD_LDBL_MAX_10_EXP {      # 308
 return _LDBL_MAX_10_EXP();
}

sub DD_LDBL_EPSILON {         # 4.450147717014402766180465434665e-308
 return _LDBL_EPSILON();
}

sub DD_LDBL_DECIMAL_DIG {     # undef
 return _LDBL_DECIMAL_DIG();
}

sub DD_LDBL_HAS_SUBNORM {     # undef
 return _LDBL_HAS_SUBNORM();
}

sub DD_LDBL_TRUE_MIN {        # undef
 return _LDBL_TRUE_MIN();
}

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;

__END__

=head1 NAME

Data::Float::DoubleDouble -  human-readable representation of the "double-double" long double


=head1 AIM

  Mostly, one would use Data::Float to do what this module does.
  But that module doesn't work with the 'double-double' type of
  long double ... hence, this module.

  Given a double-double value, we aim to be able to:
   1) Convert that NV to its internal packed hex form;
   2) Convert the packed hex form of 1) back to the original value;
   3) Convert that NV to a more human-readable packed hex form,
      similar to what Data::Float's float_hex function achieves;
   4) Convert the packed hex form of 3) back to the original value;

   For 1) we use NV2H().
   For 2) we use H2NV().
   For 3) we use float_H().
   For 4) we use H_float().

   We also have float_B and B_float which are the base 2
   equivalents of float_H and H_float.


=head1 FUNCTIONS

  #############################################

  $hex = NV2H($nv);

   Unpacks the NV to a string of 32 hex characters.
   The first 16 characters relate to the value of the most significant
   double:
    Characters 1 to 3 (incl) embody the sign of the mantissa, the value
    of the exponent, and the value (0 or 1) of the implied leading bit.
    Characters 4 to 16 (incl) embody the value of the 52-bit mantissa.

   The second 16 characters (17 to 32) relate to the value of the least
   siginificant double:
    Characters 17 to 19 (incl) embody the sign of the mantissa, the
    value of the exponent, and the value (0 or 1) of the implied
    leading bit.
    Characters 20 to 32 (incl) embody the value of the 52-bit mantissa.

   For a more human-readable hex representation, use float_H().

  #############################################

  $nv = H2NV($hex);

   For $hex written in the format returned by NV2H, H2NV($hex)
   returns the NV.

  #############################################

  $hex = D2H($nv);

   Treats the NV as a double and returns a string of 16 hex characters.
   Characters 1 to 3 (incl) embody the sign of the mantissa, the value
   (0 or 1) of the implied leading bit and the value of the exponent.
   Characters 4 to 16 (incl) embody the value of the 52-bit mantissa
   of the first double.

  #############################################

  $nv = H2D($hex, $opt); # Second arg is optional

   For $hex written in the format returned by D2H, H2D($hex) returns
   the NV.

  #############################################

  $readable_hex = float_H($nv, $opt); # Aliased to float_hex
                                           # $opt is optional

   For *most* NVs, returns a 106-bit hex representation of the NV
   (long double) $nv in the format
   s0xd.hhhhhhhhhhhhhhhhhhhhhhhhhhhpe where:
    s is the sign (either '-' or '+')
    0x is literally "0x"
    d is the leading (first) bit of the number (either '1' or '0')
    . is literally "." (the decimal point)
    hhhhhhhhhhhhhhhhhhhhhhhhhhh is a string of 27 hex digits
                                representing the remaining 105 bits
                                of the mantissa.
    p is a literal "p" that separates mantissa from exponent
    e is the (signed) exponent

   The keen mind will have realised that 27 hex digits encode 108
   (not 105) bits. However, the last 3 bits are to be ignored and
   will always be zero for a 106-bit float. Thus the 27th hex
   character for a 106-bit float will either be "8" (representing
   a "1") or "0" (representing a "0") for the 106th bit.

   BUT: Some NV values encapsulate a value that require more than
        106 bits in order to be correctly represented.
        If the string that float_H returns is larger than as
        described above, then it will, however,  have returned a
        string that contains the *minimum* number of characters
        needed to accurately represent the given value.
        As an extreme example: the double-double arrangement can
        represent the value 2**1023 + 2**-1074, but to express
        that value as a stream of bits requires 2098 bits, and to
        express that value in the format that float_H returns
        requires 526 hex characters (all of which are zero, except
        for the first and the last). When you add the sign, radix
        point, exponent, etc., the float_H representation of that
        value consists of 535 characters.

   If a second arg is provided, it must be the string 'raw' - in
   which case infs/nans will be returned in hex format instead of
   as "inf"/"nan" strings.

  #############################################

  $readable_hex = DD2HEX($nv, $fmt);

   As for float_H, but uses C's sprintf() function to do the
   conversion to the hex string. The second arg ($fmt) can be either
   "%La" (in which case the alphabetic characters will be lower
   case) or "%LA" (in which case the alphabetic characters will be
   upper case).
   Unlike float_H, this function cannot take the 'raw' argument.
   And, unlike float_H, this function will not return values that
   require more than 106 bits to be expressed.

  #############################################

  $standardised_readable_hex = std_float_H($nv, $fmt);

   As for float_H, but standardises the format to be the same as I
   get for DD2HEX. That is, there's no leading + for positive
   values, positive and zero exponents are prefixed with a +,
   trailing zeroes in the mantissa are removed, and zeroes are
   presented as (-)0x0p+0 or (-)0X0P+0. As for DD2HEX, the second
   arg ($fmt) can be either "%La" or "%LA" (nothing else) and that
   determines whether the alphabetic characters are lower case or
   upper case.
   Unlike float_H, this function cannot take the 'raw' argument.
   Like float_H it will, however, accurately express the value
   that's encapsulated in the double-double (even though that
   minimum may exceed the usual 27 hex digits).

  #############################################

  $readable = express($nv, $opt); # $opt is an optional arg.

   An alternative way of assessing the value of the double-double.
   Express the double as msd + lsd, where the 2 doubles (msd and lsd)
   are written in scientic notation. The doubles will be written in
   decimal format unless a second arg of 'h' or 'H' is provided - in
   which case they will be written in hex (respectively capitalised
   hex) format.
   The second arg ($opt), if provided, must be either 'h' or 'H'.

  #############################################

  $nv = H_float($hex);

   For $hex written in the format returned by float_H(), returns
   the NV that corresponds to $hex.

  #############################################

  @bin = float_B($nv, $opt); # Second arg isoptional

   Returns the sign, the mantissa (as a base 2 string), and the
   exponent of $nv. (There's an implied radix point between the
   first and second digits of the mantissa).
   For nan/inf, the mantissa is 'nan' or 'inf' respectively unless
   2nd arg is literally 'raw' - in which case it will be a base 2
   version of the nan/inf encoding.

  #############################################

  @bin = float_H2B($hex, $opt); # Second arg is optional

   As for the above float_B() function - but takes the hex
   string of the NV (as returned by float_H) as its argument,
   instead of the actual NV.
   For a more direct way of obtaining the array, use float_B
   instead.
   If a second arg is provided, it must be the string 'raw' - in
   which case inf/nan mantissas will be returned in hex format
   instead of as "inf"/"nan" strings.

  #############################################

  @bin = NV2binary($nv);

   Another way of arriving at (almost) the same binary representation
   of the NV -ie as an array consisting of (sign, mantissa, exponent).
   The mantissa if Infs and NaNs will be returned as 'inf' or 'nan'
   respectively and the sign associated with the nan will always
   be '+'.
   With this function, trailing zeroes are stripped from the mantissa
   and exponents for 0, inf and nan might not match the other binary
   representations.
   This function is based on code from the mpfr library's
   tests/tset_ld.c file.

  #############################################

  $hex = B2float_H(@bin, $opt); # $opt is an optional arg

   The reverse of float_H2B. It takes the array returned by
   either float_B or float_H2B as its arguments, and returns
   the corresponding hex form.
   If $opt is provided and is the string 'raw', the actual
   hex encoding of any nan/inf will be returned - instead of
   the string "inf" or "nan" respectively.

  #############################################

  ($sign1, $sign2) = get_sign($nv);

   Returns the signs of the two doubles contained in $nv.

  #############################################

  ($exp1, $exp2) = get_exp($nv);

   Returns the exponents of the two doubles contained in $nv.

  #############################################

  ($double1, $double2) = get_doubles($nv);

   Returns the two doubles contained in $nv.

  #############################################

  ($mantissa1, $mantissa2) = get_mant_H(NV2H($nv));

   Returns an array of the two 52-bit mantissa components of
   the two doubles in their hex form. The values of the
   implied leading (most significant) bits are not provided,
   nor are the values of the two exponents.

  #############################################

  $intermediate_zeroes = inter_zero(get_exp($nv));

   Returns the number of zeroes that need to come between the
   mantissas of the 2 doubles when $nv is translated to the
   representation that float_H() returns.

  #############################################

  $bool = are_inf(@nv); # Aliased to float_is_infinite.

   Returns true if and only if all of the (NV) arguments are
   infinities.
   Else returns false.

  #############################################

  $bool = are_nan(@nv); # Aliased to float_is_nan.

   Returns true if and only if all of the (NV) arguments are
   NaNs. Else returns false.

  #############################################

  $hex = dd_bytes($nv);

   Returns same as NV2H($nv).

  #############################################

  For Compatibility with Data::Float:

  #############################################

  $class = float_class($nv);

   Returns one of either "NAN", "INFINITE", "ZERO", "NORMAL"
   or "SUBNORMAL" - whichever is appropriate. (The NV must
   belong to one (and only one) class.

  #############################################

  $bool = float_is_nan($nv); # Alias for are_nan()

   Returns true if $nv is a NaN.
   Else returns false.

  #############################################

  $bool = float_is_infinite($nv); # Alias for are_inf()

   Returns true if $nv is infinite.
   Else returns false.

  #############################################

  $bool = float_is_finite($nv);

   Returns true if NV is neither infinite nor a NaN.
   Else returns false.

  #############################################

  $bool = float_is_nzfinite($nv);

   Returns true if NV is neither infinite, nor a NaN, nor zero.
   Else returns false.

  #############################################

  $bool = float_is_zero($nv);

   Returns true if NV is zero.
   Else returns false.

  #############################################

  $bool = float_is_normal($nv);

   Returns true if NV is finite && non-zero && the implied
   leading digit in its internal representation is '1'.
   Else returns false.

  #############################################

  $bool = float_is_subnormal($nv);

   Returns true if NV is finite && non-zero && the implied
   leading digit in its internal representation is '0'.

  #############################################

  $nv = nextafter($nv1, $nv2);

   $nv1 and $nv2 must both be floating point values. Returns the
   next representable floating point value adjacent to $nv1 in the
   direction of $nv2, or returns $nv2 if it is numerically
   equal to $nv1. Infinite values are regarded as being adjacent to
   the largest representable finite values. Zero counts as one value,
   even if it is signed, and it is adjacent to the positive and
   negative smallest representable finite values. If a zero is returned
   then it has the same sign as $nv1. Returns
   NaN if either argument is a NaN.

  #############################################

  $nv = nextup($nv1);

   $nv1 must be a floating point value. Returns the next representable
   floating point value adjacent to $nv1 with a numerical value that
   is strictly greater than $nv1, or returns $nv1 unchanged if there
   is no such value. Infinite values are regarded as being adjacent to
   the largest representable finite values. Zero counts as one value,
   even if it is signed, and it is adjacent to the smallest
   representable positive and negative finite values. If a zero is
   returned, because $nv1 is the smallest representable negative
   value, and zeroes are signed, it is a negative zero that is
   returned. Returns NaN if $nv1 is a NaN.

  #############################################

  $nv = nextdown($nv1);

   $nv1 must be a floating point value. Returns the next representable
   floating point value adjacent to $nv1 with a numerical value that
   is strictly less than $nv1, or returns $nv1 unchanged if there is
   no such value. Infinite values are regarded as being adjacent to the
   largest representable finite values. Zero counts as one value, even
   if it is signed, and it is adjacent to the smallest representable
   positive and negative finite values. If a zero is returned, because
   $nv is the smallest representable positive value, and zeroes are
   signed, it is a positive zero that is returned. Returns NaN if VALUE
   is a NaN.

  #############################################
  #############################################

=head1 TODO

   Over time, introduce the features of (and functions provided by)
   Data::Float

=head1 LICENSE

   This program is free software; you may redistribute it and/or
   modify it under the same terms as Perl itself.
   Copyright 2014 Sisyphus

=head1 AUTHOR

   Sisyphus <sisyphus at(@) cpan dot (.) org>

=cut
