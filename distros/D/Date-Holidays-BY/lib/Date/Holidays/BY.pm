package Date::Holidays::BY;
our $VERSION = '3.2027.0'; # VERSION

=encoding utf8

=head1 NAME

Date::Holidays::BY - Determine public holidays and business days in Belarus.

=head1 SYNOPSIS

    use Date::Holidays::BY;

    my $holidays = Date::Holidays::BY::holidays( 2024 );
      # {
      #   "0101" => "New Year",
      #   ...
      #   "1225" => "Christmas (Catholic Christmas)"
      # }

    if ( my $holidayname = Date::Holidays::BY::is_holiday( 2007, 1, 1 ) ) {
        print "Is a holiday: $holidayname\n";
    }

    if ( Date::Holidays::BY::is_business_day( 2012, 3, 11 ) ) {
        print "2012-03-11 is a business day on a weekend\n";
    }

    if ( Date::Holidays::BY::is_short_business_day( 2015, 4, 30 ) ) {
        print "2015-04-30 is a short business day\n";
    }

    my $short_days = Date::Holidays::BY::short_business_days( 2024 );
      # {
      #   "0307" => "Pre-holiday working day",
      #   ...
      #   "1231" => "Pre-holiday working day"
      # }

=cut

=head1 DESCRIPTION

Date::Holidays::BY provides functions to check if a given date is a public holiday in Belarus. This module follows the standard holiday calendar observed in Belarus, including both national holidays and specific religious observances recognized in the country.

Imports nothing by default.

=cut

use warnings;
use strict;
use utf8;
use base 'Exporter';
use Carp;
use List::Util;

our @EXPORT_OK = qw(
    is_holiday
    is_by_holiday
    holidays
    is_business_day
    is_short_business_day
    short_business_days
);


=head1 CONFIGURATION VARIABLES

=head2 $Date::Holidays::BY::ref

Hash reference containing all static holiday data, including holiday names for i18n support.
Dates are formatted as MMDD.

=cut

