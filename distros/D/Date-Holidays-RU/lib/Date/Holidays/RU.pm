package Date::Holidays::RU;
$Date::Holidays::RU::VERSION = '1.2024.0';
# ABSTRACT: Determine Russian Federation official holidays and business days.


use warnings;
use strict;
use utf8;
use base 'Exporter';

our @EXPORT_OK = qw(
    is_holiday
    is_ru_holiday
    holidays
    is_business_day
    is_short_business_day
);

use Carp;
use Time::Piece;
use List::Util qw/ first /;


my $HOLIDAYS_VALID_SINCE = 1991;
#my $BUSINESS_DAYS_VALID_SINCE = 2004;

# sources:
#   http://www.consultant.ru/law/ref/calendar/proizvodstvennye/
#   http://ru.wikipedia.org/wiki/История_праздников_России
#   http://www.consultant.ru/popular/kzot/54_6.html#p530
#   http://www.consultant.ru/document/cons_doc_LAW_127924/?frame=17#p1681

my @REGULAR_HOLIDAYS = (
    {
        name => {
            1948 => 'Новый год',
            2005 => 'Новогодние каникулы',
        },
        days => {
            1948 => '0101',
            1992 => [ qw( 0101 0102 ) ],
            2005 => [ qw( 0101 0102 0103 0104 0105 ) ],
            2013 => [ qw( 0101 0102 0103 0104 0105 0106 0108 ) ],
        },
    },
    {
        name => 'Рождество Христово',
        days => {
            1991 => '0107', # maybe 1992
        },
    },
    {
        name => 'День защитника Отечества',
        days => {
            2002 => '0223',
        },
    },
    {
        name => 'Международный женский день',
        days => {
            1966 => '0308',
        }
    },
    {
        name => {
            1965 => 'День международной солидарности трудящихся',
            1992 => 'Праздник Весны и Труда',
        },
        days => {
            1965 => [ qw( 0501 0502 ) ],
            2005 => '0501',
        },
    },
    {
        name => 'День Победы',
        days => {
            1965 => '0509',
        },
    },
    {
        name => {
            1992 => 'День принятия декларации о государственном суверенитете Российской Федерации',
            2002 => 'День России',
        },
        days => {
            1992 => '0612',
        },
    },
    {
        name => 'День народного единства',
        days => {
            2005 => '1104',
        },
    },
    {
        name => {
            1965 => 'Годовщина Великой Октябрьской социалистической революции',
            1996 => 'День согласия и примирения',
        },
        days => {
            1928 => [ qw( 1107 1108 ) ],
            1992 => '1107',
            2005 => undef,
        },
    },
    {
        name => 'День Конституции Российской Федерации',
        days => {
            1994 => '1212',
            2005 => undef,
        },
    },
);

my %HOLIDAYS_SPECIAL = (
    2004 => [ qw( 0503 0504 0510 0614 1108 1213 ) ],
    2005 => [ qw( 0106 0110 0307 0502 0613 ) ],
    2006 => [ qw( 0106 0109 0224 0508 1106 ) ],
    2007 => [ qw( 0108 0430 0611 1105 1231 ) ],
    2008 => [ qw( 0108 0225 0310 0502 0613 1103 ) ],
    2009 => [ qw( 0106 0108 0109 0309 0511 ) ],
    2010 => [ qw( 0106 0108 0222 0503 0510 0614 1105 ) ],
    2011 => [ qw( 0106 0110 0307 0502 0613 ) ],
    2012 => [ qw( 0106 0109 0309 0430 0507 0508 0611 1105 1231 ) ],
    2013 => [ qw( 0502 0503 0510 ) ],
    2014 => [ qw( 0310 0502 0613 1103 ) ],
    2015 => [ qw( 0109 0309 0504 0511 ) ],
    2016 => [ qw( 0222 0307 0502 0503 0613 ) ],
    2017 => [ qw( 0224 0508 1106 ) ],
    2018 => [ qw( 0309 0430 0502 0611 1105 1231 ) ],
    2019 => [ qw( 0502 0503 0510 ) ],
    2020 => [ qw( 0224 0309 0504 0505 ) ],
    2021 => [ qw( 0222 0503 0510 0614 1105 1231 ) ],
    2022 => [ qw( 0307 0503 0510 0613 ) ],
    2023 => [ qw( 0224 0508 1106 ) ],
    2024 => [ qw( 0429 0430 0510 1230 1231 ) ],
);

my %BUSINESS_DAYS_ON_WEEKENDS = (
    2005 => [ qw( 0305 ) ],
    2006 => [ qw( 0226 0506 ) ],
    2007 => [ qw( 0428 0609 1229 ) ],
    2008 => [ qw( 0504 0607 1101 ) ],
    2009 => [ qw( 0111 ) ],
    2010 => [ qw( 0227 1113 ) ],
    2011 => [ qw( 0305 ) ],
    2012 => [ qw( 0311 0428 0505 0512 0609 1229 ) ],
    2016 => [ qw( 0220 ) ],
    2018 => [ qw( 0428 0609 1229 ) ],
    2021 => [ qw( 0220 ) ],
    2022 => [ qw( 0305 ) ],
    2024 => [ qw( 0427 1102 1228 ) ],
);

my %SHORT_BUSINESS_DAYS = (
    2004 => [ qw( 0106 0430 0611 1231 ) ],
    2005 => [ qw( 0222 0305 1103 ) ],
    2006 => [ qw( 0222 0307 0506 1103 ) ],
    2007 => [ qw( 0222 0307 0428 0508 0609 ) ],
    2008 => [ qw( 0222 0307 0430 0508 0611 1101 1231 ) ],
    2009 => [ qw( 0430 0508 0611 1103 1231 ) ],
    2010 => [ qw( 0227 0430 0611 1103 1231 ) ],
    2011 => [ qw( 0222 0305 1103 ) ],
    2012 => [ qw( 0222 0307 0428 0512 0609 1229 ) ],
    2013 => [ qw( 0222 0307 0430 0508 0611 1231 ) ],
    2014 => [ qw( 0224 0307 0430 0508 0611 1231 ) ],
    2015 => [ qw( 0430 0508 0611 1103 1231 ) ],
    2016 => [ qw( 0220 1103 ) ],
    2017 => [ qw( 0222 0307 1103 ) ],
    2018 => [ qw( 0222 0307 0428 0508 0609 1229 ) ],
    2019 => [ qw( 0222 0307 0430 0508 0611 1231 ) ],
    2020 => [ qw( 0430 0508 0611 1103 1231 ) ],
    2021 => [ qw( 0220 0430 0611 1103 ) ],
    2022 => [ qw( 0222 0305 1103 ) ],
    2023 => [ qw( 0222 0307 1103 ) ],
    2024 => [ qw( 0222 0307 0508 0611 1102 ) ],
);



sub is_holiday {
    my ( $year, $month, $day ) = @_;

    croak 'Bad params'  unless $year && $month && $day;

    return holidays( $year )->{ _get_date_key($month, $day) };
}


sub is_ru_holiday {
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
    croak "RU holidays is not valid before $HOLIDAYS_VALID_SINCE"  if $year < $HOLIDAYS_VALID_SINCE;

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

Date::Holidays::RU - Determine Russian Federation official holidays and business days.

=head1 VERSION

version 1.2024.0

=head1 SYNOPSIS

    use Date::Holidays::RU qw( is_holiday holidays is_business_day );

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

Determine whether this date is a RU holiday. Returns holiday name or undef.

=head2 is_ru_holiday( $year, $month, $day )

Alias for is_holiday().

=head2 holidays( $year )

Returns hash ref of all RU holidays in the year.

=head2 is_business_day( $year, $month, $day )

Returns true if date is a business day in RU taking holidays and weekends into account.

=head2 is_short_business_day( $year, $month, $day )

Returns true if date is a shortened business day in RU.

=head1 NAME

Date::Holidays::RU

=head1 VERSION

version 1.2024.0

=head1 AUTHOR

Alexander Nalobin, C<< <alexander at nalobin.ru> >>
Aleksey Korabelshchikov, C<< <liosha at cpan.org> >>

=head1 AUTHOR

Alexander Nalobin <alexander@nalobin.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Alexander Nalobin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
