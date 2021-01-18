package Astro::Montenbruck::RiseSet::Sunset;

use strict;
use warnings;
no warnings qw/experimental/;
use feature qw/switch/;

use Exporter qw/import/;
use Readonly;

use Math::Trig qw/:pi deg2rad/;

use Astro::Montenbruck::MathUtils qw/quad/;
use Astro::Montenbruck::Time qw/cal2jd jd_cent/;
use Astro::Montenbruck::Time::Sidereal qw/ramc/;
use Astro::Montenbruck::RiseSet::Constants qw/:events :states/;

our @EXPORT_OK = qw/riseset_func/;
our $VERSION   = 0.02;

sub _cs_phi {
    my $phi  = shift;
    my $rphi = deg2rad($phi);
    cos($rphi), sin($rphi);
}

# Calculates sine of the altitude at hourly intervals.
sub _sin_alt {
    my ( $jd, $lambda, $cphi, $sphi, $get_position ) = @_;
    my ( $ra, $de ) = $get_position->($jd);

    # hour angle
    my $tau = deg2rad( ramc( $jd, $lambda ) ) - $ra;
    $sphi * sin($de) + $cphi * cos($de) * cos($tau);
}

sub riseset_func {
    my %arg = ( date => undef, phi => undef, lambda => undef, @_ );
    my $jd0 = cal2jd( @{ $arg{date} } );
    my ( $cphi, $sphi ) = _cs_phi( $arg{phi} );

    my $sin_alt = sub {
        my ( $hour, $get_position ) = @_;
        _sin_alt( $jd0 + $hour / 24, $arg{lambda}, $cphi, $sphi,
            $get_position );
    };

    sub {
        # h0 = altitude corection
        my %arg = (
            sin_h0 => undef,          # sine of altitude correction
            get_position =>
              undef
            ,    # function for calculation equatorial coordinates of the body
            on_event   => sub { },    # callback for rise/set event
            on_noevent => sub { },    # callback when an event is missing
            @_
        );

        my $get_coords = $arg{get_position};
        my $sin_h0     = $arg{sin_h0};
        my $on_event   = $arg{on_event};

        my $hour    = 1;
        my $y_minus = $sin_alt->( $hour - 1, $get_coords ) - $sin_h0;
        my $above   = $y_minus > 0;
        my ( $rise_found, $set_found ) = ( 0, 0 );

        my $jd_with_hour = sub { $jd0 + $_[0] / 24 };

        # loop over search intervals from [0h-2h] to [22h-24h]
        do {
            my $y_0    = $sin_alt->( $hour,     $get_coords ) - $sin_h0;
            my $y_plus = $sin_alt->( $hour + 1, $get_coords ) - $sin_h0;

            # find parabola through three values $y_minus, $y_0, $y_plus
            my ( $nz, $xe, $ye, @zeroes ) = quad( $y_minus, $y_0, $y_plus );
            given ($nz) {
                when (1) {
                    if ( $y_minus < 0 ) {
                        $on_event->(
                            $EVT_RISE, $jd_with_hour->( $hour + $zeroes[0] )
                        );
                        $rise_found = 1;
                    }
                    else {
                        $on_event->(
                            $EVT_SET, $jd_with_hour->( $hour + $zeroes[0] )
                        );
                        $set_found = 1;
                    }
                }
                when (2) {
                    if ( $ye < 0 ) {
                        $on_event->(
                            $EVT_RISE, $jd_with_hour->( $hour + $zeroes[1] )
                        );
                        $on_event->(
                            $EVT_SET, $jd_with_hour->( $hour + $zeroes[0] )
                        );
                    }
                    else {
                        $on_event->(
                            $EVT_RISE, $jd_with_hour->( $hour + $zeroes[0] )
                        );
                        $on_event->(
                            $EVT_SET, $jd_with_hour->( $hour + $zeroes[1] )
                        );
                    }
                    ( $rise_found, $set_found ) = ( 1, 1 );
                }
            }

            # prepare for next interval
            $y_minus = $y_plus;
            $hour += 2;
        } until ( ( $hour == 25 ) || ( $rise_found && $set_found ) );

        $arg{on_noevent}->( $above ? $STATE_CIRCUMPOLAR : $STATE_NEVER_RISES )
          unless ( $rise_found || $set_found );
    }
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::RiseSet::Sunset — rise and set.

=head1 SYNOPSIS

    use Astro::Montenbruck::MathUtils qw/frac/;
    use Astro::Montenbruck::RiseSet::Constants qw/:events :altitudes/;
    use Astro::Montenbruck::RiseSet::Sunset qw/:riseset_func/;

    my $func = riseset_func(
        date     => [1989, 3, 23],
        phi    => 48.1,
        lambda => -11.6
    );

    $func->(
        get_position => sub {
            my $jd = shift;
            # return equatorial coordinates of the celestial body for the Julian Day.
        },
        sin_h0       => sin( deg2rad($H0_PLANET) ),
        on_event     => sub {
            my ($evt, $jd) = @_;
            say "$evt: $jd";
        },
        on_noevent   => sub {
            my $state = shift;
            say $state;
        }
    );

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Low level routines for calculating rise and set times of celestial bodies. Unlike
L<Astro::Montenbruck::RiseSet::RST> module, they are based on algorithms from the
I<Montenbruck & Phleger> book. They are especially usefull for calculating
different types of twilight. Meeus's method is unsuitable for calculating
I<astronomical twilight>.

=head1 FUNCTIONS

=head2 riseset ( %args )

time of rise and set events.

=head3 Named Arguments

=over

=item * B<get_position> — function, which given I<Standard Julian Day>,
returns equatorial coordinates of the celestial body, in radians.

=item * B<date> — array of B<year> (astronomical, zero-based), B<month> [1..12]
and B<day>, [1..31].


=item * B<phi> — geographic latitude, degrees, positive northward

=item * B<lambda> —geographic longitude, degrees, positive westward

=item * B<get_position> — function, which given I<Standard Julian Day>,
returns equatorial coordinates of the celestial body, in radians.

=item * B<sin_h0> — sine of the I<standard altitude>, i.e. the geometric altitude
of the center of the body at the time of apparent rising or setting.


=item * C<on_event> callback is called when the event time is determined.
The arguments are:

=over

=item * event type, one of C<$EVT_RISE> or C<$EVT_SET>

=item * Univerrsal time of the event

=back

    on_event => sub { my ($evt, $ut) = @_; ... }

=item * C<on_noevent> is called when the event does not happen at the given date,
either because the body never rises, or is circumpolar. The argument is respectively
C<$STATE_NEVER_RISES> or C<$STATE_CIRCUMPOLAR>.

    on_noevent => sub { my $state = shift; ... }

=back

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2021 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
