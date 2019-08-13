package Astro::Montenbruck::RiseSet;

use strict;
use warnings;
no warnings qw/experimental/;
use feature qw/switch/;

use Exporter qw/import/;
use Readonly;
use Memoize;
memoize qw/_get_obliquity/;

use Math::Trig qw/:pi deg2rad/;
use Astro::Montenbruck::MathUtils qw/frac/;
use Astro::Montenbruck::Time qw/jd_cent/;
use Astro::Montenbruck::CoCo qw/ecl2equ/;
use Astro::Montenbruck::NutEqu qw/obliquity/;
use Astro::Montenbruck::Ephemeris qw/iterator/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids/;
use Astro::Montenbruck::RiseSet::Constants qw/:altitudes :twilight :states/;
use Astro::Montenbruck::RiseSet::RST qw/rst_function/;
use Astro::Montenbruck::RiseSet::Sunset qw/riseset/;

our %EXPORT_TAGS = (
    all => [ qw/rst_event twilight/ ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION   = 0.01;

Readonly::Array our @TWILIGHT_TYPES =>
    ($TWILIGHT_ASTRO, $TWILIGHT_NAUTICAL, $TWILIGHT_CIVIL);


sub _get_obliquity { obliquity( $_[0] ) }

sub _get_equatorial {
    my ( $id, $jd ) = @_;
    my $t    = jd_cent($jd);
    my $iter = iterator( $t, [$id] );
    my $res  = $iter->();
    my @ecl  = @{ $res->[1] }[ 0 .. 1 ];
    map { deg2rad($_) } ecl2equ( @ecl, _get_obliquity($t) );
}


sub twilight {
    my %arg = (type => $TWILIGHT_NAUTICAL, @_);
    my $type = delete $arg{type};
    die "Unknown twilight type: \"$type\"" unless exists $H0_TWL{$type};

    riseset(
        %arg,
        get_position => sub { _get_equatorial( $SU, $_[0] ) },
        sin_h0       => sin( deg2rad($H0_TWL{$type}) ),
    );
}

# Return the standard altitude of the Moon.
#
# Arguments:
#   - $r : Distance between the centers of the Earth and Moon, in km.
# Returns:
#   - Standard altitude in radians.
sub _moon_rs_alt {
    my ($y, $m, $d) = @_;
    $H0_MOO
}

sub rst_event {
    my %arg = @_;
    my $pla = delete $arg{planet};

    rst_function(
        h       => do {
            given( $pla ) {
                $H0_SUN when $SU;
                _moon_rs_alt(@{$arg{date}}) when $MO;
                default { $H0_PLA }
            }
        },
        get_position => sub {
            my $jd = shift;
            _get_equatorial( $pla, $jd )
        },
        %arg
    )
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::RiseSet — rise, set, transit.

=head1 SYNOPSIS

    use Astro::Montenbruck::Ephemeris::Planet qw/:ids/;
    use Astro::Montenbruck::MathUtils qw/frac/;
    use Astro::Montenbruck::RiseSet::Constants qw/:all/;
    use Astro::Montenbruck::RiseSet' qw/:all/;

    # create function for calculating Moon events for Munich, Germany, on March 23, 1989.
    my $func = rst_event(
        planet => $MO,
        date   => [1989, 3, 23],
        phi    => 48.1,
        lambda => -11.6
    );

    # calculate Moon rise. Alternatively, use $EVT_SET for set, $EVT_TRANSIT for
    # transit as the first argument
    $func->(
        $EVT_RISE,
        on_event => sub {
            my $jd = shift; # Standard Julian date
            my $ut = frac(jd - 0.5) * 24; # UTC, 18.95 = 18h57m
        }
    );

    # calculate civil twilight
    twilight(
        date       => [1989, 3, 23],
        phi        => 48.1,
        lambda     => -11.6,
        on_event   => sub {
            my ($evt, $ut) = @_;
            say "$evt: $ut";
        },
        on_noevent => sub {
            my $state = shift;
            say $state;
        }
    );

=head1 VERSION

Version 0.01


=head1 DESCRIPTION

High level interface for calculating rise, set and transit times of celestial
bodies, as well as twilight of different types.

To take into account I<parallax>, I<refraction> and I<apparent radius> of the
bodies, we use average corrections to geometric altitudes:

=over

=item * sunrise, sunset : B<-0°50'>

=item * moonrise, moonset : B<0°8'>

=item * stars and planets : B<-0°34'>

=back

=head2 TWILIGHT

The library also calculates the times of the beginning of the morning twilight
(I<dawn>) and end of the evening twilight (I<dusk>).

Twilight occurs when Earth's upper atmosphere scatters and reflects sunlight
which illuminates the lower atmosphere. Astronomers define the three stages of
twilight – I<civil>, I<nautical>, and I<astronomical> – on the basis of the Sun's
elevation which is the angle that the geometric center of the Sun makes with the
horizon.

=over

=item * I<astronomical>

Sun altitude is B<-18°> In the morning, the sky is completely dark before the
onset of astronomical twilight, and in the evening, the sky becomes completely
dark at the end of astronomical twilight. Any celestial bodies that can be
viewed by the naked eye can be observed in the sky after the end of this phase.

=item * I<nautical>

Sun altitude is B<-12°>. This twilight period is less bright than civil twilight
and artificial light is generally required for outdoor activities.

=item * I<civil>

Sun altitude is B<-6°>. Civil twilight is the brightest form of twilight.
There is enough natural sunlight during this period that artificial light may
not be required to carry out outdoor activities. Only the brightest celestial
objects can be observed by the naked eye during this time.

=back

=head1 EXPORT

=head2 FUNCTIONS

=over

=item * L</rst_event( %args )>

=item * L</twilight( %args )>

=back

=head1 FUNCTIONS

=head2 rst_event( %args )

Returns function for calculating time of event. See
L<Astro::Montenbruck::RiseSet::RST/EVENT FUNCTION> .

=head3 Named Arguments

=over

=item * B<planet> — celestial body identifier, one of constants defined in
L<Astro::Montenbruck::Ephemeris::Planet>.

=item * B<date> — array of B<year> (astronomical, zero-based), B<month> [1..12]
and B<day>, [1..31].

=item * B<phi> — geographical latitude, degrees, positive northward

=item * B<lambda> — geographical longitude, degrees, positive westward

=back


=head2 twilight( %args )

Function for calculating twilight. See L</TWILIGHT EVENT FUNCTION> below.

=head3 Named Arguments

=over

=item * B<type> — type of twilight, C<$TWILIGHT_NAUTICAL>, C<$TWILIGHT_ASTRO>
or C<$TWILIGHT_CIVIL>, see L<Astro::Montenbruck::RiseSet::Constants/TYPES OF TWILIGHT>.

=item * B<date> — array of B<year> (astronomical, zero-based), B<month> [1..12] and B<day>, [1..31].

=item * B<phi> — geographical latitude, degrees, positive northward

=item * B<lambda> — geographical longitude, degrees, positive westward

=item * B<on_event> — callback called when the event time is determined. The arguments are:

=over

=item * Event type, one of C<$EVT_RISE> or C<$EVT_SET>,
L<Astro::Montenbruck::RiseSet::Constants/EVENTS>. The first indicates I<dawn>,
the second — I<dusk>.

=item * Time of the event, UTC.

=back

=item * B<on_noevent> is called when the event never happens, either because the body
never rises, or is circumpolar. The argument is respectively
C<$STATE_NEVER_RISES> or C<$STATE_CIRCUMPOLAR>, see
L<Astro::Montenbruck::RiseSet::Constants/STATES>.

=back

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
