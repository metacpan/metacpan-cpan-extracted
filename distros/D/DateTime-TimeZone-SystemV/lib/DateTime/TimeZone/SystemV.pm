=head1 NAME

DateTime::TimeZone::SystemV - System V and POSIX timezone strings

=head1 SYNOPSIS

	use DateTime::TimeZone::SystemV;

	$tz = DateTime::TimeZone::SystemV->new(
		name => "US Eastern",
		recipe => "EST5EDT,M3.2.0,M11.1.0");
	$tz = DateTime::TimeZone::SystemV->new(
		"EST5EDT,M3.2.0,M11.1.0");

	if($tz->is_floating) { ...
	if($tz->is_utc) { ...
	if($tz->is_olson) { ...
	$category = $tz->category;
	$tz_string = $tz->name;

	if($tz->has_dst_changes) { ...
	if($tz->is_dst_for_datetime($dt)) { ...
	$offset = $tz->offset_for_datetime($dt);
	$abbrev = $tz->short_name_for_datetime($dt);
	$offset = $tz->offset_for_local_datetime($dt);

=head1 DESCRIPTION

An instance of this class represents a timezone that was specified by
means of a System V timezone recipe or an extended form of the same syntax
(such as that specified by POSIX).  These can express a plain offset from
Universal Time, or a system of two offsets (standard and daylight saving
time) switching on a yearly cycle according to certain types of rule.

This class implements the L<DateTime::TimeZone> interface, so that its
instances can be used with L<DateTime> objects.

=head1 SYSTEM V TIMEZONE RECIPE SYSTEM

This module supports multiple versions of the timezone recipe syntax
derived from System V.  Specifically, it supports the version specified
by POSIX.1, and the extension of the POSIX format that is used by version
3 of the L<tzfile(5)> file format.

A timezone may be specified that has a fixed offset by the
syntax "I<aaa>I<ooo>", or a timezone with DST by the syntax
"I<aaa>I<ooo>I<aaa>[I<ooo>]B<,>I<rrr>B<,>I<rrr>".  "I<aaa>" specifies an
abbreviation by which an offset is known, "I<ooo>" specifies the offset,
and "I<rrr>" is a rule for when DST starts or ends.  For backward
compatibility, the rules part may also be omitted from a DST-using
timezone, in which case some built-in default rules are used; don't rely
on those rules being useful.

An abbreviation must be a string of three or more characters from ASCII
alphanumerics, "B<+>", and "B<->".  If it contains only ASCII alphabetic
characters then the abbreviation specification "I<aaa>" may be simply
the abbreviation.  Otherwise "I<aaa>" must consist of the abbreviation
wrapped in angle brackets ("B<< < >>...B<< > >>").  The angle bracket
form is always allowed.  POSIX allows an implementation to set an upper
limit on the length of timezone abbreviations.  The limit is known as
C<TZNAME_MAX>, and is required to be no less than 6 (characters/bytes).
Abbreviations longer than 6 characters are therefore not portable.
This class imposes no such limit.

An offset (from Universal Time), "I<ooo>", is given in hours, or
hours and minutes, or hours and minutes and seconds, with an optional
preceding sign.  Hours, minutes, and seconds must be separated by colons.
The hours may be one or two digits, and the minutes and seconds must be
two digits each.  The maximum magnitude permitted is 24:59:59.  The sign
in the specification is the opposite of the sign of the actual offset.
If no sign is given then the default is "B<+>", meaning a timezone that
is behind UT (or equal to UT if the offset is zero).  If no DST offset
is specified, it defaults to one hour ahead of the standard offset.

A DST-using timezone has one transition to DST and one transition to
standard time in each Gregorian year.  The transitions may be in either
order within the year.  If the transitions are in different orders from
year to year then the behaviour is undefined; don't rely on it remaining
the same in future versions.  Likewise, the behaviour is generally
undefined if transitions coincide.  However, in the L<tzfile(5)> variant,
if the rules specify a transition to DST at 00:00 standard time on 1
January and a transition to standard time at 24:00 standard time on 31
December, which makes the transitions coincide with those of adjacent
years, then the timezone is treated as observing DST all year.

A transition rule "I<rrr>" takes the form "I<ddd>[B</>I<ttt>]", where
"I<ddd>" is the rule giving the day on which the transition notionally
takes place and "I<ttt>" is the time of day at which the transition
takes place.  (A time of day outside the usual 24-hour range can make
the transition actually take place on a different day.)  The time may be
given in hours, or hours and minutes, or hours and minutes and seconds.
Hours, minutes, and seconds must be separated by colons.  The minutes
and seconds must be two digits each.  In the POSIX variant, the hours
may be one or two digits, with no preceding sign, and the time stated may
range from 00:00:00 to 24:59:59 (almost an hour into the following day).
In the L<tzfile(5)> variant, the hours may be one to three digits, with
optional preceding sign, and the time stated may range from -167:59:59
to +167:59:59 (a span of a little over two weeks).  If the time is not
stated then it defaults to 02:00:00.  The time for the transition to DST
is interpreted according to the standard offset, and the time for the
transition to standard time is interpreted according to the DST offset.
(Thus normally the transition time is interpreted according to the offset
that prevailed immediately before the transition.)

A day rule "I<ddd>" may take three forms.  Firstly, "B<J>I<nnn>" means the
month-day date that is the I<nnn>th day of a non-leap year.  Thus "B<J59>"
means the February 28 and "B<J60>" means March 1 (even in a leap year).
February 29 cannot be specified this way.

Secondly, if "I<ddd>" is just a decimal number, it means the (1+I<ddd>)th
day of the year.  February 29 counts in this case, and it is not possible
to specify December 31 of a leap year.

Thirdly, "I<ddd>" may have the form "B<M>I<m>B<.>I<w>B<.>I<d>" means day
I<d> of the I<w>th week of the I<m>th month.  The day is given as a single
digit, with "B<0>" meaning Sunday and "B<6>" meaning Saturday.  The first
week contains days 1 to 7 of the month, the second week contains days 8
to 14, and so on.  If "I<w>" is "B<5>" then the last week of the month
(containing its last seven days) is used, rather than the fifth week
(which is incomplete).

Examples:

=over

=item MUT-4

Mauritius time, since 1907: 4 hours ahead of UT all year.

=item EST5EDT,M3.2.0,M11.1.0

US Eastern timezone with DST, from 2007 onwards.  5 hours behind UT in
winter and 4 hours behind in summer.  Changes on the second Sunday in
March and the first Sunday in November, in each case at 02:00 local time.

=item NST3:30NDT,M3.2.0/0:01,M11.1.0/0:01

Newfoundland timezone with DST, from 2007 onwards.  3.5 hours behind UT
in winter and 2.5 hours behind in summer.  Changes on the second Sunday in
March and the first Sunday in November, in each case at 00:01 local time.

=item GMT0BST,M3.5.0/1,M10.5.0

UK civil time, from 1996 onwards.  On UT during the winter, calling
it "GMT", and 1 hour ahead of UT during the summer, called "BST".
Changes on the last Sunday in March and the last Sunday in October,
in each case at 01:00 UT.

=item EST-10EST,M10.5.0,M3.5.0/3

Australian Eastern timezone, from 2007 onwards.  10 hours ahead of UT in
the southern winter (the middle of the calendar year), and 11 hours ahead
in the southern summer.  Changes to DST on the last Sunday in October,
and back on the last Sunday in March, in each case at 02:00 standard time
(16:00 UT of the preceding day).

=item EET-2EEST,M3.5.4/24,M9.3.6/145

Palestinian civil time, from 2012 onwards.  2 hours ahead of UT in winter
and 3 hours ahead in summer.  Changes at the end (24:00 local time) of
the last Thursday in March and 01:00 local time on the Friday following
the third Saturday in September (that is, the Friday falling between
September 21 and September 27 inclusive).  The extended time-of-day "145",
meaning 01:00 of the day six days after the nominal day, is only valid
in the L<tzfile(5)> variant of the System V syntax.  The time-of-day
"24" is not so restricted, being permitted by POSIX.

=back

=cut

package DateTime::TimeZone::SystemV;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Date::ISO8601 0.000
	qw(month_days ymd_to_cjdn present_ymd year_days cjdn_to_yd cjdn_to_ywd);
use Params::Classify 0.000 qw(is_undef is_string);

our $VERSION = "0.009";

my $rdn_epoch_cjdn = 1721425;

my $abbrev_rx = qr#[A-Za-z]{3,}|\<[-+0-9A-Za-z]{3,}\>#;
my $offset_rx = qr#[-+]?(?:2[0-4]|[01]?[0-9])(?::[0-5][0-9](?::[0-5][0-9])?)?#;
my $rule_date_rx = qr#J0*(?:3(?:[0-5][0-9]|6[0-5])|[12]?[0-9][0-9]|[1-9])
		     |0*(?:3(?:[0-5][0-9]|6[0-4])|[12]?[0-9][0-9]|[0-9])
		     |M0*(?:1[0-2]|[1-9])\.0*[1-5]\.0*[0-6]#x;
my $posix_rule_time_rx =
	qr#(?:2[0-4]|[01]?[0-9])(?::[0-5][0-9](?::[0-5][0-9])?)?#;
my $tzfile3_rule_time_rx =
	qr#[-+]?(?:16[0-7]|1[0-5][0-9]|0[0-9][0-9]|[0-9]{1,2})
	   (?::[0-5][0-9](?::[0-5][0-9])?)?#x;
my $posix_rule_dt_rx = qr#${rule_date_rx}(?:/${posix_rule_time_rx})?#o;
my $tzfile3_rule_dt_rx = qr#${rule_date_rx}(?:/${tzfile3_rule_time_rx})?#o;
my $posix_tz_rx = qr#${abbrev_rx}${offset_rx}
		    (?:${abbrev_rx}(?:${offset_rx})?
		       (?:,${posix_rule_dt_rx},${posix_rule_dt_rx})?)?#xo;
my $tzfile3_tz_rx = qr#${abbrev_rx}${offset_rx}
		    (?:${abbrev_rx}(?:${offset_rx})?
		       (?:,${tzfile3_rule_dt_rx},${tzfile3_rule_dt_rx})?)?#xo;

my %tz_rx = (
	posix => $posix_tz_rx,
	tzfile3 => $tzfile3_tz_rx,
);

sub _parse_abbrev($) {
	my($spec) = @_;
	return $spec =~ /\A\<(.*)\>\z/s ? $1 : $spec;
}

sub _parse_offset($) {
	my($spec) = @_;
	my($sign, $h, $m, $s) =
		($spec =~ /\A([-+]?)([0-9]+)(?::([0-9]+)(?::([0-9]+))?)?\z/);
	return ($sign eq "-" ? 1 : -1) *
		($h*3600 + (defined($m) ? $m*60 + (defined($s) ? $s : 0) : 0))
		|| 0;
}

sub _parse_rule($$) {
	my($spec, $offset) = @_;
	my($drule, $tod) = split(m#/#, $spec);
	return {
		drule => $drule,
		sod => -$offset +
			(defined($tod) ? -_parse_offset($tod) : 7200),
	};
}

=head1 CONSTRUCTOR

=over

=item DateTime::TimeZone::SystemV->new(ATTR => VALUE, ...)

Constructs and returns a L<DateTime>-compatible timezone object that
implements the timezone described by the recipe given in the arguments.
The following attributes may be given:

=over

=item B<name>

Name for the timezone object.  This will be returned by the C<name>
method described below, and will be included in certain error messages.
If not given, then the recipe is used as the timezone name.

=item B<recipe>

The short textual timezone recipe, as described in L</SYSTEM V TIMEZONE
RECIPE SYSTEM>.  Must be given.

=item B<system>

Keyword identifying the particular variant of the recipe system according
to which the recipe is to be interpreted.  It may be:

=over

=item B<posix> (default)

As specified by POSIX.1.

=item B<tzfile3>

As specified by version 3 of the L<tzfile(5)> file format.

=back

=back

=item DateTime::TimeZone::SystemV->new(RECIPE)

Simpler way to invoke the above constructor in the usual case.  Only the
recipe is given; it will be interpreted according to POSIX system,
and the recipe will also be used as the timezone name.

=cut

sub new {
	my $class = shift;
	unshift @_, "recipe" if @_ == 1;
	my $self = bless({}, $class);
	my $recipe;
	my $system;
	while(@_) {
		my $attr = shift;
		my $value = shift;
		if($attr eq "name") {
			croak "timezone name specified redundantly"
				if exists $self->{name};
			croak "timezone name must be a string"
				unless is_string($value);
			$self->{name} = $value;
		} elsif($attr eq "recipe") {
			croak "recipe specified redundantly"
				if defined $recipe;
			croak "recipe must be a string"
				unless is_string($value);
			$recipe = $value;
		} elsif($attr eq "system") {
			croak "system identifier specified redundantly"
				if defined $system;
			croak "system identifier must be a string"
				unless is_string($value);
			croak "system identifier not recognised"
				unless exists $tz_rx{$value};
			$system = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	croak "recipe not specified" unless defined $recipe;
	$self->{name} = $recipe unless exists $self->{name};
	$system = "posix" unless defined $system;
	croak "not a valid SysV-style timezone recipe"
		unless $recipe =~ /\A$tz_rx{$system}\z/;
	$recipe =~ /\A($abbrev_rx)($offset_rx)/og;
	my($std_abbrev, $std_offset) = ($1, $2);
	$self->{std_abbrev} = _parse_abbrev($std_abbrev);
	$self->{std_offset} = _parse_offset($std_offset);
	return $self if $recipe =~ /\G\z/gc;
	$recipe =~ /\G($abbrev_rx)($offset_rx)?/g;
	my($dst_abbrev, $dst_offset) = ($1, $2);
	$self->{dst_abbrev} = _parse_abbrev($dst_abbrev);
	$self->{dst_offset} = defined($dst_offset) ?
		_parse_offset($dst_offset) : $self->{std_offset} + 3600;
	my($start_rule, $end_rule);
	if($recipe =~ /\G,(.*),(.*)/g) {
		($start_rule, $end_rule) = ($1, $2);
	} else {
		# default to US 1976 rules, which is what the ruleless
		# old SysV style specs were expected to do
		($start_rule, $end_rule) = ("M4.5.0", "M10.5.0");
	}
	$self->{start_rule} = _parse_rule($start_rule, $self->{std_offset});
	$self->{end_rule} = _parse_rule($end_rule, $self->{dst_offset});
	if($system eq "tzfile3" &&
			$self->{start_rule}->{drule} =~ /\A(?:J0*1|0+)\z/ &&
			$self->{start_rule}->{sod} == -$self->{std_offset} &&
			$self->{end_rule}->{drule} =~ /\AJ0*365\z/ &&
			$self->{end_rule}->{sod} == 86400-$self->{std_offset}) {
		delete $self->{$_}
			foreach qw(std_abbrev std_offset start_rule end_rule);
	}
	return $self;
}

=back

=head1 METHODS

These methods are all part of the L<DateTime::TimeZone> interface.
See that class for the general meaning of these methods; the documentation
below only comments on the specific behaviour of this class.

=head2 Identification

=over

=item $tz->is_floating

Returns false.

=cut

sub is_floating { 0 }

=item $tz->is_utc

Returns false.

=cut

sub is_utc { 0 }

=item $tz->is_olson

Returns false.

=cut

sub is_olson { 0 }

=item $tz->category

Returns C<undef>, because the category concept doesn't properly apply
to these timezones.

=cut

sub category { undef }

=item $tz->name

Returns the timezone name.  Usually this is the recipe that was supplied
to the constructor, but it can be overridden by the constructor's B<name>
attribute.

=cut

sub name { $_[0]->{name} }

=back

=head2 Offsets

=over

=item $tz->has_dst_changes

Returns a truth value indicating whether the timezone includes a DST offset.

=cut

sub has_dst_changes { exists $_[0]->{dst_abbrev} }

=item $tz->is_dst_for_datetime(DT)

I<DT> must be a L<DateTime>-compatible object (specifically, it must
implement the C<utc_rd_values> method).  Returns a truth value indicating
whether the timezone is on DST at the instant represented by I<DT>.

=cut

sub _rule_doy($$) {
	my($drule, $year) = @_;
	if($drule =~ /\AJ([0-9]+)\z/) {
		my $j = $1;
		if($j < 60) {
			return $j;
		} else {
			return year_days($year) - 365 + $j;
		}
	} elsif($drule =~ /\A([0-9]+)\z/) {
		return 1 + $1;
	} elsif($drule =~ /\AM([0-9]+)\.([0-9]+)\.([0-9]+)\z/) {
		my($m, $w, $dow) = ($1, $2, $3);
		my $fdom = ($w == 5 ? month_days($year, $m) : $w*7) - 6;
		my(undef, undef, $fdow) =
			cjdn_to_ywd(ymd_to_cjdn($year, $m, $fdom));
		my $dom = $fdom + ($dow + 7 - $fdow) % 7;
		my(undef, $doy) = cjdn_to_yd(ymd_to_cjdn($year, $m, $dom));
		return $doy;
	} else {
		die "internal error: unrecognised day rule";
	}
}

sub _is_dst_for_utc_rdn_sod {
	my($self, $rdn, $sod) = @_;
	my($year, $doy) = cjdn_to_yd($rdn + $rdn_epoch_cjdn);
	my $soy = $doy * 86400 + $sod;
	my @latest_change;
	foreach my $change_type (qw(end_rule start_rule)) {
		for(my $y = $year+1, my $doff = year_days($year); ;
				$doff -= year_days(--$y)) {
			my $change_soy =
				($doff + _rule_doy($self->{$change_type}
							->{drule}, $y))
					* 86400 + $self->{$change_type}->{sod};
			if($change_soy <= $soy) {
				push @latest_change, $change_soy;
				last;
			}
		}
	}
	return $latest_change[1] > $latest_change[0];
}

sub is_dst_for_datetime {
	my($self, $dt) = @_;
	return 0 unless exists $self->{dst_abbrev};
	return 1 unless exists $self->{std_abbrev};
	my($utc_rdn, $utc_sod) = $dt->utc_rd_values;
	$utc_sod = 86399 if $utc_sod >= 86400;
	return $self->_is_dst_for_utc_rdn_sod($utc_rdn, $utc_sod);
}

=item $tz->offset_for_datetime(DT)

I<DT> must be a L<DateTime>-compatible object (specifically, it must
implement the C<utc_rd_values> method).  Returns the offset from UT that
is in effect at the instant represented by I<DT>, in seconds.

=cut

sub offset_for_datetime {
	my($self, $dt) = @_;
	return $self->{$self->is_dst_for_datetime($dt) ?
			"dst_offset" : "std_offset"};
}

=item $tz->short_name_for_datetime(DT)

I<DT> must be a L<DateTime>-compatible object (specifically, it
must implement the C<utc_rd_values> method).  Returns the time scale
abbreviation for the offset that is in effect at the instant represented
by I<DT>.

=cut

sub short_name_for_datetime {
	my($self, $dt) = @_;
	return $self->{$self->is_dst_for_datetime($dt) ?
			"dst_abbrev" : "std_abbrev"};
}

=item $tz->offset_for_local_datetime(DT)

I<DT> must be a L<DateTime>-compatible object (specifically, it
must implement the C<local_rd_values> method).  Takes the local
time represented by I<DT> (regardless of what absolute time it also
represents), and interprets that as a local time in the timezone of the
timezone object (not the timezone used in I<DT>).  Returns the offset
from UT that is in effect at that local time, in seconds.

If the local time given is ambiguous due to a nearby offset change, the
numerically lower offset (usually the standard one) is returned with no
warning of the situation.  If the local time given does not exist due
to a nearby offset change, the method C<die>s saying so.

=cut

sub _local_to_utc_rdn_sod($$$) {
	my($rdn, $sod, $offset) = @_;
	$sod -= $offset;
	while($sod < 0) {
		$rdn--;
		$sod += 86400;
	}
	while($sod >= 86400) {
		$rdn++;
		$sod -= 86400;
	}
	return ($rdn, $sod);
}

sub _is_dst_for_local_datetime {
	my($self, $dt) = @_;
	return 0 unless exists $self->{dst_abbrev};
	return 1 unless exists $self->{std_abbrev};
	my($lcl_rdn, $lcl_sod) = $dt->local_rd_values;
	$lcl_sod = 86399 if $lcl_sod >= 86400;
	my($std_rdn, $std_sod) =
		_local_to_utc_rdn_sod($lcl_rdn, $lcl_sod, $self->{std_offset});
	my($dst_rdn, $dst_sod) =
		_local_to_utc_rdn_sod($lcl_rdn, $lcl_sod, $self->{dst_offset});
	my $std_ok = !$self->_is_dst_for_utc_rdn_sod($std_rdn, $std_sod);
	my $dst_ok = $self->_is_dst_for_utc_rdn_sod($dst_rdn, $dst_sod);
	if($std_ok) {
		if($dst_ok) {
			return $self->{std_offset} > $self->{dst_offset};
		} else {
			return 0;
		}
	} else {
		if($dst_ok) {
			return 1;
		} else {
			croak "local time @{[
				present_ymd($lcl_rdn + $rdn_epoch_cjdn)
			]}T@{[
				sprintf(q(%02d:%02d:%02d),
					int($lcl_sod/3600),
					int($lcl_sod/60)%60,
					$lcl_sod%60)
			]} does not exist in the @{[$self->{name}]} timezone ".
				"due to offset change";
		}
	}
}

sub offset_for_local_datetime {
	my($self, $dt) = @_;
	return $self->{$self->_is_dst_for_local_datetime($dt) ?
			"dst_offset" : "std_offset"};
}

=back

=head1 SEE ALSO

L<DateTime>,
L<DateTime::TimeZone>,
L<POSIX.1|http://www.opengroup.org/onlinepubs/000095399/basedefs/xbd_chap08.html>,
L<tzfile(5)>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2007, 2009, 2010, 2011, 2012, 2013
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
