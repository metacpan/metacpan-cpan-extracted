use utf8;

package Date::Holidays::AW;
our $VERSION = '0.002';
use strict;
use warnings;

# ABSTRACT: Aruba's official holidays

use Exporter qw(import);

our @EXPORT = qw(
    holidays
    is_holiday
);

use base qw(Date::Holidays::Abstract);
use DateTime::Event::Easter;
use DateTime;

my %FIXED_DATES = (
    'newyears' => {
        m   => 1,
        d   => 1,
        pap => 'Aña Nobo',
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
        pap => 'Na dia di Himno y Bandera',
        nl  => 'Nationale vlag en volkslied',
        en  => 'Flag day',
    },
    'kingsday' => {
        m   => 3,
        d   => 18,
        pap => 'Dia di bandera',
        nl  => 'Nationale vlag en volkslied',
        en  => 'Flag day',
    },
    'kingsday' => {
        m   => 4,
        d   => 27,
        pap => 'Dia di Reino',
        nl  => 'Koningsdag',
        en  => 'Kings day',
    },
    'labor' => {
        m   => 5,
        d   => 1,
        pap => 'Dia di Labor/Dia di Obrero',
        nl  => 'Dag van de arbeid',
        en  => 'Labor day',
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
    my ($year) = @_;

    $year //= DateTime->now()->year;

    return $cache{$year} if $cache{$year};

    my %h;
    foreach (keys %FIXED_DATES) {
        my $holiday = $FIXED_DATES{$_};
        my $dt      = _to_date($holiday->{d}, $holiday->{m}, $year);
        _to_holidays(\%h, $dt, $holiday);
    }


    my $dt = _to_date(1, 1, $year);
    foreach (keys %EASTER_BASED) {
        my $holiday = $EASTER_BASED{$_};
        my $easter  = DateTime::Event::Easter->new(
            easter => 'western',
            day => $holiday->{d}
        );
        my $dt      = $easter->following($dt);
        _to_holidays(\%h, $dt, $holiday);
    }

    $cache{$year} = \%h;

    return \%h;
}

sub _to_holidays {
    my ($cache, $dt, $info) = @_;
    $cache->{ sprintf("%02i", $dt->day) . sprintf("%02i", $dt->month) }
        = [map { $info->{$_} } qw(pap nl en)],;
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
    my ($year, $month, $day) = @_;

    my $holidays = holidays($year);
    my $dt       = _to_date($day, $month, $year);
    my $key      = sprintf("%02i", $dt->day) . sprintf("%02i", $dt->month);
    return exists $holidays->{$key};
}

'One happy island';

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::Holidays::AW - Aruba's official holidays

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Date::Holidays::AW;

    if (is_holiday(2020, 3, 18)) {
        print "It is Betico day!", $/;
    }

=head1 DESCRIPTION

A L<Date::Holiday> family member from Aruba

=head1 METHODS

This module implements the C<is_holiday> and C<holiday> functions from
L<Date::Holidays::Abstract>.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
