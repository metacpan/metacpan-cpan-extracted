package Data::VRM::GB;

use strict;
use warnings;
use Exporter::Easy (
    OK => [ qw/decode_vrm/ ],
);

use DateTime;

our $VERSION = '0.03';

sub _normalise_vrm($) {
    my ($vrm) = @_;
    $vrm =~ s/\s//g;
    $vrm =~ tr/a-z/A-Z/;
    return $vrm;
}

my $SUFFIX_TABLE = {
    A => [[1963, 2], [1963, 12]],
    B => [[1964, 1], [1964, 12]],
    C => [[1965, 1], [1965, 12]],
    D => [[1966, 1], [1966, 12]],
    E => [[1967, 1], [1967, 7]],
    F => [[1967, 8], [1968, 7]],
    G => [[1968, 8], [1969, 7]],
    H => [[1969, 8], [1970, 7]],
    # No I
    J => [[1970, 8], [1971, 7]],
    K => [[1971, 8], [1972, 7]],
    L => [[1972, 8], [1973, 7]],
    M => [[1973, 8], [1974, 7]],
    N => [[1974, 8], [1975, 7]],
    # No O
    P => [[1975, 8], [1976, 7]],
    # No Q
    R => [[1976, 8], [1977, 7]],
    S => [[1977, 8], [1978, 7]],
    T => [[1978, 8], [1979, 7]],
    # No U
    V => [[1979, 8], [1980, 7]],
    W => [[1980, 8], [1981, 7]],
    X => [[1981, 7], [1982, 7]],
    Y => [[1982, 8], [1983, 7]],
};

my $PREFIX_TABLE = {
    A => [[1983, 8], [1984, 7]],
    B => [[1984, 8], [1985, 7]],
    C => [[1985, 8], [1986, 7]],
    D => [[1986, 8], [1987, 7]],
    E => [[1987, 8], [1988, 7]],
    F => [[1988, 8], [1989, 7]],
    G => [[1989, 8], [1990, 7]],
    H => [[1990, 8], [1991, 7]],
    # There's no I
    J => [[1991, 8], [1992, 7]],
    K => [[1992, 8], [1993, 7]],
    L => [[1993, 8], [1994, 7]],
    M => [[1994, 8], [1995, 7]],
    N => [[1995, 8], [1996, 7]],
    # There's no O
    P => [[1996, 8], [1997, 7]],
    # There's no Q
    R => [[1997, 8], [1998, 7]],
    S => [[1998, 8], [1999, 2]],
    T => [[1999, 3], [1999, 8]],
    # There's no U
    V => [[1999, 9], [2000, 2]],
    W => [[2000, 3], [2000, 8]],
    X => [[2000, 9], [2001, 2]],
    Y => [[2001, 3], [2001, 8]],
    # There's no Z
};

# Apply this to end dates to push the time portion close to midnight the following day,
# to make the code that bit more tolerant if comparison is done with untruncated DateTime.
# The recommendation remains that the user should truncate their DateTime before comparing, however.
my $tolerant_end_date = sub { shift->set(hour => 23, minute => 59, second => 59) };

sub decode_vrm($) {
    my ($vrm) = @_;
    $vrm = _normalise_vrm($vrm);
    if ($vrm =~ /^[A-Z]{2}([0-9]{2})[A-Z]{3}$/) {
        # The normal case
        my ($start_year, $start_month) = _split_age_numbers($1);
        return undef unless defined $start_year;
        my $start_date = DateTime->new(year => $start_year, month => $start_month, day => 1);
        my $e = $start_date->clone->add(months => 5);
        my $end_date = DateTime->last_day_of_month(year => $e->year, month => $e->month);
        return {
            start_date => $start_date,
            end_date => $end_date->$tolerant_end_date,
        };
    }
    elsif ($vrm =~ /^([A-Z])[0-9]{1,3}[A-Z]{3}$/) {
        return _resolve_letter_mark($PREFIX_TABLE, $1);
    }
    elsif ($vrm =~ /^[A-Z]{3}[0-9]{1,3}([A-Z])$/) {
        return _resolve_letter_mark($SUFFIX_TABLE, $1);
    }
    # No patterns matched, can't parse this type of VRM
    return undef;
}

sub _split_age_numbers {
    my ($age_pair) = @_;
    # Special cases
    if ($age_pair eq '50') {
        return (2050, 3);
    }
    elsif ($age_pair eq '00') {
        return (2050, 9);
    }
    elsif ($age_pair eq '01') {
        return undef;
    }

    # Usual case
    my ($month_id, $year_id) = split(//, $age_pair);
    my $year_tens = ($month_id < 5) ? $month_id : ($month_id - 5);
    my $year_units = $year_id;
    my $start_year = 2000 + ($year_tens * 10) + $year_units;
    my $start_month = ($month_id < 5) ? 3 : 9;
    return ($start_year, $start_month);
}

sub _start_of_month {
    return DateTime->new(@_, day => 1);
}

sub _ym {
    my ($y, $m) = @_;
    return (year => $y, month => $m);
}

sub _resolve_letter_mark {
    my ($table, $letter) = @_;
    my $pair = $table->{$letter};
    return undef unless defined $pair;
    my ($start_pair, $end_pair) = @$pair;
    return {
        start_date => _resolve_start_pair($start_pair),
        end_date => _resolve_end_pair($end_pair)->$tolerant_end_date,
    };
}

sub _resolve_start_pair($) {
    my ($pair) = @_;
    return _start_of_month(_ym(@$pair));
}

sub _resolve_end_pair($) {
    my ($pair) = @_;
    return DateTime->last_day_of_month(_ym(@$pair));
}



1;

=head1 NAME

Data::VRM::GB - Extract data about British vehicle registration marks

=head1 DESCRIPTION

This module allows you to get age information based on a vehicle registration
mark.

=head1 SYNOPSIS

    use Data::VRM::GB qw/decode_vrm/;

    my $vd = decode_vrm('AB56 RST');
    $vd->{start_date};
    $vd->{end_date};

=head1 LIMITATIONS

The API is unstable - we haven't fully decided on the API and return data types yet.

=head1 EXPORTS

=head2 decode_vrm

A function which takes a VRM as its first and only argument, and returns a
HASHREF with the keys C<start_date> and C<end_date>.
Each of those keys has as its value a DateTime object, truncated to the 'day'.

If the registration mark couldn't be decoded to a date, either
because it's of an unrecognised format or is using a letter prefix that is
not understood, then it will return undef.

Before comparing these dates with another DateTime, you must ensure you
truncate your DateTime to the day.  If you have a time portion, you will
get errors creeping in.

    DateTime->compare(
       decode_vrm('AB56 RST')->{end_date},
       $your_dt->truncate(to => 'day')
    );


=head1 SUPPORT

If you require assistance, support, or further development of this software, please contact OpusVL using the details below:

Telephone: +44 (0)1788 298 410

Email: community@opusvl.com

Web: http://opusvl.com

=head1 COPYRIGHT & LICENSE

Copyright (C) 2015 Opus Vision Limited

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut

