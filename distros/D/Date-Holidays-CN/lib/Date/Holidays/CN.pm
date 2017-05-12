package Date::Holidays::CN;

use warnings;
use strict;
use Carp;
use base 'Exporter';
use vars qw/$VERSION @EXPORT @EXPORT_OK/;
$VERSION = '0.01';
@EXPORT = qw(is_cn_holiday cn_holidays);
@EXPORT_OK = qw(is_cn_solar_holiday is_cn_lunar_holiday);

use DateTime;
use DateTime::Calendar::Chinese;
use Time::Local;

# The Gregorian calendar/solar calendar
my $SOLAR = {
	'0101' => '元旦',
	'0214' => '情人节',
	'0308' => '妇女节',
	'0312' => '植树节',
	'0401' => '愚人节',
	'0405' => '清明节',
	'0501' => '劳动节',
	'0504' => '青年节',
	'0601' => '劳动节',
	'0701' => '建党日',
	'0801' => '建军节',
	'0910' => '教师节',
	'1001' => '国庆节',
	'1225' => '圣诞节',
};	

# The Chinese calendar/lunar calendar
my $LUNAR = {
	'0101' => '春节',
	'0115' => '元宵节',
	'0505' => '端午节',
	'0707' => '七夕情人节',
	'0815' => '中秋节',
	'0909' => '重阳节',
	'1208' => '腊八节',
	'1222' => '冬至节',
	'1230' => '除夕',
};

sub is_cn_solar_holiday {
	my ($year, $month, $day) = @_;
	defined $year  || return undef;
	defined $month || return undef;
	defined $day   || return undef;
	# the special day: mother's day and father's day
	# mother's day = 2th sunday of 5
	if ($month == 5 && ($day > 7 && $day < 15)) {
		my $time = timelocal(0,0,0, $day, $month - 1, $year);
		my @ltime = localtime($time);
		return '母亲节' if ($ltime[6] == 0);
	}
	# father's day = 3th sunday of 6
	if ($month == 6 && ($day > 14 && $day < 22)) {
		my $time = timelocal(0,1,0, $day, $month - 1, $year);
		my @ltime = localtime($time);
		return '父亲节' if ($ltime[6] == 0);
	}
	return $SOLAR->{sprintf "%02d%02d", $month, $day};
}

sub is_cn_lunar_holiday {
	my ($year, $month, $day) = @_;
	defined $year  || return undef;
	defined $month || return undef;
	defined $day   || return undef;
	
	my $dt2 = DateTime->new(
		year   => $year,
		month  => $month,
		day    => $day,
		hour   => 0,
		minute => 0,
		second => 0,
		nanosecond => 500000000,
		time_zone => 'Asia/Shanghai',
	);
	# ouch! the DateTime::Calendar::Chinese is a bit too slow!
	my $dt = DateTime::Calendar::Chinese->from_object(object => $dt2);
	return $LUNAR->{sprintf "%02d%02d", $dt->month, $dt->day};
}

sub is_cn_holiday {
	is_cn_solar_holiday(@_) || is_cn_lunar_holiday(@_);
}

sub cn_holidays {
	my ($year) = @_;
	defined $year  || return undef;

	# only provide solar calendar for now
	return $SOLAR;
}

1;
__END__
=encoding utf8

=head1 NAME

Date::Holidays::CN - Determine Chinese public holidays

=head1 SYNOPSIS

    use Date::Holidays::CN;
   
    my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
    $year  += 1900;
    $month += 1;
    if (my $holidayname = is_cn_holiday( $year, $month, $day )) {
    	print "这是个 $holidayname";
    }
    
    my $h = cn_holidays($year);
    printf "10 月 1 日是 '%s'\n", $h->{'1001'};

	# suggested
	use Date::Holidays::CN qw/is_cn_solar_holiday is_cn_lunar_holiday/;
	my $holidayname = is_cn_solar_holiday( 2005, 10, 1 ); # $day = '国庆节'
	my $is_holiday = is_cn_lunar_holiday( 2005, 9, 18 ); # $day = '中秋节'

=head1 EXPORT

=head2 is_cn_holiday( $year, $month, $day )

determine whether that day is a Chinese holiday

=head2 cn_holidays($year)

BE CAREFUL! It only provide solar calendar for now! And it's not suggested!

=head1 EXPORT_OK

SUGGESTED! quicker and more elegant!

=head2 is_cn_solar_holiday( $year, $month, $day )

determine whether that day is a Chinese holiday by the Gregorian calendar/solar calendar

=head2 is_cn_lunar_holiday( $year, $month, $day )

determine whether that day is a Chinese holiday by the Chinese calendar/lunar calendar

=head1 RETURN VALUE

if it is a holiday, return the Chinese holiday name(utf8), otherwise return undef.

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut