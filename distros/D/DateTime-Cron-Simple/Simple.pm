##############################################
## Copyright (c) 2002-2004 - Brendan Fagan
##############################################
package DateTime::Cron::Simple;

use strict;
use vars qw($VERSION);

$VERSION = '0.2';

use DateTime;

sub new {
        my $class 	= shift;
	my $cron	= shift;
        my $can 	= { cron => $cron };
        my $obj 	= bless $can, $class;

	$obj->_init;

	return $obj;
} 

sub new_cron {
	my $obj	= shift;
	$obj->{cron} =  shift;

	$obj->_init;
}

sub validate_time {
	my $obj = shift;
	my $dt	= shift || DateTime->now;
	$dt->set_time_zone('local');

	my $ret = 1;

	unless ($obj->{min_data}->{$dt->minute}) {
		$ret = 0;
	}

	unless ($obj->{hour_data}->{$dt->hour}) {
		$ret = 0;
	}

	unless ($obj->{dom_data}->{$dt->day}) {
		$ret = 0;
	}

	unless ($obj->{month_data}->{$dt->month}) {
		$ret = 0;
	}

	unless ($obj->{dow_data}->{$dt->dow}) {
		$ret = 0;
	}

	return $ret;
}


sub _init {
	my $obj = shift;

	($obj->{min},$obj->{hour},$obj->{dom},$obj->{month},$obj->{dow}) = split(/ /,$obj->{cron});

	$obj->_set_minute;
	$obj->_set_hour;
	$obj->_set_day_of_month;
	$obj->_set_month;
	$obj->_set_day_of_week;
}

