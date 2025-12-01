package Date::Age;

use 5.010;

use strict;
use warnings;

use Carp qw(carp croak);
use Exporter 'import';
use Time::Local qw(timelocal);

our @EXPORT_OK = qw(describe details);

=head1 NAME

Date::Age - Return an age or age range from date(s)

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

  use Date::Age qw(describe details);

  print describe('1943', '2016-01-01'), "\n";	# '72-73'

  my $data = details('1943-05-01', '2016-01-01');
  # { min_age => 72, max_age => 72, range => '72', precise => 72 }

=head1 DESCRIPTION

This module calculates the age or possible age range between a date of birth
and another date (typically now or a death date).
It works even with partial dates.

=head1 METHODS

=head1 FUNCTIONS

=head2 describe

  my $range = describe($dob);
  my $range = describe($dob, $ref_date);

Returns a human-readable age or age range for the supplied date of birth.

C<describe()> accepts a date of birth in any of the formats supported by
L</details> (year only, year-month, or full year-month-day).  An optional
reference date may also be provided; if omitted, the current local date is
used.

Because partial dates imply uncertainty, the routine may return either a
single age (e.g. C<"72">) or an age range (e.g. C<"72-73">).  Year-only and
year-month dates can span a range of possible birthdays, and therefore a
range of possible ages.

Examples:

  describe('1943');	# e.g. '80-81'
  describe('1943-05', '2016');	# '72-73'
  describe('1943-05-01', '2016-01-01');  # '72'

This routine is a convenience wrapper around C<details()> that returns only
the formatted range string.

=cut

sub describe {
	if($_[0] eq __PACKAGE__) {
		shift;
	}

	croak('Usage: ', __PACKAGE__, '::describe($dob, $ref)') if(scalar(@_) == 0);

	my ($dob, $ref) = @_;
	my $info = details($dob, $ref);
	return $info->{range};
}

=head2 details

  my $info = details($dob);
  my $info = details($dob, $ref_date);

Returns a hashref describing the full computed age information.  This routine
performs the underlying date-range expansion and age calculation that
C<describe()> relies on.

The returned hashref contains:

=over 4

=item * C<min_age>

The minimum possible age based on the earliest possible birthday within the
supplied date specification.

=item * C<max_age>

The maximum possible age based on the latest possible birthday.

=item * C<range>

A string representation of the age or age range, such as C<"72"> or
C<"72-73">.

=item * C<precise>

If the age is unambiguous (e.g. the date of birth and reference date are both
fully specified), this is the exact age as an integer.  Otherwise it is
C<undef>.

=back

Supported date formats for both C<$dob> and C<$ref_date> are:

=over 4

=item * C<YYYY> - year only (e.g. C<1943>)

=item * C<YYYY-MM> - year and month (e.g. C<1943-05>)

=item * C<YYYY-MM-DD> - full date (e.g. C<1943-05-01>)

=back

Invalid or unrecognised date strings will cause the routine to C<croak()>.

Example:

  my $info = details('1943-05-01', '2016-01-01');

  # {
  #   min_age => 72,
  #   max_age => 72,
  #   range   => '72',
  #   precise => 72,
  # }

When the reference date is omitted, the current local date (YYYY-MM-DD) is
used.

=cut

sub details {
	if($_[0] eq __PACKAGE__) {
		shift;
	}

	croak('Usage: ', __PACKAGE__, '::details($dob, $ref)') if(scalar(@_) == 0);

	my ($dob, $ref) = @_;

	my ($dob_early, $dob_late) = _parse_date_range($dob);
	my ($ref_early, $ref_late) = _parse_date_range($ref // _now_string());

	my $min_age = _calc_age_localtime($dob_late,  $ref_early);
	my $max_age = _calc_age_localtime($dob_early, $ref_late);

	my $range_str = $min_age == $max_age ? $min_age : "$min_age-$max_age";
	my $precise = ($min_age == $max_age) ? $min_age : undef;

	return {
		min_age => $min_age,
		max_age => $max_age,
		range => $range_str,
		precise => $precise,
	};
}

sub _now_string {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
	return sprintf('%04d-%02d-%02d', $year + 1900, $mon + 1, $mday);
}

sub _calc_age_localtime {
	my ($dob, $ref) = @_;  # both in YYYY-MM-DD format

	# Parse manually
	my ($dy, $dm, $dd) = split /-/, $dob;
	my ($ry, $rm, $rd) = split /-/, $ref;

	# Convert to epoch for comparison
	# Note: months are 0-11 for timelocal
	my $dob_epoch = timelocal(0, 0, 0, $dd, $dm - 1, $dy);
	my $ref_epoch = timelocal(0, 0, 0, $rd, $rm - 1, $ry);

	my $age = $ry - $dy;

	# Check if birthday has occurred this year
	if ($ref_epoch < timelocal(0, 0, 0, $dd, $dm - 1, $ry)) {
		$age--;
	}

	return $age;
}

sub _parse_date_range {
	my $date = shift;

	if ($date =~ /^\d{4}-\d{2}-\d{2}$/) {
		_validate_ymd_strict($date);
		return ($date, $date);
	} elsif ($date =~ /^(\d{4})-(\d{2})$/) {
		my ($y, $m) = ($1, $2);
		die "Invalid month in date '$date'" if $m < 1 || $m > 12;

		my $start = "$y-$m-01";
		my $end = _end_of_month($y, $m);

		_validate_ymd_strict($start);
		_validate_ymd_strict($end);

		return ($start, $end);
	} elsif ($date =~ /^(\d{4})$/) {
		return ("$1-01-01", "$1-12-31");
	} else {
		die "Unrecognized date format: $date";
	}
}

sub _validate_ymd_strict {
	my $date = $_[0];

	# YYYY-MM-DD only
	return unless $date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
	my ($y, $m, $d) = ($1, $2, $3);

	die "Invalid month in date '$date'" if $m < 1 || $m > 12;

	my @dim = (31, 28 + _is_leap($y), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	my $max_d = $dim[$m - 1];

	die "Invalid day in date '$date'" if $d < 1 || $d > $max_d;
}

sub _end_of_month {
	my ($y, $m) = @_;

	my @days_in_month = (31, 28 + _is_leap($y), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	return sprintf('%04d-%02d-%02d', $y, $m, $days_in_month[$m - 1]);
}

sub _is_leap {
	my $y = $_[0];

	return 1 if $y % 400 == 0;
	return 0 if $y % 100 == 0;
	return 1 if $y % 4 == 0;
	return 0;
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * Test coverage report: L<https://nigelhorne.github.io/Date-Age/coverage/>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Date-Age>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-date-age at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Age>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Date::Age

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Date-Age>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Age>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Date-Age>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Date::Age>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut
