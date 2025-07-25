package Date::Holidays::BY;
our $VERSION = '2.2026.0'; # VERSION

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
        print "2012-03-11 is business day on weekend\n";
    }

    if ( Date::Holidays::BY::is_short_business_day( 2015, 04, 30 ) ) {
        print "2015-04-30 is short business day\n";
    }

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
#require Date::Easter;
#require Time::Piece;

our @EXPORT_OK = qw(
    is_holiday
    is_by_holiday
    holidays
    is_business_day
    is_short_business_day
);


=head1 CONFIGURATION VARIABLES

=head2 $Date::Holidays::BY::ref

Hash reference containing all static holiday data, including holiday names for i18n support.
Dates are formatted as MMDD (ISO 8601).

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
                2013 => [ qw( 0102 0510 ) ],
                2014 => [ qw( 0102 0106 0430 0704 1226 ) ],
                2015 => [ qw( 0102 0420 ) ],
                2016 => [ qw( 0108 0307 ) ],
                2017 => [ qw( 0102 0424 0425 0508 1106 ) ],
                2018 => [ qw( 0102 0309 0416 0417 0430 0702 1224 1231 ) ],
                2019 => [ qw( 0506 0507 0508 1108 ) ],
                2020 => [ qw( 0106 0427 0428 ) ],
                2021 => [ qw( 0108 0510 0511 ) ],
                2022 => [ qw( 0307 0502 ) ],
                2023 => [ qw( 0424 0508 1106 ) ],
                2024 => [ qw( 0513 1108 ) ],
                2025 => [ qw( 0106 0428 0704 1226 ) ],
                2026 => [ qw( 0420 ) ],
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
              days => {
                # ... TODO
                2014 => [ qw( 0428 0508 0702 1106  1224 1231 ) ],
                2015 => [ qw( 0106 0430 0508 0702 1106  1224 ) ],
                2016 => [ qw( 0106 ) ],
                2017 => [ qw( 0106 0307 0429 0506 1104 ) ],
                2018 => [ qw( 0307 0508 1106 ) ],
                2019 => [ qw( 0307 0430 0506 0702 1106 1224 ) ],
                # ... TODO
              },
            },
},

};

sub _radonitsa_mmdd {
    my $year=$_[0];
    if ($year < 1583) {croak "Module has limitation in counting Easter outside the period 1583-7666";}
    if ($year >= 2038 && "$]" < 5.012 && (eval{require Config; $Config::Config{ivsize}} < 8)) {croak "Require perl>=5.12.0 because 2038 problem";}
    require Date::Easter;
    my ($easter_month, $easter_day) = Date::Easter::orthodox_easter($year);
    require Time::Piece;
    return [ (Time::Piece->strptime("$year-$easter_month-$easter_day", '%Y-%m-%d') + 9*3600*24)->strftime('%m%d') ];
}


=head3 HOLIDAYS_VALID_SINCE

C<< $Date::Holidays::BY::ref->{'HOLIDAYS_VALID_SINCE'} >>

The module is only relevant from this year onward. Throws an exception (croak) for dates before this year.

=head3 INACCURATE_TIMES_BEFORE - INACCURATE_TIMES_SINCE

C<< $Date::Holidays::BY::ref->{'INACCURATE_TIMES_BEFORE'} >>

C<< $Date::Holidays::BY::ref->{'INACCURATE_TIMES_SINCE'} >>

Outside this period, postponement of a holidays are not specified and in the strict mode C<$Date::Holidays::BY::strict=1> throws an exception (croak). But you can be sure of the periodic holidays.

=cut

$ref->{'INACCURATE_TIMES_BEFORE'} = (sort keys %{$ref->{'HOLIDAYS'}->{'spec'}->{'days'}})[0];
$ref->{'INACCURATE_TIMES_SINCE'} = (reverse sort keys %{$ref->{'HOLIDAYS'}->{'spec'}->{'days'}})[0] + 1;


=head2 $Date::Holidays::BY::strict

Allows you to throws an exception (croak) if the requested date is outside the determined times.
Default is 0.

=cut

our $strict = 0;


=head2 $Date::Holidays::BY::lang

The language is determined by the locale from C<$ENV{LANG}>. Allows you to override this language after loading the module.

=cut