our $ref = {

HOLIDAYS_VALID_SINCE => 1992,

HOLIDAYS => {
  '0101' => {
            name => {
              be => 'Новы год',
              en => 'New Year',
              ru => 'Новый год',
            },
            days => {
              1992 => [ qw( 0101 ) ],
              2020 => [ qw( 0101 0102 ) ],
            },
            },
  '0308' => {
              name => {
                be => 'Дзень жанчын',
                en => 'Women\'s Day',
                ru => 'День женщин',
              },
              days => [ qw( 0308 ) ],
            },
  '0501' => {
              name => {
                be => 'Свята працы',
                en => 'Labor Day',
                ru => 'Праздник труда',
              },
              days => [ qw( 0501 ) ],
            },
  '0509' => {
              name => {
                be => 'Дзень Перамогі',
                en => 'Victory Day',
                ru => 'День Победы',
              },
              days => [ qw( 0509 ) ],
            },
  '0703' => {
              name => {
                be => 'Дзень незалежнасці Рэспублікі Беларусь',
                en => 'Independence Day of the Republic of Belarus',
                ru => 'День Независимости Республики Беларусь',
              },
              days => {
                1991 => [ qw( 0727 ) ],
                1997 => [ qw( 0703 ) ],
              }
            },
  '1107' => {
              name => {
                be => 'Дзень Кастрычніцкай рэвалюцыі',
                en => 'October Revolution Day',
                ru => 'День Октябрьской революции',
              },
              days => [ qw( 1107 ) ],
            },
  '0107' => {
              name => {
                be => 'Раство Хрыстова (праваслаўнае Раство)',
                en => 'Christmas (Orthodox Christmas)',
                ru => 'Рождество Христово (православное Рождество)',
              },
              days => [ qw( 0107 ) ],
            },
  '1225' => {
              name => {
                be => 'Раство Хрыстова (каталіцкае Раство)',
                en => 'Christmas (Catholic Christmas)',
                ru => 'Рождество Христово (католическое Рождество)',
              },
              days => [ qw( 1225 ) ],
            },
  'rado' => {
              name => {
                be => 'Радаўніца',
                en => 'Radunica',
                ru => 'Радуница',
              },
              days => \&_radonitsa_mmdd,
            },
  'spec' => {
              name => {
                be => 'Перанос працоўнага дня',
                en => 'Postponed working day',
                ru => 'Перенос рабочего дня',
              },
              days => {
                # ... TODO
                1992 => [ qw( 0102 0106 0504 ) ],
                1993 => [ qw( 0726 ) ],
                1994 => [ qw( 0307 ) ],
                1995 => [ qw( 0728 1106 ) ],
                1996 => [ qw( 0422 0510 1108 ) ],
                1997 => [ qw( 0106 0505 0704 1226 ) ],
                1998 => [ qw( 0102 0427 ) ],
                1999 => [ qw( 0108 0419 ) ],
                2000 => [ qw( 0508 1106 ) ],
                2001 => [ qw( 0102 0309 0423 0430 0702 1224 1231 ) ],
                2002 => [ qw( 0102 0510 1108 ) ],
                2003 => [ qw( 0106 0505 ) ],
                2004 => [ qw( 0102 0105 0106 ) ],
                2005 => [ qw( 0307 ) ],
                2006 => [ qw( 0102 0508 1106 ) ],
                2007 => [ qw( 0102 0309 0416 0430 0702 1224 1231 ) ],
                2008 => [ qw( 0102 0505 0704 1226 ) ],
                2009 => [ qw( 0102 0427 ) ],
                2010 => [ qw( 0108 0412 0510 ) ],
                2011 => [ qw( 0307 0502 ) ],
                2012 => [ qw( 1224 1231 ) ],
                2013 => [ qw( 0102 0510 ) ],
                2014 => [ qw( 0102 0106 0430 0704 1226 ) ],
                2015 => [ qw( 0102 0420 ) ],
                2016 => [ qw( 0108 0307 ) ],
                2017 => [ qw( 0102 0424 0508 1106 ) ],
                2018 => [ qw( 0102 0309 0416 0430 0702 1224 1231 ) ],
                2019 => [ qw( 0506 0508 1108 ) ],
                2020 => [ qw( 0106 0427 ) ],
                2021 => [ qw( 0108 0510 ) ],
                2022 => [ qw( 0307 0502 ) ],
                2023 => [ qw( 0424 0508 1106 ) ],
                2024 => [ qw( 0513 1108 ) ],
                2025 => [ qw( 0106 0428 0704 1226 ) ],
                2026 => [ qw( 0420 ) ],
                2027 => [ qw( 0510 ) ],
              },
            },
},

BUSINESS_DAYS_ON_WEEKENDS => {
  'all'  => {
              name => {
                be => 'Працоўны дзень у выхадныя дні',
                en => 'Working day on weekends',
                ru => 'Рабочий день в выходные дни',
              },
              days => {
                # ... TODO
                1991 => [ qw( 1228 ) ],
                1992 => [ qw( 0104 0516 ) ],
                1993 => [ qw( 0724 ) ],
                1994 => [ qw( 0305 ) ],
                1995 => [ qw( 0805 1104 ) ],
                1996 => [ qw( 0420 0504 1116 ) ],
                1997 => [ qw( 0104 0503 0712 1220 ) ],
                1998 => [ qw( 0110 0425 ) ],
                1999 => [ qw( 0116 0417 ) ],
                2000 => [ qw( 0513 1111 ) ],
                2001 => [ qw( 0120 0303 0421 0428 0707 1222 1229 ) ],
                2002 => [ qw( 0105 0518 1116 ) ],
                2003 => [ qw( 0104 0503 ) ],
                2004 => [ qw( 0110 0117 0131 ) ],
                2005 => [ qw( 0312 ) ],
                2006 => [ qw( 0128 0506 1104 1230 ) ],
                2007 => [ qw( 0317 0414 0505 0707 1222 1229 ) ],
                2008 => [ qw( 0112 0503 0628 1220 ) ],
                2009 => [ qw( 0110 0425 ) ],
                2010 => [ qw( 0123 0417 0515 ) ],
                2011 => [ qw( 0312 0514 ) ],
                2012 => [ qw( 1222 1229 ) ],
                2013 => [ qw( 0105 0518 ) ],
                2014 => [ qw( 0104 0111 0503 0712 1220 ) ],
                2015 => [ qw( 0110 0425 ) ],
                2016 => [ qw( 0116 0305 ) ],
                2017 => [ qw( 0121 0429 0506 1104 ) ],
                2018 => [ qw( 0120 0303 0414 0428 0707 1222 1229 ) ],
                2019 => [ qw( 0504 0511 1116 ) ],
                2020 => [ qw( 0104 0404 ) ],
                2021 => [ qw( 0116 0515 ) ],
                2022 => [ qw( 0312 0514 ) ],
                2023 => [ qw( 0429 0513 1111 ) ],
                2024 => [ qw( 0518 1116 ) ],
                2025 => [ qw( 0111 0426 0712 1220 ) ],
                2026 => [ qw( 0425 ) ],
                2027 => [ qw( 0508 ) ],
              },
            },
},


SHORT_BUSINESS_DAYS => {
  'all'  => {
              name => {
                be => 'Перадсвяточны працоўны дзень',
                en => 'Pre-holiday working day',
                ru => 'Предпраздничный рабочий день',
              },
            },
},

};

