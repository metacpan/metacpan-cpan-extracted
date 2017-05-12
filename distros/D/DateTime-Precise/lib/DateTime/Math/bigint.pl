package bigint;

use strict;
use vars qw($zero);

# arbitrary size integer math package
#
# by Mark Biggar
#
# Canonical Big integer value are strings of the form
#       /^[+-]\d+$/ with leading zeros suppressed
# Input values to these routines may be strings of the form
#       /^\s*[+-]?[\d\s]+$/.
# Examples:
#   '+0'                            canonical zero value
#   '   -123 123 123'               canonical value '-123123123'
#   '1 23 456 7890'                 canonical value '+1234567890'
# Output values always always in canonical form
#
# Actual math is done in an internal format consisting of an array
#   whose first element is the sign (/^[+-]$/) and whose remaining 
#   elements are base 100000 digits with the least significant digit first.
# The string 'NaN' is used to represent the result when input arguments 
#   are not numbers, as well as the result of dividing by zero
#
# routines provided are:
#
#   bneg(BINT) return BINT              negation
#   babs(BINT) return BINT              absolute value
#   bcmp(BINT,BINT) return CODE         compare numbers (undef,<0,=0,>0)
#   badd(BINT,BINT) return BINT         addition
#   bsub(BINT,BINT) return BINT         subtraction
#   bmul(BINT,BINT) return BINT         multiplication
#   bdiv(BINT,BINT) return (BINT,BINT)  division (quo,rem) just quo if scalar
#   bmod(BINT,BINT) return BINT         modulus
#   bgcd(BINT,BINT) return BINT         greatest common divisor
#   bnorm(BINT) return BINT             normalization
#

$zero = 0;


# normalize string form of number.   Strip leading zeros.  Strip any
#   white space and add a sign, if missing.
# Strings that are not numbers result the value 'NaN'.

sub DateTime::Math::bnorm { #(num_str) return num_str
    local($_) = @_;
    defined($_) or return 'NaN';
    s/\s+//g;                           # strip white space
    if (s/^([+-]?)0*(\d+)$/$1$2/) {     # test if number
	substr($_,0,0) = '+' unless $1; # Add missing sign
	s/^-0/+0/;
	$_;
    } else {
	'NaN';
    }
}

# Convert a number from string format to internal base 100000 format.
#   Assumes normalized value as input.
sub internal { #(num_str) return int_num_array
    my $d = shift;
    my ($is,$il) = (substr($d,0,1),length($d)-2);
    substr($d,0,1) = '';
    ($is, reverse(unpack("a" . ($il%5+1) . ("a5" x ($il/5)), $d)));
}

# Convert a number from internal base 100000 format to string format.
#   This routine scribbles all over input array.
sub external { #(int_num_array) return num_str
    my $es = shift;
    grep($_ > 9999 || ($_ = substr('0000'.$_,-5)), @_);   # zero pad
    &DateTime::Math::bnorm(join('', $es, reverse(@_)));    # reverse concat and normalize
}

# Negate input value.
sub DateTime::Math::bneg { #(num_str) return num_str
    my $num = &DateTime::Math::bnorm(@_);
    vec($num,0,8) ^= ord('+') ^ ord('-') unless $num eq '+0';
    $num =~ s/^H/N/;
    $num;
}

# Returns the absolute value of the input.
sub DateTime::Math::babs { #(num_str) return num_str
    &abs(&DateTime::Math::bnorm(@_));
}

sub abs { # post-normalized abs for internal use
    my $num = shift;
    $num =~ s/^-/+/;
    $num;
}

# Compares 2 values.  Returns one of undef, <0, =0, >0. (suitable for sort)
sub DateTime::Math::bcmp { #(num_str, num_str) return cond_code
    my ($x,$y) = (&DateTime::Math::bnorm($_[0]),&DateTime::Math::bnorm($_[1]));
    if ($x eq 'NaN') {
	return;
    } elsif ($y eq 'NaN') {
	return;
    } else {
	&cmp($x,$y);
    }
}

