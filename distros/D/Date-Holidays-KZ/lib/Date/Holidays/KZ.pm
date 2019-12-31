package Date::Holidays::KZ;
our $VERSION = '0.2020.0'; # VERSION

=encoding utf8

=head1 NAME

Date::Holidays::KZ - Determine Kazakhstan official holidays and business days.

=head1 SYNOPSIS

    use Date::Holidays::KZ qw( is_holiday holidays is_business_day );

    my ( $year, $month, $day ) = ( localtime )[ 5, 4, 3 ];
    $year  += 1900;
    $month += 1;

    if ( my $holidayname = is_holiday( $year, $month, $day ) ) {
        print "Today is a holiday: $holidayname\n";
    }

    my $ref = holidays( $year );
    while ( my ( $md, $name ) = each %$ref ) {
        print "On $md there is a holiday named $name\n";
    }

    if ( is_business_day( 2012, 03, 11 ) ) {
        print "2012-03-11 is business day on weekend\n";
    }

    if ( is_short_business_day( 2015, 04, 30 ) ) {
        print "2015-04-30 is short business day\n";
    }

    $Date::Holidays::KZ::strict=1;
    # here we die because time outside from $HOLIDAYS_VALID_SINCE to $INACCURATE_TIMES_SINCE
    holidays( 9001 );

=cut

use warnings;
use strict;
use utf8;
use base 'Exporter';

our @EXPORT_OK = qw(
    is_holiday
    is_kz_holiday
    holidays
    is_business_day
    is_short_business_day
);

=head2 $Date::Holidays::KZ::HOLIDAYS_VALID_SINCE, $Date::Holidays::KZ::INACCURATE_TIMES_SINCE

HOLIDAYS_VALID_SINCE before this year package doesn't matter
INACCURATE_TIMES_SINCE after this year dates of holidays and working day shift are not accurate, but you can most likely be sure of historical holidays

=cut

our $HOLIDAYS_VALID_SINCE = 2017; # TODO add all old
our $INACCURATE_TIMES_SINCE = 2021;


=head2 $Date::Holidays::KZ::strict

Allows you to return an error if the requested date is outside the determined times.
Default is 0.

=cut

our $strict = 0;

use Carp;
use Time::Piece;
use List::Util qw/ first /;

# internal date formatting alike ISO 8601: MMDD
my @REGULAR_HOLIDAYS = (
    {
        name => 'Новый год',
                days => [ qw( 0101 0102 ) ],
    },
    {
        name => 'Православное рождество',
        days => '0107',
    },
    {
        name => 'Международный женский день',
        days => '0308',
    },
    {
        name => 'Наурыз мейрамы',
        days => [ qw( 0321 0322 0323 ) ],
    },
    {
        name => 'Праздник единства народа Казахстана',
        days => '0501',
    },
    {
        name => 'День защитника Отечества',
        days => '0507',
    },
    {
        name => 'День Победы',
        days => '0509',
    },
    {
        name => 'День Столицы',
        days => '0706',
    },
    {
        name => 'День Конституции Республики Казахстан',
        days => '0830',
    },
    {
        name => 'День Первого Президента Республики Казахстан',
        days => '1201',
    },
    {
        name => 'День Независимости',
        days => [ qw( 1216 1217 ) ],
    },
    # Курбан-айта goes to HOLIDAYS_SPECIAL because based on the muslim calendar
);

my %HOLIDAYS_SPECIAL = (
    2017 => [ qw( 0103 0320 0508 0707 0901 1218 1219 ) ],
    2018 => [ qw( 0821 0309 0508 0430 0831 1203 1218 1231 ) ],
    2019 => [ qw( 0325 0510 0708 1202 0811 ) ],
    2020 => [ qw( 0103 0309 0324 0325 0508 0831 1218 ) ],
);


my %BUSINESS_DAYS_ON_WEEKENDS = (
    2017 => [ qw( 0318 0701 ) ],
    2018 => [ qw( 0303 0505 0825 1229 ) ],
    2019 => [ qw( 0504 ) ],
    2020 => [ qw( 0105 1220 ) ],
);

my %SHORT_BUSINESS_DAYS = (
);

=head2 is_holiday( $year, $month, $day )

Determine whether this date is a KZ holiday. Returns holiday name or undef.

=cut

sub is_holiday {
    my ( $year, $month, $day ) = @_;
    croak 'Bad params'  unless $year && $month && $day;

    return holidays( $year )->{ _get_date_key($month, $day) };
}

=head2 is_kz_holiday( $year, $month, $day )

Alias for is_holiday().

=cut

sub is_kz_holiday {
    goto &is_holiday;
}

=head2 holidays( $year )

Returns hash ref of all KZ holidays in the year.

=cut

my %cache;
sub holidays {
    my $year = shift or croak 'Bad year';

    return $cache{ $year }  if $cache{ $year };

    my $holidays = _get_regular_holidays_by_year($year);

    if ( my $spec = $HOLIDAYS_SPECIAL{ $year } ) {
        $holidays->{ $_ } = 'Перенос праздничного дня'  for @$spec;
    }

    return $cache{ $year } = $holidays;
}

sub _get_regular_holidays_by_year {
    my ($year) = @_;
    croak "KZ holidays is not valid before $HOLIDAYS_VALID_SINCE"  if $year < $HOLIDAYS_VALID_SINCE;
    if ($strict) {
		croak "KZ holidays is not valid after @{[ $INACCURATE_TIMES_SINCE - 1 ]}"  if $year >= $INACCURATE_TIMES_SINCE;
    }

    my %day;
    for my $holiday (@REGULAR_HOLIDAYS) {
        my $days = _resolve_yhash_value($holiday->{days}, $year);
        next  if !$days;
        $days = [$days]  if !ref $days;
        next  if !@$days;

        my $name = _resolve_yhash_value($holiday->{name}, $year);
        croak "Name is not defined"  if !$name; # assertion

        $day{$_} = $name  for @$days;
    }

    return \%day;
}

sub _resolve_yhash_value {
    my ($value, $year) = @_;
    return $value  if ref $value ne 'HASH';

    my $ykey = first {$year >= $_} reverse sort keys %$value;
    return  if !$ykey;
    return $value->{$ykey};
}


=head2 is_business_day( $year, $month, $day )

Returns true if date is a business day in KZ taking holidays and weekends into account.

=cut

sub is_business_day {
    my ( $year, $month, $day ) = @_;

    croak 'Bad params'  unless $year && $month && $day;

    return 0  if is_holiday( $year, $month, $day );

    # check if date is a weekend
    my $t = Time::Piece->strptime( "$year-$month-$day", '%Y-%m-%d' );
    my $wday = $t->day;
    return 1  unless $wday eq 'Sat' || $wday eq 'Sun';

    # check if date is a business day on weekend
    my $ref = $BUSINESS_DAYS_ON_WEEKENDS{ $year } or return 0;

    my $md = _get_date_key($month, $day);
    for ( @$ref ) {
        return 1  if $_ eq $md;
    }

    return 0;
}

=head2 is_short_business_day( $year, $month, $day )

Returns true if date is a shortened business day in KZ.

=cut

sub is_short_business_day {
    my ( $year, $month, $day ) = @_;

    my $short_days_ref = $SHORT_BUSINESS_DAYS{ $year } or return 0;

    my $date_key = _get_date_key($month, $day);
    return !!grep { $_ eq $date_key } @$short_days_ref;
}


sub _get_date_key {
    my ($month, $day) = @_;
    return sprintf '%02d%02d', $month, $day;
}

=head1 LICENSE

This software is copyright (c) 2019 by Vladimir Varlamov.

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
