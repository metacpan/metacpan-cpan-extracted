package bigfloat;

use strict;
use vars qw($div_scale $rnd_mode);
require 'DateTime/Math/bigint.pl';

# Arbitrary length float math package
#
# by Mark Biggar
#
# number format
#   canonical strings have the form /[+-]\d+E[+-]\d+/
#   Input values can have inbedded whitespace
# Error returns
#   'NaN'           An input parameter was "Not a Number" or 
#                       divide by zero or sqrt of negative number
# Division is computed to 
#   max($div_scale,length(dividend)+length(divisor)) 
#   digits by default.
# Also used for default sqrt scale

$div_scale = 40;

# Rounding modes one of 'even', 'odd', '+inf', '-inf', 'zero' or 'trunc'.

$rnd_mode = 'even';

#   bigfloat routines
#
#   fadd(NSTR, NSTR) return NSTR            addition
#   fsub(NSTR, NSTR) return NSTR            subtraction
#   fmul(NSTR, NSTR) return NSTR            multiplication
#   fdiv(NSTR, NSTR[,SCALE]) returns NSTR   division to SCALE places
#   fneg(NSTR) return NSTR                  negation
#   fabs(NSTR) return NSTR                  absolute value
#   fcmp(NSTR,NSTR) return CODE             compare undef,<0,=0,>0
#   fround(NSTR, SCALE) return NSTR         round to SCALE digits
#   ffround(NSTR, SCALE) return NSTR        round at SCALEth place
#   fnorm(NSTR) return (NSTR)               normalize
#   fsqrt(NSTR[, SCALE]) return NSTR        sqrt to SCALE places

# Convert a number to canonical string form.
#   Takes something that looks like a number and converts it to
#   the form /^[+-]\d+E[+-]\d+$/.
sub DateTime::Math::fnorm { #(string) return fnum_str
    local($_) = @_;
    defined($_) or return 'NaN';
    s/\s+//g;                               # strip white space
    if (/^([+-]?)(\d*)(\.(\d*))?([Ee]([+-]?\d+))?$/ &&
	($2 ne '' || defined($4))) {
	my $x = defined($4) ? $4 : '';
	my $y = defined($6) ? $6 : 0;
	&norm(($1 ? "$1$2$x" : "+$2$x"), (($x ne '') ? $y-length($x) : $y));
    } else {
	'NaN';
    }
}