sub cmp { # post-normalized compare for internal use
    my ($cx, $cy) = @_;

    return 0 if ($cx eq $cy);

    my ($sx, $sy) = (substr($cx, 0, 1), substr($cy, 0, 1));
    my $ld;

    if ($sx eq '+') {
      return  1 if ($sy eq '-' || $cy eq '+0');
      $ld = length($cx) - length($cy);
      return $ld if ($ld);
      return $cx cmp $cy;
    } else { # $sx eq '-'
      return -1 if ($sy eq '+');
      $ld = length($cy) - length($cx);
      return $ld if ($ld);
      return $cy cmp $cx;
    }

}

sub DateTime::Math::badd { #(num_str, num_str) return num_str
    my ($x, $y) = (&DateTime::Math::bnorm($_[0]),&DateTime::Math::bnorm($_[1]));
    if ($x eq 'NaN') {
	'NaN';
    } elsif ($y eq 'NaN') {
	'NaN';
    } else {
	my @x = &internal($x);             # convert to internal form
	my @y = &internal($y);
	my ($sx, $sy) = (shift @x, shift @y); # get signs
	if ($sx eq $sy) {
	    &external($sx, &add(\@x, \@y)); # if same sign add
	} else {
	    ($x, $y) = (&abs($x),&abs($y)); # make abs
	    if (&cmp($y,$x) > 0) {
		&external($sy, &sub(\@y, \@x));
	    } else {
		&external($sx, &sub(\@x, \@y));
	    }
	}
    }
}

sub DateTime::Math::bsub { #(num_str, num_str) return num_str
    &DateTime::Math::badd($_[0],&DateTime::Math::bneg($_[1]));    
}

# GCD -- Euclids algorithm Knuth Vol 2 pg 296
sub DateTime::Math::bgcd { #(num_str, num_str) return num_str
    my ($x,$y) = (&DateTime::Math::bnorm($_[0]),&DateTime::Math::bnorm($_[1]));
    if ($x eq 'NaN' || $y eq 'NaN') {
	'NaN';
    } else {
	($x, $y) = ($y,&DateTime::Math::bmod($x,$y)) while $y ne '+0';
	$x;
    }
}

# routine to add two base 1e5 numbers
#   stolen from Knuth Vol 2 Algorithm A pg 231
#   there are separate routines to add and sub as per Kunth pg 233
sub add { #(int_num_array, int_num_array) return int_num_array
    my ($x_array, $y_array) = @_;
    my $car = 0;
    for my $x (@$x_array) {
	last unless @$y_array || $car;
	$x -= 1e5 if $car = (($x += (@$y_array ? shift(@$y_array) : 0) + $car) >= 1e5) ? 1 : 0;
    }
    for my $y (@$y_array) {
	last unless $car;
	$y -= 1e5 if $car = (($y += $car) >= 1e5) ? 1 : 0;
    }
    (@$x_array, @$y_array, $car);
}

# subtract base 1e5 numbers -- stolen from Knuth Vol 2 pg 232, $x > $y
sub sub { #(int_num_array, int_num_array) return int_num_array
    my ($sx_array, $sy_array) = @_;
    my $bar = 0;
    for my $sx (@$sx_array) {
	last unless @$sy_array || $bar;
	$sx += 1e5 if $bar = (($sx -= (@$sy_array ? shift(@$sy_array) : 0) + $bar) < 0);
    }
    @$sx_array;
}

# multiply two numbers -- stolen from Knuth Vol 2 pg 233
sub DateTime::Math::bmul { #(num_str, num_str) return num_str
    my ($x, $y) = (&DateTime::Math::bnorm($_[0]), &DateTime::Math::bnorm($_[1]));
    if ($x eq 'NaN') {
	'NaN';
    } elsif ($y eq 'NaN') {
	'NaN';
    } else {
	my @x = &internal($x);
	my @y = &internal($y);
	&external(&mul(\@x, \@y));
    }
}

# multiply two numbers in internal representation
# destroys the arguments, supposes that two arguments are different
sub mul { #(*int_num_array, *int_num_array) return int_num_array
    my ($x_array, $y_array) = @_;
    my $signr = (shift @$x_array ne shift @$y_array) ? '-' : '+';
    my @prod = ();
    for my $x (@$x_array) {
	my ($car, $cty) = (0, 0);
	for my $y (@$y_array) {
	    my $prod = $x * $y + ($prod[$cty] || 0) + $car;
	    $prod[$cty++] =
		$prod - ($car = int($prod * 1e-5)) * 1e5;
	}
	$prod[$cty] += $car if $car;
	$x = shift @prod;
    }
    ($signr, @$x_array, @prod);
}


