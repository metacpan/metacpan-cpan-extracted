package DateTime::Format::Duration::ISO8601;

our $DATE = '2018-06-23'; # DATE
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    # Default error handler
    unless (exists $args{ on_error }) {
        $args{ on_error } = sub { die shift };
    }

    return bless \%args, $class;
}

sub format_duration {
    my ($self, $dtdur) = @_;

    unless (eval { $dtdur->isa('DateTime::Duration') }) {
        return $self->_error(sprintf
            '"%s": not a DateTime::Duration instance',
            $dtdur
        );
    }

    my ($y, $m, $w, $d, $H, $M, $S, $ns) = (
        $dtdur->years,
        $dtdur->months,
        $dtdur->weeks,
        $dtdur->days,
        $dtdur->hours,
        $dtdur->minutes,
        $dtdur->seconds,
        $dtdur->nanoseconds,
    );

    $S += $ns / 1_000_000_000;
    $d += $w * 7;

    my $has_date = $y || $m || $w || $d;
    my $has_time = $H || $M || $S;

    return "PT0H0M0S" if !$has_date && !$has_time;

    join(
        "",
        "P",
        ($y, "Y") x !!$y,
        ($m, "M") x !!$m,
        ($d, "D") x !!$d,
        (
            "T",
            ($H, "H") x !!$H,
            ($M, "M") x !!$M,
            ($S, "S") x !!$S,
        ) x !!$has_time,
    );
}

sub parse_duration {
    my ($self, $duration_string) = @_;

    my $duration_args = $self->parse_duration_as_deltas($duration_string);

    return unless defined $duration_args;

    if ($duration_args->{ repeats }) {
        return $self->_error(sprintf(
            '"%s": duration repetitions are not supported',
            $duration_string
        ));
    }

    # Convert weeks to days
    if (exists $duration_args->{ weeks }) {
        $duration_args->{days} += delete($duration_args->{weeks}) * 7;
    }

    # Convert ss.sss floating seconds to seconds and nanoseconds
    if (exists $duration_args->{ seconds }) {
        my ($seconds, $floating) = $duration_args->{ seconds } =~ qr{(?x)
            ([0-9]+)
            (\.[0-9]+)
        };

        if ($floating) {
            my $nanoseconds = $floating * 1_000_000_000;

            $duration_args->{ seconds } = $seconds;
            $duration_args->{ nanoseconds } = $nanoseconds;
        }
    }

    require DateTime::Duration;
    return DateTime::Duration->new(%{ $duration_args });
}

sub parse_duration_as_deltas {
    my ($self, $duration_string) = @_;

    unless (defined $duration_string) {
        return $self->_error('Duration string undefined');
    }

    my $regex = qr{(?x)
        ^
        (?:(?<repeats>R(?<repetitions>[0-9]+(?:\.[0-9]*)?)?))?
        P
        (?:
            # PnW
            (?:
                (?:(?<weeks>[0-9]+(?:\.[0-9]*)?)W)
            )
            |
            # PnYnMnDTnHnMnS & P<date>T<time>
            (?:
                (?:(?<years>[0-9]+(?:\.[0-9]*)?)Y)?
                (?:(?<months>[0-9]+(?:\.[0-9]*)?)M)?
                (?:(?<days>[0-9]+(?:\.[0-9]*)?)D)?
                (?:T
                    (?:(?<hours>[0-9]+(?:\.[0-9]*)?)H)?
                    (?:(?<minutes>[0-9]+(?:\.[0-9]*)?)M)?
                    (?:(?<seconds>[0-9]+(?:\.[0-9]*)?)S)?
                )?
            )
        )$
    };

    unless ($duration_string =~ $regex) {
        return $self->_error(sprintf(
            '"%s": not a valid ISO 8601 duration string',
            $duration_string
        ));
    }

    my %fields = map  { $_ => $+{ $_ } }
                 grep { defined $+{ $_ } }
                      keys %+;

    # XXX ISO standard only allows decimal fraction for the smallest unit

    return \%fields;
}

sub _error {
    my ($self, @args) = @_;

    die @args unless ref $self and ref $self->{ on_error } eq 'CODE';

    return $self->{ on_error }->(@args);
}

1;
# ABSTRACT: Parse and format ISO8601 duration

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Duration::ISO8601 - Parse and format ISO8601 duration

=head1 VERSION

This document describes version 0.008 of DateTime::Format::Duration::ISO8601 (from Perl distribution DateTime-Format-Duration-ISO8601), released on 2018-06-23.

=head1 SYNOPSIS

 use DateTime::Format::Duration::ISO8601;

 my $format = DateTime::Format::Duration::ISO8601->new;
 say $format->format_duration(
     DateTime::Duration->new(years=>3, months=>5, seconds=>10),
 ); # => P3Y5MT10S

 my $d = $format->parse_duration('P1Y1M1DT1H1M1S');
 say $d->in_units('minutes'); # => 61

=head1 DESCRIPTION

This module formats and parses ISO 8601 durations to and from
L<DateTime::Duration> instances.

ISO 8601 intervals are B<not> supported.

=head1 METHODS

=head2 new(C<%args>) => C<DateTime::Duration::Format::ISO8601>

=head3 Arguments

=over

=item * on_error (C<CODE>, optional)

Subroutine reference that will receive an error message if parsing fails.

The default implementation simply C<die>s with the message.

Set to C<undef> to disable error dispatching.

=back

=head2 format_duration (C<DateTime::Duration>) => C<string>

=head2 parse_duration (C<string>) => C<DateTime::Duration>

=head2 parse_duration_as_deltas(C<string>) => \%deltas

This is for parsing a duration string into hash, without creating
L<DateTime::Duration> object.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DateTime-Format-Duration-ISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DateTime-Format-Duration-ISO8601>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Format-Duration-ISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DateTime::Format::ISO8601> to parse ISO8601 date/time string into L<DateTime>
object. At the time of this writing, there is no support to parse and format
L<DateTime::Duration> object, hence this module you're reading. Also, there is
no support to format DateTime object as ISO8601 date/time string; for that
functionality use L<DateTime::Format::ISO8601::Format>.

L<DateTime::Format::Duration> to format DateTime::Duration object using
strftime-style formatting.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
