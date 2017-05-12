package DateTime::Format::Duration::XSD;

use 5.008008;
use strict;
use warnings;

use Carp;
use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;

our $VERSION = 0.01;

sub new {
    my $class = shift;
    return bless {
        fmt => DateTime::Format::Duration->new(
            pattern => '%PP%YY%mM%dDT%HH%MM%S.%NS',
            normalize => 1,
        ),
    }, $class;
}

sub parse_duration {
    my ($self, $xs_duration) = @_;
    my ($neg, $year, $mounth, $day, $hour, $min, $sec, $fsec);
    if ($xs_duration =~ /^(-)?
                          P
                          ((\d+)Y)?
                          ((\d+)M)?
                          ((\d+)D)?
                          (
                          T
                          ((\d+)H)?
                          ((\d+)M)?
                          (((\d+)(\.(\d+))?)S)?
                          )?
                         $/x)
    {
        ($neg, $year, $mounth, $day, $hour, $min, $sec, $fsec) =
        ($1,   $3,    $5,      $7,   $10,   $12,  $15,  $17);
        unless (grep {defined} ($year, $mounth, $day, $hour, $min, $sec)) {
            croak "duration contains no data '$xs_duration'";
        }
    } else {
        croak "duration string does not match standart: '$xs_duration'";
    }
    my $dt = DateTime::Duration->new(
        years   => $year || 0,
        months  => $mounth || 0,
        days    => $day || 0,
        hours   => $hour || 0,
        minutes => $min || 0,
        seconds => $sec || 0,
        nanoseconds => ($fsec ? "0.$fsec" * 1E9  : 0),
    );
    return defined $neg ? $dt->inverse : $dt;
}


sub format_duration {
    my ($self, $duration) = @_;
    my %deltas = $self->{fmt}->normalize($duration);
    if (exists $deltas{seconds} or exists $deltas{nanoseconds}) {
        $deltas{seconds} = ($deltas{seconds} || 0)
                         + (exists $deltas{nanoseconds} ? $deltas{nanoseconds} / 1E9 : 0);
    }
    my $str = $deltas{negative} ? "-P" : "P";
    $str .= "$deltas{years}Y" if exists $deltas{years};
    $str .= "$deltas{months}M" if exists $deltas{months};
    $str .= "$deltas{days}D" if exists $deltas{days};
    $str .= "T" if grep {exists $deltas{$_}} qw(hours minutes seconds);
    $str .= "$deltas{hours}H" if exists $deltas{hours};
    $str .= "$deltas{minutes}M" if exists $deltas{minutes};
    $str .= "$deltas{seconds}S" if exists $deltas{seconds};

    return $str;
}

1;

=head1 NAME

DateTime::Format::Duration::XSD

=head1 SYNOPSIS

  use DateTime::Format::Duration::XSD;
  my $dfdx = DateTime::Format::Duration::XSD->new();
  my $duration_object = $dfdx->parse_duration('-P1Y2M3DT1H2M3.33S');
  my $xsd_duration = $dfdx->format_duration($duration_object);

=head1 DESCRIPTION

DateTime::Format::Duration::XSD - Formats and parses DateTime::Duration
according to xs:duration

=head1 SEE ALSO

L<DateTime>, L<DateTime::Duration>, L<DateTime::Format::XSD>

The XML Schema speficitation

=head1 AUTHOR

Smal D A, E<lt>mialinx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Smal D A

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

