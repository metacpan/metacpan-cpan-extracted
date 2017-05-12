package Apache::Voodoo::Validate::date;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo::Validate::Plugin");

sub config {
	my ($self,$c) = @_;
	my @e;

	if (defined($c->{valid})) {
		if ($c->{valid} =~ /^(past|future)$/ ) {
			$self->{valid} = $c->{valid};
		}
		elsif (ref($c->{valid}) ne "CODE") {
			push(@e,"'valid' must be either 'past','future', or a subroutine reference");
		}
	}

	if (defined($c->{now})) {
		if (ref($c->{now}) eq "CODE") {
			$self->{now} = $c->{now};
		}
		else {
			push(@e,"'now' must be a subroutine reference");
		}
	}
	else {
		$self->{now} = \&_default_now;
	}

	if (defined($c->{parser})) {
		if (ref($c->{parser}) eq "CODE") {
			$self->{parser} = $c->{parser};
		}
		else {
			push(@e,"'parser' must be a subroutine reference");
		}
	}
	else {
		$self->{parser} = \&_default_parser;
	}

	return @e;
}

sub valid {
	my ($self,$v) = @_;

	my $e;
	my ($y,$m,$d) = $self->{parser}->($v);

	if (defined($y)   &&
		defined($m)   &&
		defined($d)   &&
		$y =~ /^\d+$/ &&
		$m =~ /^\d+$/ &&
		$d =~ /^\d+$/) {

		$v = sprintf("%04d-%02d-%02d",$y,$m,$d);

		if (defined($self->{'valid'})) {	# supresses warnings.
			if ($self->{'valid'} eq "past" && $v gt $self->{now}->()) {
				$e = 'PAST';
			}
			elsif ($self->{'valid'} eq "future" && $v le $self->{now}->()) {
				$e = 'FUTURE';
			}
		}
	}
	else {
		$e = 'BAD';
	}

	return $v,$e;
}

sub _default_now {
	my @tp = localtime();
	return sprintf("%04d-%02d-%02d",$tp[5]+1900,$tp[4]+1,$tp[3]);
}

sub _default_parser {
	my $date = shift;

	# Number of days in each month
	my %md = (1  => 31,
	          2  => 29,
	          3  => 31,
	          4  => 30,
	          5  => 31,
	          6  => 30,
	          7  => 31,
	          8  => 31,
	          9  => 30,
	          10 => 31,
	          11 => 30,
	          12 => 31);

	# Split the date up into month day year
	my ($m,$d,$y);

	if ($date =~ /^\d?\d\/\d?\d\/\d{4}$/) {
		($m,$d,$y) = split("/",$date, 3);
	}
	elsif ($date =~ /^\d{4}-\d?\d-\d?\d$/) {
		($y,$m,$d) = split("-",$date, 3);
	}
	else {
		return undef;
	}

	#Strip off any leading 0s
	$m *= 1;
	$d *= 1;
	$y *= 1;

	# If the month isn't within a valid range return
	if ($m !~ /^\d+$/ || $m < 1 || $m > 12) {
		return undef;
	}

	# Check to see if the day is valid on leap years
	if ($m == 2 && $d == 29) {
		unless (($y%4 == 0 && $y%100 != 0) || $y%400 == 0){
			return undef;
		}
	}

	# If the day isn't within a valid range return
	if ($d !~ /^\d+$/ || $d < 1 || $d > $md{$m}) {
		return undef;
	}

	# make sure the year is four digits
	if ($y !~ /^\d+$/ || $y < 1000 || $y > 9999) {
		return undef;
	}

	return $y,$m,$d;
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
