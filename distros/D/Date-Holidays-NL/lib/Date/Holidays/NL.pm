package Date::Holidays::NL;
our $VERSION = '0.007';
use strict;
use warnings;

# ABSTRACT: The Netherlands official holidays

use Exporter qw(import);

our @EXPORT = qw(
    holidays
    is_holiday
    is_holiday_dt
);

use base qw(Date::Holidays::Abstract);
use DateTime::Event::Easter;
use DateTime;

my %FIXED_DATES = (
    'newyears' => {
        m   => 1,
        d   => 1,
        nl  => 'Nieuwjaarsdag',
        en  => 'New years day',
    },
    'wimlex' => {
        m      => 4,
        d      => 27,
        nl     => 'Koningsdag',
        en     => 'Kings day',
        # change day of week if it falls on a sunday
        dow    => { 7 => -1 },
        year_started => 2014,
    },
    'minna-princess' => {
        m  => 8,
        d  => 31,
        nl => 'Prinsessedag',
        en => "Princess's day",

        # change day of week if it falls on a sunday
        dow          => { 7 => 1 },
        year_started => 1885,
        year_ended   => 1890,
    },
    'minna-queen' => {
        m  => 8,
        d  => 31,
        nl => 'Koninginnedag',
        en => "Queen's day",

        # change day of week if it falls on a sunday
        dow          => { 7 => 1 },
        year_started => 1891,
        year_ended   => 1948,
    },
    'juliana-beatrix' => {
        m  => 4,
        d  => 30,
        nl => 'Koninginnedag',
        en => "Queen's day",

        # change day of week if it falls on a sunday
        dow          => { 7 => 1 },
        year_started => 1949,
        year_ended   => 1979,
    },
    'juliana-beatrix-2' => {
        m  => 4,
        d  => 30,
        nl => 'Koninginnedag',
        en => "Queen's day",

        # change day of week if it falls on a sunday
        dow          => { 7 => -1 },
        year_started => 1980,
        year_ended   => 2013,
    },
    'liberation' => {
        m        => 5,
        d        => 5,
        nl       => 'Bevrijdingsdag',
        en       => 'Liberation day',
        interval => 5, # Day off every five years
        gov      => 1, # Government works are having a day off tho
    },
    'xmas' => {
        m   => 12,
        d   => 25,
        nl  => 'Kerst',
        en  => 'Christmas',
    },
    'boxing' => {
        m   => 12,
        d   => 26,
        nl  => 'Tweede kerstdag',
        en  => 'Boxing day',
    },
);

my %EASTER_BASED = (
    'goodfri' => {
        d   => -2,
        nl  => 'Goede vrijdag',
        en  => 'Good friday',
        gov => 1,
    },
    'easter' => {
        d   => 0,
        nl  => 'Pasen',
        en  => 'Easter',
    },
    'easter2' => {
        d   => 1,
        nl  => 'Tweede paasdag',
        en  => 'Second day of easter',
    },
    'ascension' => {
        d   => 40,
        nl  => 'Hemelvaartsdag',
        en  => 'Ascension day',
    },
    pentecost => {
        d   => 49,
        nl  => 'Pinksteren',
        en  => 'Pentecost',
    },
    pentecost2 => {
        d   => 50,
        nl  => 'Tweede pinksterdag',
        en  => 'Pentecost',
    }
);

my %cache;

sub holidays {
    my $year = shift;
    my %args = @_;

    $year //= DateTime->now()->year;

    my $key = $year;
    if ($args{gov}) {
        $key .= 'gov';
    }

    return $cache{$key} if $cache{$key};

    my %h;
    foreach (keys %FIXED_DATES) {
        my $holiday = $FIXED_DATES{$_};

        if (my $int = $holiday->{interval}) {
            if (!$args{gov}) {
                next if $year % $int != 0;
            }
        }
        # Skip government holidays, currently good friday only
        # https://wetten.overheid.nl/BWBR0002448/2010-10-10
        elsif (!$args{gov} && $holiday->{gov}) {
            next;
        }

        if (my $start = $holiday->{year_started}) {
            next if $year < $start;
        }

        if (my $end = $holiday->{year_ended}) {
            next if $year > $end;
        }

        my $dt = _to_date($holiday->{d}, $holiday->{m}, $year);

        if (my $dow = $holiday->{dow}) {
            my $cur = $dt->dow();
            foreach (keys %$dow) {
                next unless $cur == $_;
                $dt->add(days => $dow->{$_});
                last;
            }
        }

        _to_holidays(\%h, $dt, $holiday);
    }

    my $dt = _to_date(1, 1, $year);
    foreach (keys %EASTER_BASED) {
        my $holiday = $EASTER_BASED{$_};
        if (!$args{gov} && $holiday->{gov}) {
            next;
        }
        my $easter  = DateTime::Event::Easter->new(
            easter => 'western',
            day    => $holiday->{d}
        );
        my $dt = $easter->following($dt);
        _to_holidays(\%h, $dt, $holiday);
    }

    $cache{$key} = \%h;

    return \%h;
}

sub _to_holidays {
    my ($cache, $dt, $info) = @_;
    $cache->{ sprintf("%02i", $dt->day) . sprintf("%02i", $dt->month) }
        = [map { $info->{$_} } qw(nl en)];
}

sub _to_date {
    my ($day, $month, $year) = @_;
    return DateTime->new(
        day       => $day,
        month     => $month,
        year      => $year,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'UTC',
    );
}

sub is_holiday {
    my $year  = shift;
    my $month = shift;
    my $day   = shift;

    my $dt = _to_date($day, $month, $year);
    return is_holiday_dt($dt, @_);
}

sub is_holiday_dt {
    my $dt = shift;

    my %args = @_;

    my $holidays = holidays($dt->year, @_);
    my $key      = sprintf("%02i", $dt->day) . sprintf("%02i", $dt->month);

    if (exists $holidays->{$key}) {
        my $lang = lc(delete $args{lang} // 'nl');
        if ($lang eq 'en' || $lang eq 'eng') {
            return $holidays->{$key}[1];
        }
        # default to dutch
        return $holidays->{$key}[0];
    }
    return;
}

'I always get my sin';

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Holidays::NL - The Netherlands official holidays

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Date::Holidays::NL;

    if (my $thing = is_holiday(2020, 5, 5, lang => 'en')) {
        print "It is $thing!", $/; # prints 'It is Liberation day!'
    }

=head1 DESCRIPTION

A L<Date::Holidays> family member from the Netherlands

=head1 METHODS

This module implements the C<is_holiday>, C<is_holiday_dt> and C<holiday>
functions from L<Date::Holidays::Abstract>.

All methods accept additional parameters. The most important is a flag called
C<gov>, when supplied you will get days that the government considers special
in regards to service terms. It essentially says that if a company or
government needs to contact you before or on that day it can be expedited to
the following work day. See the L<relevant
law|https://wetten.overheid.nl/BWBR0002448/2010-10-10> for more information.

=head2 is_holiday(yyyy, mm, dd, %additional)

    is_holiday(
        '2022', '05', '05',
        gov  => 1,      # Important for government institutions
        lang => 'en'    # defaults to nl/nld, alternatively en/eng can be used.
    );

=head2 is_holiday_dt(dt, %additional)

    is_holiday_dt(
        DateTime->new(
            year      => 2022,
            month     => 5,
            day       => 5,
            time_zone => 'Europe/Amsterdam',
        ),
        gov  => 1,      # Important for government institutions
        lang => 'en'    # defaults to nl/nld, alternatively en/eng can be used.
    );

=head2 holidays(yyyy, gov => 1)

    holidays('2022', gov  => 1);

Similar API to the other functions, returns an hashref for the year.

=head1 SEE ALSO

=over

=item https://wetten.overheid.nl/BWBR0002448/2010-10-10

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
