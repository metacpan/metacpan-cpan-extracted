package Astro::Montenbruck::RiseSet::RST;

use strict;
use warnings;
no warnings qw/experimental/;
use feature qw/switch/;

use Exporter qw/import/;
use Readonly;

use Math::Trig qw/:pi deg2rad rad2deg acos/;
use List::Util qw/any/;

use Astro::Montenbruck::Time::Sidereal qw/ramc/;
use Astro::Montenbruck::MathUtils qw/diff_angle reduce_deg reduce_rad/;
use Astro::Montenbruck::Time qw/cal2jd jd_cent $SEC_PER_DAY/;
use Astro::Montenbruck::Time::DeltaT qw/delta_t/;
use Astro::Montenbruck::CoCo qw/equ2hor/;
use Astro::Montenbruck::RiseSet::Constants qw/:events :states/;

our @EXPORT_OK = qw/rst_function/;
our $VERSION   = 0.01;

# Interpolate from three equally spaced tabular angular values.
#
# [Meeus-1998; equation 3.3]
#
# This version is suitable for interpolating from a table of
# angular values which may cross the origin of the circle,
# for example: 359 degrees...0 degrees...1 degree.
#
# Arguments:
#   - `n` : the interpolating factor, must be between -1 and 1
#   - `y` : a sequence of three values
#
# Results:
#   - the interpolated value of y

sub _interpolate_angle3 {
    my ( $n, $y ) = @_;
    die "interpolating factor $n out of range" unless ( -1 < $n ) && ( $n < 1 );

    my $a = diff_angle( $y->[0], $y->[1], 'radians' );
    my $b = diff_angle( $y->[1], $y->[2], 'radians' );
    my $c = diff_angle( $a,      $b,      'radians' );
    $y->[1] + $n / 2 * ( $a + $b + $n * $c );
}

# Interpolate from three equally spaced tabular values.
#
# [Meeus-1998; equation 3.3]
#
# Parameters:
#   - `n` : the interpolating factor, must be between -1 and 1
#   - `y` : a sequence of three values
#
# Results:
#   - the interpolated value of y
sub _interpolate3 {
    my ( $n, $y ) = @_;
    die "interpolating factor out of range $n" unless ( -1 < $n ) && ( $n < 1 );

    my $a = $y->[1] - $y->[0];
    my $b = $y->[2] - $y->[1];
    my $c = $b - $a;
    $y->[1] + $n / 2 * ( $a + $b + $n * $c );
}

