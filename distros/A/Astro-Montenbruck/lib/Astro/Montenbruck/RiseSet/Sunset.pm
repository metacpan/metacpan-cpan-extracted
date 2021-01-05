package Astro::Montenbruck::RiseSet::Sunset;

use strict;
use warnings;
no warnings qw/experimental/;
use feature qw/switch/;

use Exporter qw/import/;
use Readonly;

use Math::Trig qw/:pi deg2rad/;

use Astro::Montenbruck::Time qw/cal2jd jd_cent/;
use Astro::Montenbruck::Time::Sidereal qw/ramc/;
use Astro::Montenbruck::RiseSet::Constants qw/:events :states/;

our @EXPORT_OK = qw/riseset/;
our $VERSION   = 0.01;

sub _cs_phi {
    my $phi  = shift;
    my $rphi = deg2rad($phi);
    cos($rphi), sin($rphi);
}

# Finds a parabola through 3 points: (-1, $y_minus), (0, $y_0) and (1, $y_plus),
# that do not lie on straight line.
# Arguments:
# $y_minus, $y_0, $y_plus - three Y-values
# Returns:
# $nz - number of roots within the interval [-1, +1]
# $xe, $ye - X and Y of the extreme value of the parabola
# $zero1 - first root within [-1, +1] (for $nz = 1, 2)
# $zero2 - second root within [-1, +1] (only for $nz = 2)
sub _quad {
    my ( $y_minus, $y_0, $y_plus ) = @_;
    my $nz = 0;
    my $a  = 0.5 * ( $y_minus + $y_plus ) - $y_0;
    my $b  = 0.5 * ( $y_plus - $y_minus );
    my $c  = $y_0;

    my $xe  = -$b / ( 2 * $a );
    my $ye  = ( $a * $xe + $b ) * $xe + $c;
    my $dis = $b * $b - 4 * $a * $c;          # discriminant of y = axx+bx+c
    my @zeroes;
    if ( $dis >= 0 ) {

        # parabola intersects x-axis
        my $dx = 0.5 * sqrt($dis) / abs($a);
        @zeroes[ 0, 1 ] = ( $xe - $dx, $xe + $dx );
        $nz++ if abs( $zeroes[0] ) <= 1;
        $nz++ if abs( $zeroes[1] ) <= 1;
        $zeroes[0] = $zeroes[1] if $zeroes[0] < -1;
    }
    $nz, $xe, $ye, @zeroes;
}

# Calculates sine of the altitude at hourly intervals.
sub _sin_alt {
    my ( $jd, $lambda, $cphi, $sphi, $get_position ) = @_;
    my ( $ra, $de ) = $get_position->($jd);
    my $tau = deg2rad( ramc( $jd, $lambda ) ) - $ra;
    $sphi * sin($de) + $cphi * cos($de) * cos($tau);
}

sub riseset {
    my %arg = @_;
    my $jd0 = cal2jd( @{$arg{date}} );
    my ( $cphi, $sphi ) = _cs_phi($arg{phi});
    my $sin_alt = sub {
        my $hour = shift;
        _sin_alt( $jd0 + $hour / 24, $arg{lambda}, $cphi, $sphi, $arg{get_position} );
    };
    my $hour    = 1;
    my $y_minus = $sin_alt->( $hour - 1 ) - $arg{sin_h0};
    my $above   = $y_minus > 0;
    my ( $rise_found, $set_found ) = ( 0, 0 );

    # loop over search intervals from [0h-2h] to [22h-24h]
    do {
        my $y_0    = $sin_alt->($hour) - $arg{sin_h0};
        my $y_plus = $sin_alt->( $hour + 1 ) - $arg{sin_h0};

        # find parabola through three values $y_minus, $y_0, $y_plus
        my ( $nz, $xe, $ye, @zeroes ) = _quad( $y_minus, $y_0, $y_plus );
        given ($nz) {
            when (1) {
                if ( $y_minus < 0 ) {
                    $arg{on_event}->( $EVT_RISE, $hour + $zeroes[0] );
                    $rise_found = 1;
                }
                else {
                    $arg{on_event}->( $EVT_SET, $hour + $zeroes[0] );
                    $set_found = 1;
                }
            }
            when (2) {
                if ( $ye < 0 ) {
                    $arg{on_event}->( $EVT_RISE, $hour + $zeroes[1] );
                    $arg{on_event}->( $EVT_SET,  $hour + $zeroes[0] );
                }
                else {
                    $arg{on_event}->( $EVT_RISE, $hour + $zeroes[0] );
                    $arg{on_event}->( $EVT_SET,  $hour + $zeroes[1] );
                }
                ( $rise_found, $set_found ) = ( 1, 1 );
            }
        }

        # prepare for next interval
        $y_minus = $y_plus;
        $hour += 2;
    } until ( ( $hour == 25 ) || ( $rise_found && $set_found ) );

    $arg{on_noevent}->( $above ? $STATE_CIRCUMPOLAR : $STATE_NEVER_RISES)
        unless ( $rise_found || $set_found );
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
    use Astro::Montenbruck::RiseSet::Sunset qw/:riseset/;

    riseset(
        date     => [1989, 3, 23],
        phi    => 48.1,
        lambda => -11.6,
        get_position => sub {
            my $jd = shift;
            # return equatorial coordinates of the celestial body for the Julian Day.
        },
        sin_h0       => sin( deg2rad($H0_PLANET) ),
        on_event     => sub {
            my ($evt, $ut) = @_;
            say "$evt: $ut";
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
