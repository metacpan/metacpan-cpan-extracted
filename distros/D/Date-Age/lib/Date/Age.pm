package Date::Age;

use strict;
use warnings;
use Exporter 'import';
use Time::Local qw(timelocal);

our @EXPORT_OK = qw(describe details);

=head1 NAME

Date::Age - Return an age or age range from date(s)

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  use Date::Age qw(describe details);

  say describe('1943', '2016-01-01');    # '72-73'

  my $data = details('1943-05-01', '2016-01-01');
  # { min_age => 72, max_age => 72, range => '72', precise => 72 }

=head1 DESCRIPTION

This module calculates the age or possible age range between a date of birth
and another date (typically now or a death date).
It works even with partial dates.

=cut

sub describe {
	my ($dob, $ref) = @_;
	my $info = details($dob, $ref);
	return $info->{range};
}

sub details {
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
	return localtime->ymd();
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
