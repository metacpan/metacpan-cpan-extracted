package Calendar::Japanese::Acme::Syukujitsu;

use 5.006;
use strict;
use warnings;
use utf8;

use Carp qw(croak);
use Class::Accessor::Lite (ro => [qw(max_year min_year syukujitsus)]);
use Encode;
use File::Slurp;
use Furl;
use List::Util qw(max min);
use Smart::Args;

our $VERSION = '0.01';
our $DEFAULT_ENDPOINT = 'http://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv';

sub new {
    args
        my $class,
        my $cachefile => {optional => 1},
        my $endpoint => {optional => 1};

    my $data;
    if ($cachefile) {
        $data = read_file($cachefile);
    } else {
        $endpoint = $endpoint || $DEFAULT_ENDPOINT;
        $data = Furl->new()->get($endpoint)->content;
    }
    Encode::from_to($data, 'sjis', 'utf-8');

    my $syukujitsus = {};
    for my $line (split /\n/, $data) {
        chop($line) if $line =~ /(\n|\r|\n\r)$/;
        my ($date, $syukujitsu_name) = split /,/, $line;
        my ($year, $month, $day) = split /-/, $date;
        next unless $day;

        $month =~ s/^0//;
        $day =~ s/^0//;
        $syukujitsus->{$year}{$month}{$day} = $syukujitsu_name;
    }

    bless +{
        max_year => max(keys %$syukujitsus),
        min_year => min(keys %$syukujitsus),
        syukujitsus => $syukujitsus,
    } => $class
}

sub get_syukujitsus {
    args
        my $self,
        my $year,
        my $month => {optional => 1},
        my $day => {optional => 1};

    croak "$year is too old for Japanese government calendar." if $year < $self->min_year;
    croak "$year is too new for Japanese government calendar." if $year > $self->max_year;

    if (!$day and !$month) {
        return $self->syukujitsus->{$year};
    } elsif (!$day) {
        return $self->syukujitsus->{$year}{$month};
    } else {
        return $self->syukujitsus->{$year}{$month}{$day};
    }
}

sub is_syukujitsu {
    args
        my $self,
        my $year,
        my $month,
        my $day;

    croak "$year is too old for Japanese government calendar." if $year < $self->min_year;
    croak "$year is too new for Japanese government calendar." if $year > $self->max_year;

    return $self->syukujitsus->{$year}{$month}{$day};
}

1;

__END__

=head1 NAME

Calendar::Japanese::Acme::Syukujitsu - Japanese Syukujitsu in calender

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use Calendar::Japanese::Acme::Syukujitsu;

  # Getting a list of Syukujitsus
  $holidays = get_syukujitsus(2017, 8);
  $holidays = get_syukujitsus(2017, 8, 18);

  # Examining whether it is holiday or not.
  $name = is_syukujitsu(2017, 9, 11);

=head1 DESCRIPTION

This module read Syukujitsu information from
F<syukujitsu.csv> that published by Japanese government.
With interface that referenced to C<Calendar::Japanese::Holiday>.

=head1 METHODS

=head2 new([cachefile => $cachefile][endpoint => $endpoint])
Constructor.

=head2 get_syukujitsus(year => $year [, month => $month [, day => $day]])

=head2 is_syukujitsu(year => $year, month => $month, day => $day)

=head1 AUTHOR

Nao Muto <n@o625.com>

=cut