my $envlang = lc substr(( $ENV{LANG} || $ENV{LC_ALL} || $ENV{LC_MESSAGES} || '' ), 0, 2);
$envlang = (List::Util::first {/^\Q$envlang\E$/} qw(be en ru)) || 'en';
our $lang = $lang || $envlang;


=head2 $Date::Holidays::BY::HOLIDAYS_VALID_SINCE

Deprecated. See C<< $Date::Holidays::BY::ref->{'HOLIDAYS_VALID_SINCE'} >>

=cut

our $HOLIDAYS_VALID_SINCE = $ref->{'HOLIDAYS_VALID_SINCE'};


=head2 $Date::Holidays::BY::INACCURATE_TIMES_SINCE

Deprecated. See C<< $Date::Holidays::BY::ref->{'INACCURATE_TIMES_BEFORE'} >> and C<< $Date::Holidays::BY::ref->{'INACCURATE_TIMES_SINCE'} >>

=cut

our $INACCURATE_TIMES_SINCE = $ref->{'INACCURATE_TIMES_SINCE'};



=head1 FUNCTIONS

=head2 holidays( $year )

Returns hash ref of all holidays in the year.

    {
      MMDD => 'name',
      ...
    }

Сaches the result for the selected language for the specified year in a variable C<$Date::Holidays::ref-E<gt>{'cache'}>

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

        for my $md (@{_resolve_yhash_value( $ref->{'HOLIDAYS'}->{$key}->{'days'}, $year )}) {
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

Determine whether this date is a BY holiday. Returns holiday name or undef.

=cut

sub is_holiday {
    my ( $year, $month, $day ) = @_;
    croak 'Bad params'  unless $year && $month && $day;

    return holidays( $year )->{ _get_date_key($month, $day) };
}


=head2 is_by_holiday( $year, $month, $day )

Alias for is_holiday().

=cut

sub is_by_holiday {
    goto &is_holiday;
}


=head2 is_business_day( $year, $month, $day )

Returns true if date is a business day in BY taking holidays and weekends into account.

=cut

sub is_business_day {
    my ( $year, $month, $day ) = @_;
    croak 'Bad params'  unless $year && $month && $day;

    return 0  if is_holiday( $year, $month, $day );

    # check if date is a weekend
    require Time::Piece;
    my $t = Time::Piece->strptime( "$year-$month-$day", '%Y-%m-%d' );
    my $wday = $t->day;
    return 1  unless $wday eq 'Sat' || $wday eq 'Sun';

    # check if date is a business day on weekend
    for my $md (@{_resolve_yhash_value($ref->{'BUSINESS_DAYS_ON_WEEKENDS'}->{'all'}->{'days'}, $year)}) {
        if ($md eq _get_date_key($month, $day)) {return 1;}
    }

    return 0;
}


=head2 is_short_business_day( $year, $month, $day )

Returns true if date is a shortened business day.

=cut

sub is_short_business_day {
    my ( $year, $month, $day ) = @_;

    for my $md (@{_resolve_yhash_value($ref->{'SHORT_BUSINESS_DAYS'}->{'all'}->{'days'}, $year)}) {
        if ($md eq _get_date_key($month, $day)) {return 1;}
    }

    return 0;
}


sub _get_date_key {
    my ($month, $day) = @_;
    return sprintf '%02d%02d', $month, $day;
}


=head1 I18N

Translations are available in Belarusian (be), English (en), and Russian (ru), with the language selected based on the locale from C<$ENV{LANG}>. If not mapped, "en" is used by default. See C<$Date::Holidays::BY::lang>.

The module supports localization of holiday names, which can be redefined if needed in C<$Date::Holidays::BY::ref>:

    use Date::Holidays::BY;

    $Date::Holidays::BY::ref->{'HOLIDAYS'}->{'0308'}->{'name'}->{'en'} = 'name1';

    say Date::Holidays::BY::holidays(2024)->{'0308'}; # name1

    $Date::Holidays::BY::ref->{'HOLIDAYS'}->{'0308'}->{'name'}->{'en'} = 'name2';
    $Date::Holidays::BY::ref->{'cache'} = undef;

    say Date::Holidays::BY::holidays(2024)->{'0308'}; # name2

=cut

=head1 LICENSE

This software is copyright (c) 2025 by Vladimir Varlamov.

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