sub _radonitsa_mmdd {
    my $year=$_[0];
    if ($year < 1583) {croak "Module has limitation in counting Easter before 1583";}
    # Radonitsa is the Tuesday of the second week after Orthodox Easter: Easter + 9 days.
    # Orthodox Easter is calculated by the Meeus algorithm in the Julian calendar,
    # all dates are counted as the day number from March 1 (1 = March 1, 32 = April 1, 62 = May 1, 93 = June 1).

    # Paschal full moon: its date is March 21 (Julian) + $d days ($d is 0..29, depends on the year in the 19-year lunar cycle).
    my $d = (19 * ($year % 19) + 15) % 30;

    # Days from the day after the full moon to the next Sunday ($e is 0..6, depends on the year in the 4-year leap cycle and 7-day week cycle).
    my $e = (2 * ($year % 4) + 4 * ($year % 7) - $d + 34) % 7;

    # Orthodox Easter in the Julian calendar: March 22 + $d + $e days,
    # i.e. day number 22 + $d + $e from March 1 (March 22 .. April 25, can be > 31 = April).
    my $julian_easter = 22 + $d + $e;

    # The Julian calendar is behind the Gregorian one: 13 days in 1900-2099, 14 in 2100-2199 and so on.
    my $gregorian_shift = int($year / 100) - int($year / 400) - 2;

    # Radonitsa in the Gregorian calendar as the day number from March 1
    # (Easter in Julian calendar + shift between calendars + 9 days).
    my $n = $julian_easter + $gregorian_shift + 9;

    # Day number from March 1 to month and day (March has 31 days, April 30, May 31).
    return [ $n <= 31 ? sprintf('03%02d', $n)
           : $n <= 61 ? sprintf('04%02d', $n - 31)
           : $n <= 92 ? sprintf('05%02d', $n - 61)
           :            sprintf('06%02d', $n - 92) ];
}


=head3 HOLIDAYS_VALID_SINCE

C<< $Date::Holidays::BY::ref->{'HOLIDAYS_VALID_SINCE'} >>

The module is only relevant from this year onward. Throws an exception (croak) for dates before this year.

=head3 INACCURATE_TIMES_BEFORE - INACCURATE_TIMES_SINCE

C<< $Date::Holidays::BY::ref->{'INACCURATE_TIMES_BEFORE'} >>

C<< $Date::Holidays::BY::ref->{'INACCURATE_TIMES_SINCE'} >>

The regular public holidays are defined for all years, but the exact postponements of days off are known only within this period. Outside it, in strict mode (C<$Date::Holidays::BY::strict=1>) an exception is thrown (croak).

=cut

$ref->{'INACCURATE_TIMES_BEFORE'} = (sort keys %{$ref->{'HOLIDAYS'}->{'spec'}->{'days'}})[0];
$ref->{'INACCURATE_TIMES_SINCE'} = (reverse sort keys %{$ref->{'HOLIDAYS'}->{'spec'}->{'days'}})[0] + 1;


=head2 $Date::Holidays::BY::strict

If true, throws an exception (croak) when the requested year is outside the period for which the data is defined.
Default is 0.

=cut

our $strict = 0;


=head2 $Date::Holidays::BY::lang

The language is determined from the locale in C<$ENV{LC_ALL}>, C<$ENV{LC_MESSAGES}> or C<$ENV{LANG}> (in this order of priority). You can override it after loading the module.

=cut

my $envlang = lc substr(( $ENV{LC_ALL} || $ENV{LC_MESSAGES} || $ENV{LANG} || '' ), 0, 2);
$envlang = (List::Util::first {/^\Q$envlang\E$/} qw(be en ru)) || 'en';
our $lang = $lang || $envlang;


=head1 FUNCTIONS

=head2 holidays( $year )

Returns a hash reference of all holidays in the year.

    {
      MMDD => 'name',
      ...
    }

The result is cached for the selected language and year in C<$Date::Holidays::BY::ref-E<gt>{'cache'}>.

The returned hash reference is the cache itself, not a copy. Changes made to it (for example, adding your own days) are visible to C<is_holiday()> and C<is_business_day()> until the cache is cleared (see L</I18N>).

Throws an exception (croak) if the year is not valid.

=cut

sub holidays {
    my $year = shift or croak 'Bad year';

    return $ref->{'cache'}->{'HOLIDAYS'}->{$lang}->{$year}  if $ref->{'cache'}->{'HOLIDAYS'}->{$lang}->{$year};

    croak "BY holidays is not valid before $ref->{'HOLIDAYS_VALID_SINCE'}"  if $year < $ref->{'HOLIDAYS_VALID_SINCE'};
    if ($strict && ($year < $ref->{'INACCURATE_TIMES_BEFORE'} || $year >= $ref->{'INACCURATE_TIMES_SINCE'} )) {
        croak "BY holidays are not valid outside the period @{[ $ref->{'INACCURATE_TIMES_BEFORE'} ]}-@{[ $ref->{'INACCURATE_TIMES_SINCE'} - 1 ]}";
    }

    for my $key (keys %{$ref->{'HOLIDAYS'}}) {

        my $name = _resolve_yhash_value( $ref->{'HOLIDAYS'}->{$key}->{'name'}, $year )->{$lang} || croak "Name is not defined";

        # postponed days are defined only for the exact years, unlike periodic holidays
        my $mds;
        if ($key eq 'spec') {
            $mds = $ref->{'HOLIDAYS'}->{$key}->{'days'}->{$year} || [];
        } else {
            $mds = _resolve_yhash_value( $ref->{'HOLIDAYS'}->{$key}->{'days'}, $year );
        }

        for my $md (@{$mds}) {
            $ref->{'cache'}->{'HOLIDAYS'}->{$lang}->{$year}->{$md} = $name;
        }

    }

    return $ref->{'cache'}->{'HOLIDAYS'}->{$lang}->{$year};
}

sub _resolve_yhash_value {
    my ($value, $year) = @_;
    return $value->($year)  if ref $value eq 'CODE';
    return $value  if ref $value ne 'HASH';
    my @keys = keys %{$value};
    return $value  if $keys[0] !~ /^\d\d\d\d$/;
    my $ykey = List::Util::first { $year >= $_ } reverse sort @keys;
    return [] if !$ykey;
    return $value->{$ykey}->($year)  if ref $value->{$ykey} eq 'CODE';
    return $value->{$ykey};
}


=head2 is_holiday( $year, $month, $day )

Determines whether the date is a public holiday in Belarus. Returns the holiday name or undef.

Throws an exception (croak) if the date is invalid.

=cut

sub is_holiday {
    my ( $year, $month, $day ) = @_;
    croak 'Bad params'  unless $year && $month && $day;
    _check_date( $year, $month, $day );

    return holidays( $year )->{ _get_date_key($month, $day) };
}


=head2 is_by_holiday( $year, $month, $day )

Alias for is_holiday().

=cut

sub is_by_holiday {
    goto &is_holiday;
}


=head2 is_business_day( $year, $month, $day )

Returns true if the date is a business day in Belarus, taking holidays, weekends and working days on weekends into account.

Throws an exception (croak) if the date is invalid.

=cut

sub is_business_day {
    my ( $year, $month, $day ) = @_;
    croak 'Bad params'  unless $year && $month && $day;
    _check_date( $year, $month, $day );

    return 0  if is_holiday( $year, $month, $day );

    # check if date is a weekend
    my $wday = _day_of_week( $year, $month, $day );
    return 1  unless $wday == 0 || $wday == 6;

    # check if date is a business day on weekend
    # working days on weekends are defined only for the exact years
    for my $md (@{$ref->{'BUSINESS_DAYS_ON_WEEKENDS'}->{'all'}->{'days'}->{$year} || []}) {
        if ($md eq _get_date_key($month, $day)) {return 1;}
    }

    return 0;
}


=head2 short_business_days( $year )

Returns hash ref of all shortened business days in the year.

    {
      MMDD => 'name',
      ...
    }

A shortened business day is a business day immediately preceding a public holiday (Labor Code of the Republic of Belarus, art. 116), its length is reduced by one hour. The days are calculated by this rule.

The result is cached in C<$Date::Holidays::BY::ref-E<gt>{'cache'}> like in C<holidays()>.

=cut