sub rst_function {
    my %arg = @_;
    my ( $h, $phi, $lambda ) = map { deg2rad( $arg{$_} ) } qw/h phi lambda/;

    my $sin_h = sin($h);
    my $delta = $arg{delta} || 1 / 1440;
    my $jdm   = cal2jd( @{ $arg{date} } );
    my $gstm  = deg2rad( ramc( $jdm, 0 ) );
    my @equ   = map { [ $arg{get_position}->( $jdm + $_ ) ] } ( -1 .. 1 );
    my @alpha = map { $_->[0] } @equ;
    my @delta = map { $_->[1] } @equ;
    my $cos_h =
      ( $sin_h - sin($phi) * sin($delta[1]) ) / ( cos($phi) * cos($delta[1]) );
    my $dt = delta_t($jdm) / $SEC_PER_DAY;

    sub {
        my $evt = shift;    # $EVT_RISE, $EVT_SET or $EVT_TRANSIT
        die "Unknown event: $evt" unless any { $evt eq $_ } @RS_EVENTS;
        my %arg = ( max_iter => 50, @_ );

        if ( $cos_h < -1 ) {
            $arg{on_noevent}->($STATE_CIRCUMPOLAR);
            return;
        }
        elsif ( $cos_h > 1 ) {
            $arg{on_noevent}->($STATE_NEVER_RISES);
            return;
        }

        my $h0 = acos($cos_h);
        my $m0 = ( reduce_rad( $alpha[1] + $lambda - $gstm ) ) / pi2;
        my $m  = do {
            given ($evt) {
                $m0 when $EVT_TRANSIT;
                $m0 - $h0 / pi2 when $EVT_RISE;
                $m0 + $h0 / pi2 when $EVT_SET;
            }
        };
        if ( $m < 0 ) {
            $m++;
        }
        elsif ( $m > 1 ) {
            $m--;
        }
        die "m is out of range: $m" unless ( 0 <= $m ) && ( $m <= 1 );

        for ( 0 .. $arg{max_iter} ) {
            my $m0 = $m;
            my $theta0 =
              deg2rad( reduce_deg( rad2deg($gstm) + 360.985647 * $m ) );
            my $n  = $m + $dt;
            my $ra = _interpolate_angle3( $n, \@alpha );
            my $h1 = diff_angle( 0, $theta0 - $lambda - $ra, 'radians' );
            my $dm = do {
                given ($evt) {
                    -( $h1 / pi2 ) when $EVT_TRANSIT;
                    default {
                        my $de = _interpolate3( $n, \@delta );
                        my ( $az, $alt ) = map { deg2rad($_) }
                          equ2hor( map { rad2deg($_) } ( $h1, $de, $phi ) );
                        ( $alt - $h ) /
                          ( pi2 * cos($de) * cos($phi) * sin($h1) );
                    }
                }
            };
            $m += $dm;
            if ( abs( $m - $m0 ) < $delta ) {
                $arg{on_event}->( $jdm + $m );
                return;
            }
        }
        die 'bailout!';
      }
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::RiseSet::RST — rise, set, transit.

=head1 SYNOPSIS

    use Astro::Montenbruck::MathUtils qw/frac/;
    use Astro::Montenbruck::RiseSet::Constants qw/:events :altitudes/;
    use Astro::Montenbruck::RiseSet::RST qw/rst_function/;

    # create function for calculating Moon events for Munich, Germany, on March 23, 1989.
    my $func = rst_function(
        date     => [1989, 3, 23],
        phi    => 48.1,
        lambda => -11.6,
        get_position => sub {
            my $jd = shift;
            # return equatorial coordinates of the celestial body for the Julian Day.
        }
    );

    # calculate rise. Alternatively, use $EVT_SET for set, $EVT_TRANSIT for
    # transit as the first argument
    $func->(
        $EVT_RISE,
        on_event  => sub {
            my $jd = shift; # Standard Julian date of the event
            my $ut = frac(jd - 0.5) * 24; # UTC, 18.95 = 18h57m
        },
        on_noevent => sub {
            my $state = shift;
            say "The body is $state"
        }
    });


=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Low-level routines for calculating rise, set and transit times of celestial
bodies. The calculations are based on I<"Astronomical Algorythms" by Jean Meeus>.
The same subject is discussed in I<Montenbruck & Phleger>'s book, but Meeus's
method is more general and consistent. Unit tests use examples from the both sources.

The general problem here is to find the instant of time at which a celestial
body reaches a predetermined I<altitude>.


=head1 FUNCTIONS

=head2 rst_function( %args )

Returns function for calculating time of event. See L</EVENT FUNCTION> below.

=head3 Named Arguments

=over

=item * B<date> — array of B<year> (astronomical, zero-based), B<month> [1..12],
and B<day>, [1..31].

=item * B<phi> — geographical latitude, degrees, positive northward

=item * B<lambda> — geographical longitude, degrees, positive westward

=item * B<get_position> — function, which given I<Standard Julian Day>, returns
equatorial coordinates of the celestial body, in radians.


=item * B<h> — the I<standard altitude>, i.e. the geometric altitude of the
center of the body at the time of apparent rising or setting, degrees.

=back

=head2 EVENT FUNCTION

The event function, returned by L</rst_function( %args )>, calculates time of a
given event (rise, set or trasnsit).

    $func->( EVENT_TYPE, on_event => sub{ ... }, on_noevent => sub{ ... } );

Its first argument, I<event type>, is one of C<$EVT_RISE>, C<$EVT_SET>, or
C<$EVT_TRANSIT>, see L<Astro::Montenbruck::RiseSet::Constants/EVENTS>.

Named arguments are callback functions:

=over

=item * C<on_event> is called when the event time is determined. The argument is
I<Standard Julian day> of the event.

    on_event => sub { my $jd = shift; ... }

=item * C<on_noevent> is called when the event does not happen at the given date,
either because the body never rises, or is circumpolar. The argument is respectively
C<$STATE_NEVER_RISES> or C<$STATE_CIRCUMPOLAR>, see
L<Astro::Montenbruck::RiseSet::Constants/STATES>.

    on_noevent => sub { my $state = shift; ... }

=back

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2020 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
