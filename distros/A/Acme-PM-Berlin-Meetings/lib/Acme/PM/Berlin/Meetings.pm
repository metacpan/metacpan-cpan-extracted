# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2010,2012,2015,2016,2017,2020,2024 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Acme::PM::Berlin::Meetings;

use strict;
our $VERSION = '202402.28';

use Exporter 'import'; # needs Exporter 5.57
our @EXPORT = qw(next_meeting);

use DateTime;

sub next_meeting {
    my $count = shift || 1;
    my $dt = DateTime->now(time_zone => 'local');
    map { $dt = next_meeting_dt($dt) } (1 .. $count);
}

sub next_meeting_dt {
    my $dt = shift;
    my $dt_berlin = $dt->clone->set_time_zone('Europe/Berlin');

    # Regular exception: December meeting is in January
    if ($dt_berlin->month == 1 && $dt_berlin->day < 10) {
	my $dec_meeting = _get_dec_meeting($dt_berlin);
	if ($dec_meeting > $dt_berlin) {
	    return $dec_meeting;
	}
    }

    # Exceptions
    {
	# August 2020 (last Wed -> last Tue)
	my $dt_aug_2020       = DateTime->new(year=>2020, month=>8, day=>25, hour=>19, time_zone=>"Europe/Berlin");
	my $dt_aug_2020_from  = DateTime->new(year=>2020, month=>7, day=>29, hour=>19, time_zone=>"Europe/Berlin");
	my $dt_aug_2020_until = DateTime->new(year=>2020, month=>8, day=>26, hour=>19, time_zone=>"Europe/Berlin");
	if ($dt_berlin > $dt_aug_2020_from && $dt_berlin < $dt_aug_2020) {
	    return $dt_aug_2020;
	} elsif ($dt_berlin >= $dt_aug_2020 && $dt_berlin < $dt_aug_2020_until) {
	    $dt_berlin = $dt_aug_2020_until;
	}
    }
    {
	# September 2020 (last Wed, 19h -> pre-last Wed, 18h)
	my $dt_sep_2020       = DateTime->new(year=>2020, month=>9, day=>23, hour=>18, time_zone=>"Europe/Berlin");
	my $dt_sep_2020_from  = DateTime->new(year=>2020, month=>8, day=>25, hour=>19, time_zone=>"Europe/Berlin");
	my $dt_sep_2020_until = DateTime->new(year=>2020, month=>9, day=>30, hour=>19, time_zone=>"Europe/Berlin");
	if ($dt_berlin > $dt_sep_2020_from && $dt_berlin < $dt_sep_2020) {
	    return $dt_sep_2020;
	} elsif ($dt_berlin >= $dt_sep_2020 && $dt_berlin < $dt_sep_2020_until) {
	    $dt_berlin = $dt_sep_2020_until;
	}
    }

    # Regular meetings
    my $last_wed_of_month = _get_last_wed_of_month($dt_berlin);
    if ($last_wed_of_month <= $dt_berlin) {
	$dt_berlin->add(months => 1, end_of_month => 'limit');
	$last_wed_of_month = _get_last_wed_of_month($dt_berlin);
    }
    if ($last_wed_of_month->month == 12) {
	return _get_dec_meeting($last_wed_of_month);
    }
    $last_wed_of_month;    
}

sub _get_last_wed_of_month {
    my $dt_berlin = shift;
    my $last_day_of_month = DateTime->last_day_of_month(year => $dt_berlin->year, month => $dt_berlin->month, time_zone => 'Europe/Berlin');
    my $dow = $last_day_of_month->day_of_week;
    my $last_wed_of_month = $last_day_of_month->add(days => $dow < 3 ? -$dow-4 : -$dow+3);
    _adjust_hour($last_wed_of_month);
    $last_wed_of_month;
}

sub _get_dec_meeting {
    my $dt = shift;
    $dt = $dt->clone;
    if ($dt->month == 12) {
	$dt->add(months => 1); # end_of_month does not matter
    }
    $dt->set(day => 3);
    my $dow = $dt->day_of_week;
    $dt->add(days => $dow < 4 ? -$dow+3 : -$dow+10);
    _adjust_hour($dt);
    $dt;
}

sub _adjust_hour {
    my $dt = shift;
    if ($dt->year >= 2024 || ($dt->year == 2023 && $dt->month >= 5)) {
	$dt->set(hour => 18);
    } elsif ($dt->year >= 2016) {
	$dt->set(hour => 19);
    } else {
	$dt->set(hour => 20);
    }
}

1;

__END__

=head1 NAME

Acme::PM::Berlin::Meetings - get the next date of the Berlin PM meeting

=head1 SYNOPSIS

    use Acme::PM::Berlin::Meetings;
    next_meeting(1)

Or use the bundled script:

    berlin-pm

=head1 NOTES

This module knows about special Berlin.PM traditions like postponing
the December meeting to the first or second week in January.

=head1 AUTHOR

Slaven Rezic

=head1 SEE ALSO

L<Acme::PM::Barcelona::Meeting>, L<Acme::PM::Paris::Meetings>.

=cut
