package Date::Holidays::PL;
BEGIN {
  $Date::Holidays::PL::AUTHORITY = 'cpan:AJGB';
}
BEGIN {
  $Date::Holidays::PL::VERSION = '1.110050';
}
# ABSTRACT: Determine holidays for Poland

use strict;
use warnings;
use utf8;

use parent qw( Date::Holidays::Abstract );

use DateTime;
use Params::Validate qw( validate validate_pos SCALAR BOOLEAN OBJECT );
use Date::Easter qw( gregorian_easter );
use Try::Tiny;

use Sub::Exporter -setup => {
    exports => [
        qw( pl_holidays is_pl_holiday pl_holidays_dt is_pl_holiday_dt ),
    ],
};


# holidays always present
my %SharedHolidays = map {
    $_ => 1
} qw( 0101 0501 1101 1225 1226 );

# law changes in 1951, 1960, 1989, 1990 and 2011
my %ChangesByYear = (
    (
        map {
            $_ => {
                %SharedHolidays,
                map { $_ => 1 } qw( 0106 0722 0815 )
            }
        } (1951 .. 1959),
    ),
    (
        map {
            $_ => {
                %SharedHolidays,
                map { $_ => 1 } qw( 0722 )
            }
        } (1960 .. 1988),
    ),
    1989 => {
        %SharedHolidays,
        map { $_ => 1 } qw( 0722 0815 1111 )
    },
    # since 1990
    1990 => {
        %SharedHolidays,
        map { $_ => 1 } qw( 0503 0815 1111 )
    },
    # since 2011
    'CURRENT' => {
        %SharedHolidays,
        map { $_ => 1 } qw( 0106 0503 0815 1111 )
    },
);
# always on those dates
my %FixedHolidays = (
    # New Year's Day
    '0101' => 'Nowy Rok',
    # Epiphany (1951-1959 only)
    '0106' => 'Trzech Króli',
    # Labor Day
    '0501' => 'Święto Państwowe',
    # Constitution Day ( since 1990 )
    '0503' => 'Święto Narodowe Trzeciego Maja',
    # Polish Committee of National Liberation Manifesto (1951-1989 only)
    '0722' => 'Święto Odrodzenia Polski',
    # Assumption of the Blessed Virgin Mary ( 1951-1959, 1989+ )
    '0815' => 'Wniebowzięcie Najświętszej Maryi Panny',
    # All Saints' Day
    '1101' => 'Wszystkich Świętych',
    # Independence Day ( since 1989 )
    '1111' => 'Narodowe Święto Niepodległości',
    # Christmas Day
    '1225' => 'pierwszy dzień Bożego Narodzenia',
    # Boxing Day
    '1226' => 'drugi dzień Bożego Narodzenia',
);

# Params::Validate config
my $ValidateOpts = {
    year => {
        type => SCALAR,
        regex => qr/^\d{4}$/,
        callbacks => {
            'between 1951 and 9999' => sub {
                shift >= 1951
            },
        },
    },
    month => {
        type => SCALAR,
    },
    day => {
        type => SCALAR,
    },
    WEEKENDS => {
        type => BOOLEAN,
        default => 1,
        optional => 1,
    }
};


sub pl_holidays {
    my ($year) = validate_pos(@{[shift]},
        $ValidateOpts->{year},
    );
    my %args = validate(@_,
        {
            WEEKENDS => $ValidateOpts->{WEEKENDS},
        }
    );

    my $y = exists $ChangesByYear{$year} ? $year : 'CURRENT';

    my $holidays = {
        _compute_movablefeasts_for_year( $year ),
        map {
            $_ => $FixedHolidays{$_}
        } keys %{ $ChangesByYear{$y} },
    };

    unless ( $args{WEEKENDS} ) {
        my @weekend_holidays = grep {
                my ($m, $d) = unpack "A2A2", $_;

                my $dt = DateTime->new(
                    year => $year,
                    month => $m,
                    day => $d
                );

                $dt->day_of_week >= 6;
            } keys %$holidays;

        delete @{$holidays}{ @weekend_holidays };
    }

    return $holidays;
};


sub pl_holidays_dt {
    my $year = shift;
    my $holidays = pl_holidays($year, @_);

    return +{
        map {
            my ($m, $d) = unpack "A2A2", $_;
            my $name = $holidays->{$_};

            $name => DateTime->new(
                year => $year,
                month => $m,
                day => $d
            );
        } keys %$holidays
    }
}


sub is_pl_holiday {
    my ($year, $month, $day) = validate_pos(@_,
        @{$ValidateOpts}{qw(year month day)}
    );

    my $dt;

    # let DateTime validate the date - no need to validate twice
    try {
        $dt = DateTime->new(
            year => $year,
            month => $month,
            day => $day,
        );
    } catch {
        die "Date $year-$month-$day is invalid: $_";
    };

    my $holidays = pl_holidays( $year );

    my $md = $dt->strftime('%m%d');
    return $holidays->{$md};
}


sub is_pl_holiday_dt {
    my ($dt) = validate_pos(@_,
        {
            type => OBJECT,
            isa => 'DateTime',
        }
    );

    my $holidays = pl_holidays( $dt->year );

    my $md = $dt->strftime('%m%d');
    return $holidays->{$md};
}

# calculate moveable feast for given year
sub _compute_movablefeasts_for_year {
    my $year = shift;

    # already calculated

    my @easter_md = map { sprintf('%02d', $_ ) } gregorian_easter( $year );

    my $easter = DateTime->new(
        year => $year,
        month => $easter_md[0],
        day => $easter_md[1],
    );

    return (
        # Easter Sunday
        $easter->strftime('%m%d') =>
            'pierwszy dzień Wielkanocy',
        # Easter Monday
        $easter->clone->add( days => 1)->strftime('%m%d') =>
            'drugi dzień Wielkanocy',
        # Pentecoste Sunday
        $easter->clone->add( days => 49)->strftime('%m%d') =>
            'pierwszy dzień Zielonych Świątek',
        # Corpus Christi
        $easter->clone->add( days => 60)->strftime('%m%d') =>
            'dzień Bożego Ciała',
    );
}




1;

__END__
=pod

=encoding utf-8

=head1 NAME

Date::Holidays::PL - Determine holidays for Poland

=head1 VERSION

version 1.110050

=head1 SYNOPSIS

    use Date::Holidays::PL qw( pl_holidays is_pl_holiday
                               pl_holidays_dt is_pl_holiday_dt);

    my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
    $year  += 1900;
    $month += 1;

    # pl_holidays
    my $holidays = pl_holidays( $year );
    for my $month_day ( keys %$holidays ) {
        print "$month_day: $holidays->{$month_day}\n";
    }

    # pl_holidays_dt
    my $holidays_dt = pl_holidays_dt( $year );
    for my $name ( keys %$holidays ) {
        print "$name ", $holidays->{$name}->strftime('%Y-%m-%d'), "\n";
    }

    # is_pl_holiday
    if ( my $name = is_pl_holiday($year, $month, $day) ) {
        print "$year-$month-$day is a public holiday: $name\n";
    }

    # is_pl_holiday_dt
    if ( my $name = is_pl_holiday_dt(DateTime->now) ) {
        print "Today is a public holiday: $name\n";
    }

=head1 DESCRIPTION

Date::Holidays::PL determines public holidays for Poland.

=head1 METHODS

=head2 pl_holidays

    my $holidays = pl_holidays( $year );

    my $holidays_excluding_weekends = pl_holidays( $year, { WEEKENDS => 0 } );

Returns a hashref of all public holidays for given year. Keys are in the
month-day format I<MMDD> and the values are the names of the holidays.

As the second argument hashref could be provided with one configuration
option:

=over 4

=item WEEKENDS

If set to false then the list of holidays will not include those which are
during weekends.

Boolean, default true.

=back

=head2 pl_holidays_dt

    my $holidays = pl_holidays_dt( $year );

    my $holidays_excluding_weekends = pl_holidays_dt( $year, { WEEKENDS => 0 } );

Returns a hashref of all public holidays for given year. Keys are the names
of the holidays (in Polish) and values are DateTime objects.

As the second argument hashref could be provided with one configuration
option:

=over 4

=item WEEKENDS

If set to false then the list of holidays will not include those which are
during weekends.

Boolean, default true.

=back

=head2 is_pl_holiday

    if ( my $name = is_pl_holiday($year, $month, $day) ) {
        print "$year-$month-$day is a public holiday: $name\n";
    }

Takes three arguments: I<year>, I<month> and I<day>.

Returns the name of a holiday if date given is a public holiday, otherwise
returns undef.

=head2 is_pl_holiday_dt

    if ( my $name = is_pl_holiday_dt(DateTime->now) ) {
        print "Today is a public holiday: $name\n";
    }

Takes one argument: L<DateTime> object.

Returns the name of a holiday if date given is a public holiday, otherwise
returns undef.

=head1 PUBLIC HOLIDAYS

The following Polish holidays have fixed dates:

    # New Year's Day
    Jan  1     Nowy Rok
    # Epiphany (1951-1959, 2011+ only)
    Jan  6     Trzech Króli
    # Labor Day
    May  1     Święto Państwowe
    # Constitution Day ( since 1990 )
    May  3     Święto Narodowe Trzeciego Maja
    # Polish Committee of National Liberation Manifesto (1951-1989 only)
    Jul 22     Święto Odrodzenia Polski
    # Assumption of the Blessed Virgin Mary ( 1951-1959, 1989+ )
    Aug 15     Wniebowzięcie Najświętszej Maryi Panny
    # All Saints' Day
    Nov  1     Wszystkich Świętych
    # Independence Day ( since 1989 )
    Nov 11     Narodowe Święto Niepodległości
    # Christmas Day
    Dec 25     pierwszy dzień Bożego Narodzenia
    # Boxing Day
    Dec 26     drugi dzień Bożego Narodzenia

List of Polish moveable feasts:

    # Easter Sunday
               pierwszy dzień Wielkanocy
    # Easter Monday
    +1 day     drugi dzień Wielkanocy
    # Pantecoste Sunday
    +49 days   pierwszy dzień Zielonych Świątek
    # Corpus Christi
    +60 days   dzień Bożego Ciała

Based on Polish law (since year 1951):
L<Ustawa z dnia 18 stycznia 1951 r. o dniach wolnych od pracy|http://isap.sejm.gov.pl/DetailsServlet?id=WDU19510040028>
and
L<Ustawa z dnia 24 września 2010 r. o zmianie ustawy - Kodeks pracy oraz niektórych innych ustaw|http://isap.sejm.gov.pl/DetailsServlet?id=WDU20102241459>.

=head1 EXPORTS

Date::Holidays::PL uses L<Sub::Exporter> to export following methods:

=over 4

=item *

L<"pl_holidays">

=item *

L<"pl_holidays_dt">

=item *

L<"is_pl_holiday">

=item *

L<"is_pl_holiday_dt">

=back

By default no methods are exported.

=head1 SEE ALSO

=over 4

=item *

L<Date::Holidays>

=item *

L<Date::Holidays::Abstract>

=item *

L<http://pl.wikipedia.org/wiki/Dni_wolne_od_pracy_w_Polsce>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