# normalize number -- for internal use
sub norm { #(mantissa, exponent) return fnum_str
    my ($mantissa, $exp) = @_;
    defined($exp) or $exp = 0;
    if ($mantissa eq 'NaN') {
	'NaN';
    } else {
	# strip leading zeros
	$mantissa =~ s/^([+-])0+/$1/;
	if (length($mantissa) == 1) {
	    '+0E+0';
	} else {
	    # strip trailing zeros
	    $exp += length($1) if ($mantissa =~ s/(0+)$//);
	    sprintf("%sE%+ld", $mantissa, $exp);
	}
    }
}

# negation
sub DateTime::Math::fneg { #(fnum_str) return fnum_str
    local($_) = &DateTime::Math::fnorm($_[0]);
    vec($_,0,8) ^= ord('+') ^ ord('-') unless $_ eq '+0E+0'; # flip sign
    s/^H/N/;
    $_;
}

# absolute value
sub DateTime::Math::fabs { #(fnum_str) return fnum_str
    local($_) = &DateTime::Math::fnorm($_[0]);
    s/^-/+/;		                       # mash sign
    $_;
}

# multiplication
sub DateTime::Math::fmul { #(fnum_str, fnum_str) return fnum_str
    my ($x,$y) = (&DateTime::Math::fnorm($_[0]),&DateTime::Math::fnorm($_[1]));
    if ($x eq 'NaN' || $y eq 'NaN') {
	'NaN';
    } else {
	my ($xm,$xe) = split('E',$x);
	my ($ym,$ye) = split('E',$y);
	&norm(&DateTime::Math::bmul($xm,$ym),$xe+$ye);
    }
}

# addition
sub DateTime::Math::fadd { #(fnum_str, fnum_str) return fnum_str
    my ($x,$y) = (&DateTime::Math::fnorm($_[0]),&DateTime::Math::fnorm($_[1]));
    if ($x eq 'NaN' || $y eq 'NaN') {
	'NaN';
    } else {
	my ($xm,$xe) = split('E',$x);
	my ($ym,$ye) = split('E',$y);
	($xm,$xe,$ym,$ye) = ($ym,$ye,$xm,$xe) if ($xe < $ye);
	&norm(&DateTime::Math::badd($ym,$xm.('0' x ($xe-$ye))),$ye);
    }
}

# subtraction
sub DateTime::Math::fsub { #(fnum_str, fnum_str) return fnum_str
    &DateTime::Math::fadd($_[0],&DateTime::Math::fneg($_[1]));    
}

# division
#   args are dividend, divisor, scale (optional)
#   result has at most max(scale, length(dividend), length(divisor)) digits
sub DateTime::Math::fdiv #(fnum_str, fnum_str[,scale]) return fnum_str
{
    my ($x,$y,$scale) = (&DateTime::Math::fnorm($_[0]),&DateTime::Math::fnorm($_[1]),$_[2]);
    if ($x eq 'NaN' || $y eq 'NaN' || $y eq '+0E+0') {
	'NaN';
    } else {
	my ($xm,$xe) = split('E',$x);
	my ($ym,$ye) = split('E',$y);
	$scale = $div_scale if (!$scale);
	$scale = length($xm)-1 if (length($xm)-1 > $scale);
	$scale = length($ym)-1 if (length($ym)-1 > $scale);
	$scale = $scale + length($ym) - length($xm);
	&norm(&round(&DateTime::Math::bdiv($xm.('0' x $scale),$ym),$ym),
	    $xe-$ye-$scale);
    }
}

# round int $q based on fraction $r/$base using $rnd_mode
sub round { #(int_str, int_str, int_str) return int_str
    my ($q,$r,$base) = @_;
    if ($q eq 'NaN' || $r eq 'NaN') {
	'NaN';
    } elsif ($rnd_mode eq 'trunc') {
	$q;                         # just truncate
    } else {
	my $cmp = &DateTime::Math::bcmp(&DateTime::Math::bmul($r,'+2'),$base);
	if ( $cmp < 0 ||
		 ($cmp == 0 &&
		  ( $rnd_mode eq 'zero'                             ||
		   ($rnd_mode eq '-inf' && (substr($q,0,1) eq '+')) ||
		   ($rnd_mode eq '+inf' && (substr($q,0,1) eq '-')) ||
		   ($rnd_mode eq 'even' && $q =~ /[24680]$/)        ||
		   ($rnd_mode eq 'odd'  && $q =~ /[13579]$/)        )) ) {
	    $q;                     # round down
	} else {
	    &DateTime::Math::badd($q, ((substr($q,0,1) eq '-') ? '-1' : '+1'));
				    # round up
	}
    }
}

# round the mantissa of $x to $scale digits
sub DateTime::Math::fround { #(fnum_str, scale) return fnum_str
    my ($x,$scale) = (&DateTime::Math::fnorm($_[0]),$_[1]);
    if ($x eq 'NaN' || $scale <= 0) {
	$x;
    } else {
	my ($xm,$xe) = split('E',$x);
	if (length($xm)-1 <= $scale) {
	    $x;
	} else {
	    &norm(&round(substr($xm,0,$scale+1),
			 "+0".substr($xm,$scale+1,1),"+10"),
		  $xe+length($xm)-$scale-1);
	}
    }
}

# round $x at the 10 to the $scale digit place
sub DateTime::Math::ffround { #(fnum_str, scale) return fnum_str
    my ($x,$scale) = (&DateTime::Math::fnorm($_[0]),$_[1]);
    if ($x eq 'NaN') {
	'NaN';
    } else {
	my ($xm,$xe) = split('E',$x);
	if ($xe >= $scale) {
	    $x;
	} else {
	    $xe = length($xm)+$xe-$scale;
	    if ($xe < 1) {
		'+0E+0';
	    } elsif ($xe == 1) {
		&norm(&round('+0',"+0".substr($xm,1,1),"+10"), $scale);
	    } else {
		&norm(&round(substr($xm,0,$xe),
		      "+0".substr($xm,$xe,1),"+10"), $scale);
	    }
	}
    }
}
    
# compare 2 values returns one of undef, <0, =0, >0
#   returns undef if either or both input value are not numbers
sub DateTime::Math::fcmp #(fnum_str, fnum_str) return cond_code
{
    my ($x, $y) = (&DateTime::Math::fnorm($_[0]),&DateTime::Math::fnorm($_[1]));
    if ($x eq "NaN" || $y eq "NaN") {
	return;
    } else {
	# Compare signs between the two numbers.
	my $ret = (ord($y) <=> ord($x));
	$ret and return $ret;
	# Compare the numbers by making both of them integer and using the
	# integer compare routines.  Make the numbers into integers by
	# taking the number with the larger exponent and adding either
	# abs($xe - $ye) to the end of it so that the two numbers have the
	# same exponent.
	my ($xm,$xe,$ym,$ye) = split('E', $x."E$y");
	my $diff = abs($xe - $ye);
	(($xe > $ye) ? $xm : $ym) .= '0' x $diff;
	&DateTime::Math::bcmp($xm,$ym) <=> 0;
    }
}

# square root by Newtons method.
sub DateTime::Math::fsqrt { #(fnum_str[, scale]) return fnum_str
    my ($x, $scale) = (&DateTime::Math::fnorm($_[0]), $_[1]);
    if ($x eq 'NaN' || $x =~ /^-/) {
	'NaN';
    } elsif ($x eq '+0E+0') {
	'+0E+0';
    } else {
	my ($xm, $xe) = split('E',$x);
	$scale = $div_scale if (!$scale);
	$scale = length($xm)-1 if ($scale < length($xm)-1);
	my ($gs, $guess) = (1, sprintf("1E%+d", (length($xm)+$xe-1)/2));
	while ($gs < 2*$scale) {
	    $guess = &DateTime::Math::fmul(&DateTime::Math::fadd($guess,&DateTime::Math::fdiv($x,$guess,$gs*2)),".5");
	    $gs *= 2;
	}
	&DateTime::Math::fround($guess, $scale);
    }
}

1;
