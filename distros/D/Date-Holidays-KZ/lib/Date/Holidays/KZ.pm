package Date::Holidays::KZ;
$Date::Holidays::KZ::VERSION = '0.2018.0';
# ABSTRACT: Determine Kazakhstan official holidays and business days.


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

use Carp;
use Time::Piece;
use List::Util qw/ first /;


my $HOLIDAYS_VALID_SINCE = 2018; # TODO
my $BUSINESS_DAYS_VALID_SINCE = 2018;

# sources:
# https://ru.wikipedia.org/wiki/Праздники_Казахстана
# https://online.zakon.kz/Document/?doc_id=33843977#pos=25;-101&sdoc_params=text%3D%25D0%259F%25D1%2580%25D0%25BE%25D0%25B8%25D0%25B7%25D0%25B2%25D0%25BE%25D0%25B4%25D1%2581%25D1%2582%25D0%25B2%25D0%25B5%25D0%25BD%25D0%25BD%25D1%258B%25D0%25B9%2520%25D0%25BA%25D0%25B0%25D0%25BB%25D0%25B5%25D0%25BD%25D0%25B4%25D0%25B0%25D1%2580%25D1%258C%25202018%26mode%3Dindoc%26topic_id%3D33843977%26spos%3D1%26tSynonym%3D1%26tShort%3D1%26tSuffix%3D1&sdoc_pos=0

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
);


my %HOLIDAYS_SPECIAL = (
    2018 => [ qw( 0821 0309 0508 0430 0831 1203 1218 1231 ) ],
);


my %BUSINESS_DAYS_ON_WEEKENDS = (
    2018 => [ qw( 0303 0505 0825 1229 ) ],
);

my %SHORT_BUSINESS_DAYS = (
    2018 => [ qw(  ) ],
);



sub is_holiday {
    my ( $year, $month, $day ) = @_;

    croak 'Bad params'  unless $year && $month && $day;

    return holidays( $year )->{ _get_date_key($month, $day) };
}


sub is_kz_holiday {
    goto &is_holiday;
}


my %cache;
sub holidays {
    my $year = shift or croak 'Bad year';

    return $cache{ $year }  if $cache{ $year };

    my $holidays = _get_regular_holidays_kz_year($year);

    if ( my $spec = $HOLIDAYS_SPECIAL{ $year } ) {
        $holidays->{ $_ } = 'Перенос праздничного дня'  for @$spec;
    }

    return $cache{ $year } = $holidays;
}

sub _get_regular_holidays_kz_year {
    my ($year) = @_;
    croak "KZ holidays is not valid before $HOLIDAYS_VALID_SINCE"  if $year < $HOLIDAYS_VALID_SINCE;

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

Date::Holidays::KZ - Determine Kazakhstan official holidays and business days.

=head1 VERSION

version 0.2018.0

=head1 SYNOPSIS

    use Date::Holidays::KZ qw( is_holiday holidays is_business_day );

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

Determine whether this date is a KZ holiday. Returns holiday name or undef.

=head2 is_kz_holiday( $year, $month, $day )

Alias for is_holiday().

=head2 holidays( $year )

Returns hash ref of all KZ holidays in the year.

=head2 is_business_day( $year, $month, $day )

Returns true if date is a business day in KZ taking holidays and weekends into account.

=head2 is_short_business_day( $year, $month, $day )

Returns true if date is a shortened business day in KZ.

=head1 NAME

Date::Holidays::KZ

=head1 VERSION

version 0.2018.0

=head1 AUTHOR

Vladimir Varlamov, C<< <bes.internal@gmail.com> >>

=head1 AUTHOR

Vladimir Varlamov <bes.internal@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vladimir Varlamov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
