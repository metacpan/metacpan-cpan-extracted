package Date::Holidays::AW;
our $VERSION = '0.005';
use strict;
use warnings;

# ABSTRACT: Aruba's official holidays

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
        pap => "A\x{00F1}a Nobo",
        nl  => 'Nieuwjaarsdag',
        en  => 'New years day',
    },
    'betico' => {
        m   => 1,
        d   => 25,
        pap => 'Dia di Betico',
        nl  => 'Betico-dag',
        en  => 'Betico day',
    },
    'flagday' => {
        m   => 3,
        d   => 18,
        pap => 'Dia di Himno y Bandera',
        nl  => 'Nationale vlag en volkslied',
        en  => 'Flag day',
    },
    'wimlex' => {
        m      => 4,
        d      => 27,
        nl     => 'Koningsdag',
        en     => 'Kings day',
        pap    => 'Dia di Rei',
        # change day of week if it falls on a sunday
        dow    => { 7 => -1 },
        year_started => 2014,
    },
    'minna-princess' => {
        m  => 8,
        d  => 31,
        nl => 'Prinsessedag',
        en => "Princess's day",
        pap => 'Dia di Prensesa',

        # change day of week if it falls on a sunday
        dow          => { 7 => 1 },
        year_started => 1885,
        year_ended   => 1890,
    },
    'minna-queen' => {
        m   => 8,
        d   => 31,
        nl  => 'Koninginnedag',
        en  => "Queen's day",
        pap => 'Dia di Reina',

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
        pap => 'Dia di Reina',

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
        pap => 'Dia di Reina',

        # change day of week if it falls on a sunday
        dow          => { 7 => -1 },
        year_started => 1980,
        year_ended   => 2013,
    },
    'labor' => {
        m   => 5,
        d   => 1,
        pap => 'Dia di Labor/Dia di Obrero',
        nl  => 'Dag van de arbeid',
        en  => 'Labor day',
        # change day of week if it falls on a sunday
        dow          => { 7 => 1 },
    },
    'xmas' => {
        m   => 12,
        d   => 25,
        pap => 'Pasco di Nacemento',
        nl  => 'Kerst',
        en  => 'Christmas',
    },
    'boxing' => {
        m   => 12,
        d   => 26,
        pap => 'Di dos dia di Pasco di Nacemento',
        nl  => 'Tweede kerstdag',
        en  => 'Boxing day',
    },
);

my %EASTER_BASED = (
    'carnaval' => {
        d   => -48,
        pap => 'Despues di Carnaval grandi',
        nl  => 'Carnavalsmaandag',
        en  => 'Carnaval monday',
    },
    'goodfri' => {
        d   => -2,
        pap => 'Bierna Santo',
        nl  => 'Goede vrijdag',
        en  => 'Good friday',
    },
    'easter' => {
        d   => 0,
        pap => 'Pasco Grandi',
        nl  => 'Pasen',
        en  => 'Easter',
    },
    'easter2' => {
        d   => 1,
        pap => 'Pasco Grandi',
        nl  => 'Tweede paasdag',
        en  => 'Second day of easter',
    },
    'ascension' => {
        d   => 40,
        pap => 'Dia di Asuncion',
        nl  => 'Hemelvaartsdag',
        en  => 'Ascension day',
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
            if ($args{gov} && $holiday->{gov}) {
                # We should have this
            }
            else {
                next if $year % $int != 0;
            }
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
        = [ map { $info->{$_} } qw(pap nl en)];
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
        my $lang = lc(delete $args{lang} // 'pap');
        if ($lang eq 'nl' || $lang eq 'nld') {
            return $holidays->{$key}[1];
        }
        if ($lang eq 'en' || $lang eq 'eng') {
            return $holidays->{$key}[2];
        }
        # default to pap
        return $holidays->{$key}[0];
    }
    return;
}

'Aruba dushi terra';

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Holidays::AW - Aruba's official holidays

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Date::Holidays::AW;

    if (my $thing = is_holiday(2020, 3, 18, lang => 'en')) {
        print "It is $thing!", $/; # prints 'It is Betico day!'
    }

=head1 DESCRIPTION

A L<Date::Holidays> family member from Aruba

=head1 METHODS

This module implements the C<is_holiday> and C<holiday> functions from
L<Date::Holidays::Abstract>.

=head2 is_holiday(yyyy, mm, dd, %additional)

    is_holiday(
        '2020', '3', '18',
        gov  => 1,      # Important for government institutions
        lang => 'en'    # defaults to pap, alternatively nl/nld or en/eng can be used.
    );

=head2 is_holiday_dt(dt, %additional)

    is_holiday_dt(
        DateTime->new(
            year      => 2020,
            month     => 3,
            day       => 18,
            time_zone => 'America/Curacao',
        ),
        gov  => 1,      # Important for government institutions
        lang => 'en'    # defaults to pap, alternatively nl/nld or en/eng can be used.
    );

=head2 holidays(yyyy, gov => 1)

    holidays('2022', gov  => 1);

Similar API to the other functions, returns an hashref for the year.

=head1 UTF-8

Be aware that we return UTF-8 when Papiamento is chosen. So make sure you set
your enconding to UTF-8, otherwise you may see weird things.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
