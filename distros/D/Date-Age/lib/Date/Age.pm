package Date::Age;

use strict;
use warnings;
use Exporter 'import';
use Time::Local;
use Time::Piece;

our @EXPORT_OK = qw(describe details);

=head1 NAME

Date::Age - Return an age or age range from date(s)

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Date::Age qw(describe details);

  say describe("1943", "2016-01-01");    # "72-73"

  my $data = details("1943-05-01", "2016-01-01");
  # { min_age => 72, max_age => 72, range => "72", precise => 72 }

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

	my $min_age = _calc_age($dob_late, $ref_early);
	my $max_age = _calc_age($dob_early, $ref_late);

	my $range_str = $min_age == $max_age ? "$min_age" : "$min_age–$max_age";
	my $precise  = ($min_age == $max_age) ? $min_age : undef;

	return {
		min_age => $min_age,
		max_age => $max_age,
		range   => $range_str,
		precise => $precise,
	};
}

sub _now_string {
	return localtime->ymd();
}

sub _calc_age {
	my ($dob, $ref) = @_;
	my $dob_tp = Time::Piece->strptime($dob, "%Y-%m-%d");
	my $ref_tp = Time::Piece->strptime($ref, "%Y-%m-%d");

	my $age = $ref_tp->year - $dob_tp->year;
	if ($ref_tp->mon < $dob_tp->mon || ($ref_tp->mon == $dob_tp->mon && $ref_tp->mday < $dob_tp->mday)) {
		$age--;
	}
	return $age;
}

sub _parse_date_range {
	my $date = shift;

	if ($date =~ /^\d{4}-\d{2}-\d{2}$/) {
		return ($date, $date);
	} elsif ($date =~ /^(\d{4})-(\d{2})$/) {
		my ($y, $m) = ($1, $2);
		return ("$y-$m-01", _end_of_month($y, $m));
	} elsif ($date =~ /^(\d{4})$/) {
		return ("$1-01-01", "$1-12-31");
	} else {
		die "Unrecognized date format: $date";
	}
}

sub _end_of_month {
	my ($y, $m) = @_;

	my @days_in_month = (31, 28 + _is_leap($y), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	return sprintf("%04d-%02d-%02d", $y, $m, $days_in_month[$m - 1]);
}

sub _is_leap {
	my $y = shift;

	return 0 if $y % 4;
	return 1 if $y % 100;
	return 0 if $y % 400;
	return 1;
}

1;

__END__

=head1 REPOSITORY

L<https://github.com/nigelhorne/Date-Age>