sub short_business_days {
    my $year = shift or croak 'Bad year';

    return $ref->{'cache'}->{'SHORT_BUSINESS_DAYS'}->{$lang}->{$year}  if $ref->{'cache'}->{'SHORT_BUSINESS_DAYS'}->{$lang}->{$year};

    croak "BY holidays is not valid before $ref->{'HOLIDAYS_VALID_SINCE'}"  if $year < $ref->{'HOLIDAYS_VALID_SINCE'};

    my $mds = _calc_short_business_days( $year );
    my $name = $ref->{'SHORT_BUSINESS_DAYS'}->{'all'}->{'name'}->{$lang} || croak "Name is not defined";

    return $ref->{'cache'}->{'SHORT_BUSINESS_DAYS'}->{$lang}->{$year} = { map { $_ => $name } @{$mds} };
}

# Business days immediately preceding a public holiday (without postponed days).
sub _calc_short_business_days {
    my $year = shift;

    my %holiday;
    for my $y ( $year, $year + 1 ) {
        for my $key ( grep { $_ ne 'spec' } keys %{$ref->{'HOLIDAYS'}} ) {
            $holiday{$y . $_} = 1  for @{_resolve_yhash_value( $ref->{'HOLIDAYS'}->{$key}->{'days'}, $y )};
        }
    }

    my @mds;
    for my $date ( keys %holiday ) {
        my ( $y, $m, $d ) = unpack 'A4 A2 A2', $date;
        # the day before the holiday, for January 1 it is December 31 of the previous year
        if ( $d > 1 ) {
            $d--;
        } elsif ( $m > 1 ) {
            $m--;
            $d = _days_in_month( $y, $m );
        } else {
            $y--;
            $m = 12;
            $d = 31;
        }
        next  unless $y == $year && is_business_day( $year, $m, $d );
        push @mds, _get_date_key( $m, $d );
    }
    @mds = sort @mds;

    return \@mds;
}


=head2 is_short_business_day( $year, $month, $day )

Returns true if date is a shortened business day. See C<short_business_days()>.

Throws an exception (croak) if the date is invalid.

=cut

sub is_short_business_day {
    my ( $year, $month, $day ) = @_;
    croak 'Bad params'  unless $year && $month && $day;
    _check_date( $year, $month, $day );

    return short_business_days( $year )->{ _get_date_key($month, $day) } ? 1 : 0;
}


sub _days_in_month {
    my ( $year, $month ) = @_;
    my @mdays = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    return 29  if $month == 2 && $year % 4 == 0 && ( $year % 100 != 0 || $year % 400 == 0 );
    return $mdays[ $month - 1 ];
}


sub _check_date {
    my ( $year, $month, $day ) = @_;
    croak "Bad date: $year-$month-$day"
        unless $year =~ /^\d+$/ && $month =~ /^\d+$/ && $day =~ /^\d+$/
            && $month >= 1 && $month <= 12 && $day >= 1;
    croak "Bad date: $year-$month-$day"  if $day > _days_in_month( $year, $month );
    return;
}


# Day of the week Sakamoto's algorithm: 0 = Sunday, ..., 6 = Saturday (Gregorian calendar).
sub _day_of_week {
    my ( $year, $month, $day ) = @_;
    my @shift = ( 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 );
    $year--  if $month < 3;
    return ( $year + int( $year / 4 ) - int( $year / 100 ) + int( $year / 400 ) + $shift[ $month - 1 ] + $day ) % 7;
}


sub _get_date_key {
    my ($month, $day) = @_;
    return sprintf '%02d%02d', $month, $day;
}


=head1 I18N

Translations are available in Belarusian (be), English (en), and Russian (ru), with the language selected from the locale in C<$ENV{LC_ALL}>, C<$ENV{LC_MESSAGES}> or C<$ENV{LANG}> (in this order of priority). If the locale is not one of these, "en" is used. See C<$Date::Holidays::BY::lang>.

Holiday names can be redefined in C<$Date::Holidays::BY::ref>:

    use Date::Holidays::BY;

    $Date::Holidays::BY::ref->{'HOLIDAYS'}->{'0308'}->{'name'}->{'en'} = 'name1';

    say Date::Holidays::BY::holidays(2024)->{'0308'}; # name1

    $Date::Holidays::BY::ref->{'HOLIDAYS'}->{'0308'}->{'name'}->{'en'} = 'name2';
    $Date::Holidays::BY::ref->{'cache'} = undef;

    say Date::Holidays::BY::holidays(2024)->{'0308'}; # name2

=cut

=head1 LICENSE

This software is copyright (c) 2026 by Vladimir Varlamov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or
b) the "Artistic License"

=cut


=head1 AUTHOR

Vladimir Varlamov, C<< <bes.internal@gmail.com> >>

=cut



1;
