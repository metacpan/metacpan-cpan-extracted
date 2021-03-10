package Astro::Montenbruck::RiseSet::Plarise;

use strict;
use warnings;
no warnings qw/experimental/;
use feature qw/switch/;

use Exporter qw/import/;
use Readonly;

use Math::Trig qw/:pi deg2rad rad2deg acos/;

use Astro::Montenbruck::MathUtils qw/to_range/;
use Astro::Montenbruck::Time qw/cal2jd jd_cent/;
use Astro::Montenbruck::Time::Sidereal qw/ramc/;
use Astro::Montenbruck::RiseSet::Constants qw/:events :states/;

our @EXPORT_OK = qw/rst_func/;
our $VERSION   = 0.01;

Readonly our $SID => 0.9972696; # Conversion sidereal/solar time 
Readonly our $ZT_MIN => 0.008;
Readonly our $MAX_COUNT => 10;

sub _cs_phi {
    my $phi  = shift;
    my $rphi = deg2rad($phi);
    cos($rphi), sin($rphi);
}



sub rst_func {
    my %arg = ( date => undef, phi => undef, lambda => undef, @_ );
    my $jd0 = cal2jd( @{ $arg{date} } );
    my $phi = $arg{phi};
    my ( $cphi, $sphi ) = _cs_phi( $phi );

    my $lst_0h = ramc( $jd0, $arg{lambda} ) / 15;
    

    sub {
        my %arg = (
            sin_h0 =>       undef, # sine of altitude correction
            get_position => undef, # function for calculation equatorial coordinates of the body
            @_
        );

        #  Compute geocentric planetary position at 0h and 24h local time
        my @ra;
        my @de;
        ($ra[$_], $de[$_]) = $arg{get_position}->($jd0 + $_) for (0..1);

        # Generate continuous right ascension values in case of jumps
        # between 0h and 24h
        $ra[1] += pi2 if $ra[0] - $ra[1] >  pi;
        $ra[0] += pi2 if $ra[0] - $ra[1] < -pi;
    
        sub {
            my $event = shift;

            my $zt;
            my $zt0 = 12.0; # Starting value 12h local time
            my $state = $event;
            for (my $i = 0; $i <= $MAX_COUNT; $i++) {
                # Linear interpolation of planetary position
                my $ra = $ra[0] + ($zt0 / 24) * ($ra[1] - $ra[0]);
                my $de = $de[0] + ($zt0 / 24) * ($de[1] - $de[0]);
                my $above = rad2deg($de) > 90 - $phi;

                # Compute semi-diurnal arc (in radans)
                my $sda = ($arg{sin_h0} - sin($de) * $sphi) / (cos($de) * $cphi);
                if (abs($sda) < 1) {
                    $sda = acos($sda);
                } elsif ($phi > 0) {
                    # Test for circumpolar motion or invisibility
                    $state = $above ? $STATE_CIRCUMPOLAR : $STATE_NEVER_RISES;
                    last;
                }
                my $lst = $lst_0h + $zt0 / $SID; # Sidereal time at univ. time ZT0
                my $h = $lst - rad2deg($ra) / 15;
                my $dtau = do {
                    given ($event) {
                        $h + rad2deg($sda) / 15 when $EVT_RISE;
                        $h                      when $EVT_TRANSIT;
                        $h - rad2deg($sda) / 15 when $EVT_SET;
                    }
                };
                my $dzt = $SID * (to_range($dtau + 12, 24) - 12);
                $zt0 -= $dzt;
                $zt = $zt0;
                last if abs($dzt) <= $ZT_MIN; 
            }

            return $state eq $event ? ($state, $jd0 + $zt / 24) 
                                    : ($state, undef)

        }

    }
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::RiseSet::Plarise — rise and set.

=head1 SYNOPSIS

    use Astro::Montenbruck::RiseSet::Constants qw/:events :altitudes/;
    use Astro::Montenbruck::RiseSet::Plarise qw/:rst_func/;

    # build top-level function for any event and any celestial object 
    # for given time and place
    my $rst_func = rst_func(
        date     => [1989, 3, 23],
        phi      => 48.1, # geographic latitude 
        lambda   => -11.6 # geographic longitude
    );

    # build second level functon for calculating any event for given object
    my $evt_func = $rst_func->(
        get_position => sub {
            my $jd = shift;
            # return equatorial coordinates of the celestial body for the Julian Day.
        },
        sin_h0       => sin( deg2rad($H0_PLANET) ),
    );

    # finally, calculate time of rise event. Alternatively, use $EVT_SET or $EVT_TRANSIT
    my ($state, $jd) = $evt_func->($EVT_RISE);


=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Low level routines for calculating rise and set times of celestial bodies. 
They are especially usefull for calculating different types of twilight. 

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