# modulus
sub DateTime::Math::bmod { #(num_str, num_str) return num_str
    (&DateTime::Math::bdiv(@_))[1];
}

sub DateTime::Math::bdiv { #(dividend: num_str, divisor: num_str) return num_str
    my ($x, $y) = (&DateTime::Math::bnorm($_[0]), &DateTime::Math::bnorm($_[1]));
    return wantarray ? ('NaN','NaN') : 'NaN'
	if ($x eq 'NaN' || $y eq 'NaN' || $y eq '+0');
    return wantarray ? ('+0',$x) : '+0' if (&cmp(&abs($x),&abs($y)) < 0);
    my @x = &internal($x);
    my @y = &internal($y);
    my $srem = $y[0];
    my $sr = (shift @x ne shift @y) ? '-' : '+';
    my ($car, $bar, $prd, $dd) = (0, 0, 0, 0);
    if (($dd = int(1e5/($y[$#y]+1))) != 1) {
	for $x (@x) {
	    $x = $x * $dd + $car;
	    $x -= ($car = int($x * 1e-5)) * 1e5;
	}
	push(@x, $car); $car = 0;
	for $y (@y) {
	    $y = $y * $dd + $car;
	    $y -= ($car = int($y * 1e-5)) * 1e5;
	}
    }
    else {
	push(@x, 0);
    }
    my @q = ();
    my ($v2,$v1) = @y[-2,-1];
    while ($#x > $#y) {
	my ($u2,$u1,$u0) = @x[-3..-1];
	my $q = (($u0 == $v1) ? 99999 : int(($u0*1e5+$u1)/$v1));
	{
	    local $^W = 0;
	    --$q while ($v2*$q > ($u0*1e5+$u1-$q*$v1)*1e5+$u2);
	}
	if ($q) {
	    ($car, $bar) = (0,0);
	    for ($y = 0, $x = $#x-$#y-1; $y <= $#y; ++$y,++$x) {
		$prd = $q * $y[$y] + $car;
		$prd -= ($car = int($prd * 1e-5)) * 1e5;
		$x[$x] += 1e5 if ($bar = (($x[$x] -= $prd + $bar) < 0));
	    }
	    if ($x[$#x] < $car + $bar) {
		$car = 0; --$q;
		for ($y = 0, $x = $#x-$#y-1; $y <= $#y; ++$y,++$x) {
		    $x[$x] -= 1e5
			if ($car = (($x[$x] += $y[$y] + $car) > 1e5));
		}
	    }   
	}
	pop(@x); unshift(@q, $q);
    }
    if (wantarray) {
	my @d = ();
	if ($dd != 1) {
	    $car = 0;
	    for $x (reverse @x) {
		$prd = $car * 1e5 + $x;
		$car = $prd - (my $tmp = int($prd / $dd)) * $dd;
		unshift(@d, $tmp);
	    }
	}
	else {
	    @d = @x;
	}
	(&external($sr, @q), &external($srem, @d, $zero));
    } else {
	&external($sr, @q);
    }
}

# compute power of two numbers -- stolen from Knuth Vol 2 pg 233
sub DateTime::Math::bpow { #(num_str, num_str) return num_str
    my ($x, $y) = (&DateTime::Math::bnorm($_[0]), &DateTime::Math::bnorm($_[1]));
    if ($x eq 'NaN') {
	'NaN';
    } elsif ($y eq 'NaN') {
	'NaN';
    } elsif ($x eq '+1') {
	'+1';
    } elsif ($x eq '-1') {
	&bmod($x,2) ? '-1': '+1';
    } elsif ($y =~ /^-/) {
	'NaN';
    } elsif ($x eq '+0' && $y eq '+0') {
	'NaN';
    } else {
	my @x    = &internal($x);
	my @pow2 = @x;
	my @pow  = &internal("+1");
	my ($y1, $res, @tmp1, @tmp2) = (1); # need tmp to send to mul
	while ($y ne '+0') {
	    ($y,$res)=&DateTime::Math::bdiv($y,2);
	    if ($res ne '+0') {my @tmp=@pow2; @pow =&mul(\@pow,  \@tmp);}
	    if ($y ne '+0')   {my @tmp=@pow2; @pow2=&mul(\@pow2, \@tmp);}
	}
	&external(@pow);
    }
}

1;