sub _set_minute {
	my $obj = shift;

	foreach my $min (0..60) {
		$obj->{min_data}->{$min} = 0;
	}

	foreach my $entry (split(/,/,$obj->{min})) {
		my ($num,$interval) = split(/\//,$entry);
		my ($num1,$num2) = split(/\-/,$num);
		
		if ($interval && $num2) {
			for (my $i = $num1; $i <= $num2; $i = $i + $interval) {
				$obj->{min_data}->{$i} = 1;
			}
		} elsif ($interval) {
			if ($num1 eq '*') {
				for (my $i = 0; $i <= 60; $i = $i + $interval) {
					$obj->{min_data}->{$i} = 1;
				}
			}
		} elsif ($num2) {
			for (my $i = $num1; $i <= $num2; $i++) {
				$obj->{min_data}->{$i} = 1;
			}
		} else {
			if ($num1 eq '*') {
				for (my $i = 0; $i <= 60; $i++) {
					$obj->{min_data}->{$i} = 1;
				}
			} else {
				$obj->{min_data}->{$num1} = 1;
			}
		}
	}
}

sub _set_hour {
	my $obj = shift;

	foreach my $hour (0..24) {
		$obj->{hour_data}->{$hour} = 0;
	}

	foreach my $entry (split(/\,/,$obj->{hour})) {
		my ($num,$interval) = split(/\//,$entry);
		my ($num1,$num2) = split(/\-/,$num);
		
		if ($interval && $num2) {
			for (my $i = $num1; $i <= $num2; $i = $i + $interval) {
				$obj->{hour_data}->{$i} = 1;
			}
		} elsif ($interval) {
			if ($num1 eq '*') {
				for (my $i = 0; $i <= 24; $i = $i + $interval) {
					$obj->{hour_data}->{$i} = 1;
				}
			}
		} elsif ($num2) {
			for (my $i = $num1; $i <= $num2; $i++) {
				$obj->{hour_data}->{$i} = 1;
			}
		} else {
			if ($num1 eq '*') {
				for (my $i = 0; $i <= 24; $i++) {
					$obj->{hour_data}->{$i} = 1;
				}
			} else {
				$obj->{hour_data}->{$num1} = 1;
			}
		}
	}
}

sub _set_day_of_month {
	my $obj = shift;

	foreach my $dom (0..31) {
		$obj->{dom_data}->{$dom} = 0;
	}

	foreach my $entry (split(/\,/,$obj->{dom})) {
		my ($num,$interval) = split(/\//,$entry);
		my ($num1,$num2) = split(/-/,$num);
		
		if ($interval && $num2) {
			for (my $i = $num1; $i <= $num2; $i = $i + $interval) {
				$obj->{dom_data}->{$i} = 1;
			}
		} elsif ($interval) {
			if ($num1 eq '*') {
				for (my $i = 0; $i <= 31; $i = $i + $interval) {
					$obj->{dom_data}->{$i} = 1;
				}
			}
		} elsif ($num2) {
			for (my $i = $num1; $i <= $num2; $i++) {
				$obj->{dom_data}->{$i} = 1;
			}
		} else {
			if ($num1 eq '*') {
				for (my $i = 0; $i <= 31; $i++) {
					$obj->{dom_data}->{$i} = 1;
				}
			} else {
				$obj->{dom_data}->{$num1} = 1;
			}
		}
	}
}

sub _set_month {
	my $obj = shift;

	foreach my $month (0..12) {
		$obj->{month_data}->{$month} = 0;
	}

	foreach my $entry (split(/\,/,$obj->{month})) {
		my ($num,$interval) = split(/\//,$entry);
		my ($num1,$num2) = split(/-/,$num);
		
		if ($interval && $num2) {
			for (my $i = $num1; $i <= $num2; $i = $i + $interval) {
				$obj->{month_data}->{$i} = 1;
			}
		} elsif ($interval) {
			if ($num1 eq '*') {
				for (my $i = 0; $i <= 12; $i = $i + $interval) {
					$obj->{month_data}->{$i} = 1;
				}
			}
		} elsif ($num2) {
			for (my $i = $num1; $i <= $num2; $i++) {
				$obj->{month_data}->{$i} = 1;
			}
		} else {
			if ($num1 eq '*') {
				for (my $i = 0; $i <= 12; $i++) {
					$obj->{month_data}->{$i} = 1;
				}
			} else {
				$obj->{month_data}->{$num1} = 1;
			}
		}
	}
}

sub _set_day_of_week {
	my $obj = shift;

	foreach my $dow (0..7) {
		$obj->{dow_data}->{$dow} = 0;
	}

	foreach my $entry (split(/\,/,$obj->{dow})) {
		my ($num,$interval) = split(/\//,$entry);
		my ($num1,$num2) = split(/-/,$num);
		
		if ($interval && $num2) {
			for (my $i = $num1; $i <= $num2; $i = $i + $interval) {
				$obj->{dow_data}->{$i} = 1;
			}
		} elsif ($interval) {
			if ($num1 eq '*') {
				for (my $i = 0; $i <= 7; $i = $i + $interval) {
					$obj->{dow_data}->{$i} = 1;
				}
			}
		} elsif ($num2) {
			for (my $i = $num1; $i <= $num2; $i++) {
				$obj->{dow_data}->{$i} = 1;
			}
		} else {
			if ($num1 eq '*') {
				for (my $i = 0; $i <= 7; $i++) {
					$obj->{dow_data}->{$i} = 1;
				}
			} else {
				$obj->{dow_data}->{$num1} = 1;
			}
		}
	}
}

1;
__END__
=pod

=head1 NAME

DateTime::Cron::Simple - Parse a cron entry and check against current time

=head1 SYNOPSIS

  use DateTime::Cron::Simple;

  $c = DateTime::Cron::Simple->new($cron);

  $boolean = $c->validate_time;

  $c->new_cron($cron);

=head1 DESCRIPTION

This module is a quick and dirty way to determine if a cron time format is valid for the current date and time.

A cron entry follows the cron format from crontab(5).

The validate_time function uses the current date and time for comparison, but will also accept a valid DateTime object as a parameter.

=head1 EXAMPLE

  use DateTime::Cron::Simple;

  $c = DateTime::Cron::Simple->new('0-59/2 10,12 * * 5');

  if($c->validate_time) { ... }

  $c->new_cron('* * 1 * 0');

  if($c->validate_time) { ... }

=head1 CHANGES

Please see the CHANGES file in the module distribution.

=head1 TO-DO

 - currently does not handle ! and > or < in cron entries
 - better code implementation

=head1 AUTHOR 

Brendan Fagan <suburbanantihero (at) yahoo (dot) com>. Comments, bug reports, patches and flames are appreciated. 

=head1 COPYRIGHT

Copyright (c) 2004 - Brendan Fagan

=cut
