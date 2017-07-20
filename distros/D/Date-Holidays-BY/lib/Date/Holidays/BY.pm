package Date::Holidays::BY;
$Date::Holidays::BY::VERSION = '0.2017.2';
# ABSTRACT: Determine Belorussian official holidays and business days.


use warnings;
use strict;
use utf8;
use base 'Exporter';

our @EXPORT_OK = qw(
    is_holiday
    is_by_holiday
    holidays
    is_business_day
    is_short_business_day
);

use Carp;
use Time::Piece;
use List::Util qw/ first /;


my $HOLIDAYS_VALID_SINCE = 2017; # TODO
my $BUSINESS_DAYS_VALID_SINCE = 2017;

# sources:
#   https://ru.wikipedia.org/wiki/Праздники_Белоруссии

my @REGULAR_HOLIDAYS = (
    {
        name => 'Новый год',
		days => '0101',
    },
    {
        name => 'Международный женский день',
        days => '0308',
    },
    {
        name => 'Праздник труда',
        days => '0501',
    },
    {
        name => 'День Победы',
        days => '0509',
    },
    {
        name => 'День Независимости Республики Беларусь',
        days => '0703',
    },
    {
        name => 'День Октябрьской революции',
        days => '1107',
    },
    {
        name => 'Рождество Христово (православное Рождество)',
        days => '0107',
    },
    {
        name => 'Рождество Христово (католическое Рождество)',
        days => '1225',
    },
);


my %HOLIDAYS_SPECIAL = (
    2017 => [ qw( 0102 0424 0425 0508 1106 ) ],
    2018 => [ qw( 0417 ) ],
);


my %BUSINESS_DAYS_ON_WEEKENDS = (
    2017 => [ qw( 0121 0429 0506 1104 ) ],
);

my %SHORT_BUSINESS_DAYS = (
    2017 => [ qw( 0106 0307 0429 0506 1104 ) ],
    2018 => [ qw( 0307 0416 0430 0508 0602 1106 1224 1231 ) ],
);



sub is_holiday {
    my ( $year, $month, $day ) = @_;

    croak 'Bad params'  unless $year && $month && $day;

    return holidays( $year )->{ _get_date_key($month, $day) };
}


sub is_by_holiday {
    goto &is_holiday;
}


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
    croak "BY holidays is not valid before $HOLIDAYS_VALID_SINCE"  if $year < $HOLIDAYS_VALID_SINCE;

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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Holidays::BY - Determine Belorussian official holidays and business days.

=head1 VERSION

version 0.2017.2

=head1 SYNOPSIS

    use Date::Holidays::BY qw( is_holiday holidays is_business_day );

    binmode STDOUT, ':encoding(UTF-8)';
   
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

=head2 is_holiday( $year, $month, $day )

Determine whether this date is a BY holiday. Returns holiday name or undef.

=head2 is_by_holiday( $year, $month, $day )

Alias for is_holiday().

=head2 holidays( $year )

Returns hash ref of all BY holidays in the year.

=head2 is_business_day( $year, $month, $day )

Returns true if date is a business day in BY taking holidays and weekends into account.

=head2 is_short_business_day( $year, $month, $day )

Returns true if date is a shortened business day in BY.

=head1 NAME

Date::Holidays::BY

=head1 VERSION

version 0.2017.2

=head1 AUTHOR

Vladimir Varlamov, C<< <bes.internal@gmail.com> >>

=head1 AUTHOR

Vladimir Varlamov <bes.internal@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vladimir Varlamov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
