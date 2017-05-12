package Bessarabv::Weight;
{
  $Bessarabv::Weight::VERSION = '1.0.0';
}

# ABSTRACT: get Ivan Bessarabov's weight data


use strict;
use warnings;
use Carp;

use LWP::Simple;
use JSON;
use Time::Local;

my $true = 1;
my $false = '';


sub new {
    my ($class, %opts) = @_;

    croak "new() does not need any parameters. Stopped" if %opts;

    my $self = {};
    bless $self, $class;

    $self->__get_data();

    return $self;
}


sub has_weight {
    my ($self, $date) = @_;

    $self->__die_if_date_is_incorrect($date);

    if (exists $self->{__data}->{$date} and defined $self->{__data}->{$date}) {
        return $true;
    } else {
        return $false;
    }
}


sub get_weight {
    my ($self, $date) = @_;

    if ($self->has_weight($date)) {
        return $self->{__data}->{$date};
    } else {
        $date = '' if not defined $date;
        croak "There is no weight info for the date '$date'";
    }
}

sub __get_data {
    my ($self) = @_;

    my $json = get("http://ivan.bessarabov.ru/weight.json");
    my $data = from_json($json);

    my $day_data = $data->[0]->{day};

    my %date2weight = map { $_->{label} => $_->{min_value} } @{ $day_data };

    $self->{__data} =  \%date2weight;

    return $false;
}

sub __die_if_date_is_incorrect {
    my ($self, $date) = @_;

    $date = '' if not defined $date;

    if ($date =~ /^(\d{4})-(\d\d)-(\d\d)$/) {

        my $year = $1;
        my $month = $2;
        my $day = $3;

        # It dies with more or less fiendly message in case of error
        timelocal(0,0,0, $day, $month-1, $year);

    } else {
        croak "Incorrect date '$date'. Stopped";
    }

    return $false;
}

1;

__END__

=pod

=head1 NAME

Bessarabv::Weight - get Ivan Bessarabov's weight data

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

    use Bessarabv::Weight;

    my $bw = Bessarabv::Weight->new();

    print $bw->get_weight("2013-08-21") # 82.2

=head1 DESCRIPTION

My name is Ivan Bessarabov and I'm a lifelogger. Well, actually I don't record
all of my life, but I do records of some parts of my life.

One of the thing that I measure is my weight. I use super pretty iPhone App
L<Weightbot|http://tapbots.com/software/weightbot/>. I've created Perl module
L<Weightbot::API> to get data from that App. I use that module to download my
weight data and to draw L<graph|http://ivan.bessarabov.ru/weight>.

This module is a very simple Perl API to get info about my weight that is
stored somewhere in the cloud. I sometimes play with this numbers, so I have
releases this module to make things easy. Not sure if someone else will need
this module, but there is no secret here and that's why I've released it on
CPAN, but not on my DarkPAN.

Bessarabv::Weight uses Semantic Versioning standart for version numbers.
Please visit L<http://semver.org/> to find out all about this great thing.

=head1 METHODS

=head2 new

This is a constructor. It recieves no parameters and it returns object.

This constructor downloads data from the cloud and stores it in the object.
There is only one interaction with the cloud. After the new() is completed no
interactions with the cloud is done.

    my $bw = Bessarabv::Weight->new();

=head2 has_weight

If there is weight data for the given date it returns true value. Othervise i
returns false value. It should recieve date in the format YYYY-MM-DD. In case
the date is incorrect this method will die.

    $bw->has_weight("2013-08-11");  # false
    $bw->has_weight("2013-08-20");  # true

=head2 get_weight

Returns my weight in kilograms for the given date. In case the date is
incorrect the method dies. The method dies if there is no value for the
specified date.

    $bw->get_weight("2013-08-10");  # 80.8
    $bw->get_weight("2013-08-11");  # Boom! Script dies here because there is
                                    # no value. Use has_weight() to check.

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
