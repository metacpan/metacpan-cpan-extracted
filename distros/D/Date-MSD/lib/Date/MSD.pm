=head1 NAME

Date::MSD - conversion between flavours of Mars Sol Date

=head1 SYNOPSIS

	use Date::MSD qw(js_to_msd msd_to_cmsdnf cmsdn_to_js);

	$msd = js_to_msd($js);
	($cmsdn, $cmsdf) = msd_to_cmsdnf($msd, $tz);
	$js = cmsdn_to_js($cmsdn, $cmsdf, $tz);

	# and 69 other conversion functions

=head1 DESCRIPTION

For date and time calculations it is convenient to represent dates by
a simple linear count of days, rather than in a particular calendar.
This module performs conversions between different flavours of linear
count of Martian solar days ("sols").

Among Martian day count systems there are also some non-trivial
differences of concept.  There are systems that count only complete days,
and those that count fractional days also.  There are some that are fixed
to Airy Mean Time (time on the Martian prime meridian), and others that
are interpreted according to a timezone.  The functions of this module
appropriately handle the semantics of all the non-trivial conversions.

The day count systems supported by this module are Mars Sol Date,
Julian Sol, and Chronological Mars Solar Date, each in both integral
and fractional forms.

=head2 Flavours of day count

In the interests of orthogonality, all flavours of day count come in
both integral and fractional varieties.  Generally, there is a quantity
named "XYZ" which is a real count of days since a particular epoch (an
integer plus a fraction) and a corresponding quantity named "XYZN" ("XYZ
Number") which is a count of complete days since the same epoch.  XYZN is
the integral part of XYZ.  There is also a quantity named "XYZF" ("XYZ
Fraction") which is a count of fractional days since the XYZN changed
(at midnight).  XYZF is the fractional part of XYZ, in the range [0, 1).

This quantity naming pattern is derived from the naming of Terran day
counts, particularly JD (Julian Date) and JDN (Julian Day Number) which
have the described correspondence.  The "XYZF" name type is a neologism,
invented for L<Date::JD>.

All calendar dates given are in the Darian calendar for Mars.  An hour
number is appended to each date, separated by a "T"; hour 00 is midnight
at the start of the day.  An appended "Z" indicates that the date is to
be interpreted in the timezone of the prime meridian (Airy Mean Time),
and so is absolute; where any other timezone is to be used then this is
explicitly noted.

=over

=item MSD (Mars Sol Date)

days elapsed since 0140-19-26T00Z (approximately MJD 5521.50
in Terrestrial Time).  This epoch is the most recent near
coincidence of midnight on the Martian prime meridian with noon
on the Terran prime meridian.  MSD is defined by the paper at
L<http://pubs.giss.nasa.gov/docs/2000/2000_Allison_McEwen.pdf>.

=item JS (Julian Sol)

days elapsed since 0000-01-01T00Z (MSD -94129.0) (approximately
MJD -91195.22 in Terrestrial Time).  This epoch is an Airy
midnight approximating the last northward equinox prior to
the first telescopic observations of Mars.  The same epoch is
used for the Darian calendar for Mars.  JS is defined (but not
explicitly) by the document describing the Darian calendar, at
L<http://pweb.jps.net/~tgangale/mars/converter/calendar_clock.htm>.

=item CMSD (Chronological Mars Solar Date)

days elapsed since -0608-23-20T00 in the timezone of interest.
CMSD = MSD + 500000.0 + Zoff, where Zoff is the timezone
offset in fractional days.  CMSD is defined by the memo at
L<http://www.fysh.org/~zefram/time/define_cmsd.txt>.

=back

=head2 Meaning of the day

A day count has meaning only in the context of a particular definition
of "day".  Potentially several time scales could be expressed in terms
of a day count, just as Terran day counts such as MJD are used in the
timescales UT1, UT2, UTC, TAI, TT, TCG, and others.  For a day number
to be meaningful it is necessary to be aware of which kind of day it
is counting.  Conversion between the different time scales is out of
scope for this module.

=cut

package Date::MSD;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.004";

use parent "Exporter";
our @EXPORT_OK;

my %msd_flavours = (
	msd => { epoch_msd => 0 },
	js => { epoch_msd => -94129.0 },
	cmsd => { epoch_msd => -500000.0, zone => 1 },
);

=head1 FUNCTIONS

Day counts in this API may be native Perl numbers or C<Math::BigRat>
objects.  Both are acceptable for all parameters, in any combination.
In all conversion functions, the result is of the same type as the
input, provided that the inputs are of consistent type.  If native Perl
numbers are supplied then the conversion is subject to floating point
rounding, and possible overflow if the numbers are extremely large.
The use of C<Math::BigRat> is recommended to avoid these problems.
With C<Math::BigRat> the results are exact.

There are conversion functions between all pairs of day count systems.
This is a total of 72 conversion functions (including 12 identity
functions).

When converting between timezone-relative counts (CMSD) and absolute
counts (MSD, JS), the timezone that is being used must be specified.
It is given in a ZONE argument as a fractional number of days offset
from the base time scale (typically Airy Mean Time).  Beware of
floating point rounding when the offset does not have a terminating
binary representation; use of C<Math::BigRat> avoids this problem.
A ZONE parameter is not used when converting between absolute day counts
(e.g., between MSD and JS) or between timezone-relative counts (e.g.,
between CMSD and CMSDN).

=over

=item msd_to_msd(MSD)

=item msd_to_js(MSD)

=item msd_to_cmsd(MSD, ZONE)

=item js_to_msd(JS)

=item js_to_js(JS)

=item js_to_cmsd(JS, ZONE)

=item cmsd_to_msd(CMSD, ZONE)

=item cmsd_to_js(CMSD, ZONE)

=item cmsd_to_cmsd(CMSD)

These functions convert from one continuous day count to another.
This principally involve a change of epoch.  The input identifies a
point in time, as a continuous day count of input flavour.  The function
returns the same point in time, represented as a continuous day count
of output flavour.

=item msd_to_msdnn(MSD)

=item msd_to_jsnn(MSD)

=item msd_to_cmsdnn(MSD, ZONE)

=item js_to_msdnn(JS)

=item js_to_jsnn(JS)

=item js_to_cmsdnn(JS, ZONE)

=item cmsd_to_msdnn(CMSD, ZONE)

=item cmsd_to_jsnn(CMSD, ZONE)

=item cmsd_to_cmsdnn(CMSD)

These functions convert from a continuous day count to an integral day
count.  The input identifies a point in time, as a continuous day count
of input flavour.  The function returns the day number of output flavour
that applies at that instant.  The process throws away information about
the time of (output-flavour) day.

=item msd_to_msdnf(MSD)

=item msd_to_jsnf(MSD)

=item msd_to_cmsdnf(MSD, ZONE)

=item js_to_msdnf(JS)

=item js_to_jsnf(JS)

=item js_to_cmsdnf(JS, ZONE)

=item cmsd_to_msdnf(CMSD, ZONE)

=item cmsd_to_jsnf(CMSD, ZONE)

=item cmsd_to_cmsdnf(CMSD)

These functions convert from a continuous day count to an integral day
count with separate fraction.  The input identifies a point in time,
as a continuous day count of input flavour.  The function returns a
list of two items: the day number and fractional day of output flavour,
which together identify the same point in time as the input.

=item msd_to_msdn(MSD)

=item msd_to_jsn(MSD)

=item msd_to_cmsdn(MSD, ZONE)

=item js_to_msdn(JS)

=item js_to_jsn(JS)

=item js_to_cmsdn(JS, ZONE)

=item cmsd_to_msdn(CMSD, ZONE)

=item cmsd_to_jsn(CMSD, ZONE)

=item cmsd_to_cmsdn(CMSD)

These functions convert from a continuous day count to an integral day
count, possibly with separate fraction.  The input identifies a point in
time, as a continuous day count of input flavour.  If called in scalar
context, the function returns the day number of output flavour that
applies at that instant, throwing away information about the time of
(output-flavour) day.  If called in list context, the function returns a
list of two items: the day number and fractional day of output flavour,
which together identify the same point in time as the input.

These functions are not recommended, because the context-sensitive
return convention makes their use error-prone.  They are retained for
backward compatibility.  You should prefer to use the more specific
functions shown above.

=item msdn_to_msd(MSDN, MSDF)

=item msdn_to_js(MSDN, MSDF)

=item msdn_to_cmsd(MSDN, MSDF, ZONE)

=item jsn_to_msd(JSN, JSF)

=item jsn_to_js(JSN, JSF)

=item jsn_to_cmsd(JSN, JSF, ZONE)

=item cmsdn_to_msd(CMSDN, CMSDF, ZONE)

=item cmsdn_to_js(CMSDN, CMSDF, ZONE)

=item cmsdn_to_cmsd(CMSDN, CMSDF)

These functions convert from an integral day count with separate fraction
to a continuous day count.  The input identifies a point in time, as
an integral day number of input flavour plus day fraction in the range
[0, 1).  The function returns the same point in time, represented as a
continuous day count of output flavour.

=item msdn_to_msdnn(MSDN[, MSDF])

=item msdn_to_jsnn(MSDN[, MSDF])

=item msdn_to_cmsdnn(MSDN, MSDF, ZONE)

=item jsn_to_msdnn(JSN[, JSF])

=item jsn_to_jsnn(JSN[, JSF])

=item jsn_to_cmsdnn(JSN, JSF, ZONE)

=item cmsdn_to_msdnn(CMSDN, CMSDF, ZONE)

=item cmsdn_to_jsnn(CMSDN, CMSDF, ZONE)

=item cmsdn_to_cmsdnn(CMSDN[, CMSDF])

These functions convert from an integral day count with separate fraction
to an integral day count.  The input identifies a point in time, as an
integral day number of input flavour plus day fraction in the range
[0, 1).  The function returns the day number of output flavour that
applies at that instant.  The process throws away information about
the time of (output-flavour) day.  If converting between systems that
delimit days identically (e.g., between JS and MSD), the day fraction
makes no difference and may be omitted from the input.

=item msdn_to_msdnf(MSDN, MSDF)

=item msdn_to_jsnf(MSDN, MSDF)

=item msdn_to_cmsdnf(MSDN, MSDF, ZONE)

=item jsn_to_msdnf(JSN, JSF)

=item jsn_to_jsnf(JSN, JSF)

=item jsn_to_cmsdnf(JSN, JSF, ZONE)

=item cmsdn_to_msdnf(CMSDN, CMSDF, ZONE)

=item cmsdn_to_jsnf(CMSDN, CMSDF, ZONE)

=item cmsdn_to_cmsdnf(CMSDN, CMSDF)

These functions convert from one integral day count with separate
fraction to another.  The input identifies a point in time, as an
integral day number of input flavour plus day fraction in the range
[0, 1).  The function returns a list of two items: the day number and
fractional day of output flavour, which together identify the same point
in time as the input.

=item msdn_to_msdn(MSDN[, MSDF])

=item msdn_to_jsn(MSDN[, MSDF])

=item msdn_to_cmsdn(MSDN, MSDF, ZONE)

=item jsn_to_msdn(JSN[, JSF])

=item jsn_to_jsn(JSN[, JSF])

=item jsn_to_cmsdn(JSN, JSF, ZONE)

=item cmsdn_to_msdn(CMSDN, CMSDF, ZONE)

=item cmsdn_to_jsn(CMSDN, CMSDF, ZONE)

=item cmsdn_to_cmsdn(CMSDN[, CMSDF])

These functions convert from an integral day count with separate fraction
to an integral day count, possibly with separate fraction.  The input
identifies a point in time, as an integral day number of input flavour
plus day fraction in the range [0, 1).  If called in scalar context, the
function returns the day number of output flavour that applies at that
instant, throwing away information about the time of (output-flavour) day.
If called in list context, the function returns a list of two items:
the day number and fractional day of output flavour, which together
identify the same point in time as the input.

If converting between systems that delimit days identically (e.g.,
between JS and MSD), the day fraction makes no difference to the integral
day number of the output, and may be omitted from the input.  If the day
fraction is extracted from the output when it wasn't supplied as input,
it will default to zero.

These functions are not recommended, because the context-sensitive
return convention makes their use error-prone.  They are retained for
backward compatibility.  You should prefer to use the more specific
functions shown above.

=cut

eval { local $SIG{__DIE__};
	require POSIX;
	*_floor = \&POSIX::floor;
};
if($@ ne "") {
	*_floor = sub($) {
		my $i = int($_[0]);
		return $i == $_[0] || $_[0] > 0 ? $i : $i - 1;
	}
}

sub _check_dn($$) {
	croak "purported day number $_[0] is not an integer"
		unless ref($_[0]) ? $_[0]->is_int : $_[0] == int($_[0]);
	croak "purported day fraction $_[1] is out of range [0, 1)"
		unless $_[1] >= 0 && $_[1] < 1;
}

sub _ret_dnn($) {
	my $dn = ref($_[0]) eq "Math::BigRat" ?
			$_[0]->copy->bfloor : _floor($_[0]);
	return $dn;
}

sub _ret_dnf($) {
	my $dn = &_ret_dnn;
	return ($dn, $_[0] - $dn);
}

sub _ret_dn($) {
	return wantarray ? &_ret_dnf : &_ret_dnn;
}

foreach my $src (keys %msd_flavours) { foreach my $dst (keys %msd_flavours) {
	my $ediff = $msd_flavours{$src}->{epoch_msd} -
			$msd_flavours{$dst}->{epoch_msd};
	my $ediffh = $ediff == int($ediff) ? 0 : 0.5;
	my $src_zone = !!$msd_flavours{$src}->{zone};
	my $dst_zone = !!$msd_flavours{$dst}->{zone};
	my($zp, $z1, $z2);
	if($src_zone == $dst_zone) {
		$zp = $z1 = $z2 = "";
	} else {
		$zp = "\$";
		my $zsign = $src_zone ? "-" : "+";
		$z1 = "$zsign \$_[1]";
		$z2 = "$zsign \$_[2]";
	}
	eval "sub ${src}_to_${dst}(\$${zp}) { \$_[0] + (${ediff}) ${z1} }";
	push @EXPORT_OK, "${src}_to_${dst}";
	eval "sub ${src}_to_${dst}nn(\$${zp}) {
		_ret_dnn(\$_[0] + (${ediff}) ${z1})
	}";
	push @EXPORT_OK, "${src}_to_${dst}nn";
	eval "sub ${src}_to_${dst}nf(\$${zp}) {
		_ret_dnf(\$_[0] + (${ediff}) ${z1})
	}";
	push @EXPORT_OK, "${src}_to_${dst}nf";
	eval "sub ${src}_to_${dst}n(\$${zp}) {
		_ret_dn(\$_[0] + (${ediff}) ${z1})
	}";
	push @EXPORT_OK, "${src}_to_${dst}n";
	eval "sub ${src}n_to_${dst}(\$\$${zp}) {
		_check_dn(\$_[0], \$_[1]);
		\$_[0] + \$_[1] + (${ediff}) ${z2}
	}";
	push @EXPORT_OK, "${src}n_to_${dst}";
	my($tp, $tc);
	if($ediffh == 0 && $src_zone == $dst_zone) {
		$tp = ";";
		$tc = "push \@_, 0 if \@_ == 1;";
	} else {
		$tp = $tc = "";
	}
	eval "sub ${src}n_to_${dst}nn(\$${tp}\$${zp}) { $tc
		_check_dn(\$_[0], \$_[1]);
		_ret_dnn(\$_[0] + \$_[1] + ($ediff) ${z2})
	}";
	push @EXPORT_OK, "${src}n_to_${dst}nn";
	eval "sub ${src}n_to_${dst}nf(\$\$${zp}) {
		_check_dn(\$_[0], \$_[1]);
		_ret_dnf(\$_[0] + \$_[1] + ($ediff) ${z2})
	}";
	push @EXPORT_OK, "${src}n_to_${dst}nf";
	eval "sub ${src}n_to_${dst}n(\$${tp}\$${zp}) { $tc
		_check_dn(\$_[0], \$_[1]);
		_ret_dn(\$_[0] + \$_[1] + ($ediff) ${z2})
	}";
	push @EXPORT_OK, "${src}n_to_${dst}n";
} }

=back

=head1 SEE ALSO

L<Date::Darian::Mars>,
L<Date::JD>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2007, 2009, 2010, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
