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
use Astro::Montenbruck::RiseSet::Constants
  qw/:altitudes :twilight :events :states/;
use Astro::Montenbruck::RiseSet::Plarise qw/rst_func/;
use Astro::Montenbruck::RiseSet::Sunset qw/riseset_func/;

our %EXPORT_TAGS = ( all => [qw/rst riseset twilight/], );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION     = 0.02;

Readonly::Array our @TWILIGHT_TYPES =>
  ( $TWILIGHT_ASTRO, $TWILIGHT_NAUTICAL, $TWILIGHT_CIVIL );

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
    my %arg = (
        type       => $TWILIGHT_NAUTICAL,
        on_event   => sub { },
        on_noevent => sub { },
        @_
    );
    my $type = delete $arg{type};
    die "Unknown twilight type: \"$type\"" unless exists $H0_TWL{$type};
    my $on_event   = delete $arg{on_event};
    my $on_noevent = delete $arg{on_noevent};

    if (wantarray) {
        my %res;
        riseset_func(%arg)->(
            on_event => sub {
                my ( $evt, $jd ) = @_;
                $res{$evt} = $jd;
                $on_event->(@_);
            },
            on_noevent => sub {
                $on_noevent->(@_);
            },
            %arg,
            get_position => sub { _get_equatorial( $SU, $_[0] ) },
            sin_h0       => sin( deg2rad( $H0_TWL{$type} ) ),
        );
        return %res;
    }

    riseset_func(%arg)->(
        %arg,
        get_position => sub { _get_equatorial( $SU, $_[0] ) },
        sin_h0       => sin( deg2rad( $H0_TWL{$type} ) ),
        on_event     => $on_event,
        on_noevent   => $on_noevent
    );
}

sub riseset {
    my %arg = @_;
    my $pla = delete $arg{planet};
    my $h0  = do {
        given ($pla) {
            $H0_SUN when $SU;
            $H0_MOO when $MO;
            default { $H0_PLA }
        }
    };
    my $func = riseset_func(%arg);
    sub {
        my %arg = ( on_event => sub { }, on_noevent => sub { }, @_ );

        if (wantarray) {

            # if caller asks for a result, collect events to %res hash
            my %res;
            $func->(
                get_position => sub { _get_equatorial( $pla, $_[0] ) },
                sin_h0       => sin( deg2rad($h0) ),
                on_event     => sub {
                    my ( $evt, $jd ) = @_;
                    $arg{on_event}->(@_);
                    $res{$evt} = { ok => 1, jd => $jd };
                },
                on_noevent => sub {
                    my ($state) = shift;
                    $arg{on_noevent}->(@_);
                    my $evt =
                      $state eq $STATE_NEVER_RISES ? $EVT_RISE : $EVT_SET;
                    $res{$evt} = { ok => 0, state => $state };
                }
            );
            return %res;
        }

 # if caller doesn't ask for a result, just call the function with the callbacks
        $func->(
            get_position => sub { _get_equatorial( $pla, $_[0] ) },
            sin_h0       => sin( deg2rad($h0) ),
            on_event     => $arg{on_event},
            on_noevent   => $arg{on_noevent},
        );
    }
}

sub rst {

    # build top-level function for any event and any celestial object
    # for given time and place
    my $rst = rst_func(@_);

    sub {
        my $obj = shift;
        my %arg = ( on_event => sub { }, on_noevent => sub { }, @_ );

        my $h0 = do {
            given ($obj) {
                $H0_SUN when $SU;
                $H0_MOO when $MO;
                default { $H0_PLA }
            }
        };

        # build second level functon for calculating any event for given object
        my $evt_func = $rst->(
            get_position => sub { _get_equatorial( $obj, $_[0] ) },
            sin_h0       => sin( deg2rad($h0) )
        );

        if (wantarray) {

            # if caller asks for a result, collect events to %res hash
            my %res;
            for (@RS_EVENTS) {
                my ( $state, $jd ) = $evt_func->($_);
                if ( $state eq $_ ) {
                    $arg{on_event}->( $_, $jd );
                    $res{$_} = { ok => 1, jd => $jd };
                }
                else {
                    $arg{on_noevent}->( $_, $state );
                    $res{$_} = { ok => 0, state => $state };
                }
            }
            return %res;
        }

 # if caller doesn't ask for a result, just call the function with the callbacks
        for (@RS_EVENTS) {
            my ( $state, $jd ) = $evt_func->($_);
            if ( $state eq $_ ) {
                $arg{on_event}->( $_, $jd );
            }
            else {
                $arg{on_noevent}->( $_, $state );
            }
        }
    }
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::RiseSet - rise, set, transit.

=head1 SYNOPSIS

    use Astro::Montenbruck::Ephemeris::Planet qw/:ids/;
    use Astro::Montenbruck::MathUtils qw/frac/;
    use Astro::Montenbruck::RiseSet::Constants qw/:all/;
    use Astro::Montenbruck::RiseSet qw/:all/;

    # create function for calculating rise/set/transit events for Munich, Germany, on March 23, 1989.
    my $func = rst(
        date   => [1989, 3, 23],
        phi    => 48.1,
        lambda => -11.6
    );

    # calculate Moon rise, set and transit
    $func->(
        $MO,
        on_event   => sub {
            my ($evt, $jd) = @_;
            say "$evt: $jd";
        },
        on_noevent => sub {
            my ($evt, $state) = @_; # $STATE_CIRCUMPOLAR or $STATE_NEVER_RISES
            say "$evt: $state";
        }        
    );

    # alternatively, call the function in list context:
    my %res = $func->($MO); # result structure is described below

    # calculate civil twilight    
    twilight(
        date       => [1989, 3, 23],
        phi        => 48.1,
        lambda     => -11.6,
        on_event   => sub {
            my ($evt, $jd) = @_;
            say "$evt: $jd";
        },
        on_noevent => sub {
            my $state = shift;
            say $state;
        }
    );


=head1 VERSION

Version 0.02

=head1 DESCRIPTION

High level interface for calculating rise, set and transit times of celestial
bodies, as well as twilight of different types.

There are two low-level functions for calculating the events, based on based on different algorithms:

=over

=item 1.

L<Astro::Montenbruck::RiseSet::Plarise::rst>, which calculates rise, set and transit times using I<iterative method>.

=item 2.

L<Astro::Montenbruck::RiseSet::Sunset::riseset_func>, which calculates rise and set times using I<quadratic interpolation>.

=back

Both of them are described in I<"Astronomy On The Personal Computer"> by O.Montenbruck and T.Phleger.
However, they are built on different algorithms: B<riseset_func> utilizes quadratic interpolation 
while B<rst> is iterative. Along with rise and set, B<rst> gives transit times. At the other hand, 
B<riseset_func> is a base for calculating twilight.

To take into account I<parallax>, I<refraction> and I<apparent radius> of the
bodies, we use average corrections to geometric altitudes:

=over

=item * sunrise, sunset : B<-0 deg 50 min>

=item * moonrise, moonset : B<0 deg 8 min>

=item * stars and planets : B<-0 deg 34 min>

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

Sun altitude is B<-18 deg> In the morning, the sky is completely dark before the
onset of astronomical twilight, and in the evening, the sky becomes completely
dark at the end of astronomical twilight. Any celestial bodies that can be
viewed by the naked eye can be observed in the sky after the end of this phase.

=item * I<nautical>

Sun altitude is B<-12 deg>. This twilight period is less bright than civil twilight
and artificial light is generally required for outdoor activities.

=item * I<civil>

Sun altitude is B<-6 deg>. Civil twilight is the brightest form of twilight.
There is enough natural sunlight during this period that artificial light may
not be required to carry out outdoor activities. Only the brightest celestial
objects can be observed by the naked eye during this time.

=back

=head1 CAVEATS

Sometimes rise and set happen on different calendar dates. For example, here is the output of C<riseset.pl>
script:

  $ perl .\script\riseset.pl --date=1989-03-28 --place=48.1 -11.6 --timezone=UTC

  Date      :  1989-03-28 UTC
  Place     :  48N06, 011E35
  Time Zone :  UTC

          rise       transit    set     
  Moon    23:34:17   03:23:59   07:10:54

This directly depends on time zone. Since event time is always given as Julian date,
it is not hard to determine correct order of events. 

=head1 EXPORT

=head2 FUNCTIONS

=over

=item * L</rst( %args )>

=item * L</riseset( %args )>

=item * L</twilight( %args )>

=back

=head1 FUNCTIONS


=head2 rst( %args )

Returns function for calculating times of rises, sets and transits of celestial bodies. See
L<Astro::Montenbruck::RiseSet::Plarise/rst> .

=head3 Named Arguments

=over

=item * 

B<date> - array of B<year> (astronomical, zero-based), B<month> [1..12] and B<day>, [1..31].

=item * 

B<phi> - geographical latitude, degrees, positive northward

=item * 

B<lambda> - geographical longitude, degrees, positive westward

=back

=head3 Returns

function, which calculates rise, set and transit for a celestial body. 
It accepts celestial body identifier as positional argument (see L<Astro::Montenbruck::Ephemeris::Planet>)
and two optional callbacks as named arguments: 

=over

=item * 

B<on_event($event, $jd> - callback called when the event time is determined. The first argument
is one of: C<$EVT_RISE>, C<$EVT_SET> or C<$EVT_TRANSIT> constants (see L<Astro::Montenbruck::RiseSet::Constants>),
the second - I<Standard Julian Date>.

=item * 

B<on_noevent($event, $state> - callback called when the body is I<circumpolar> or I<never rises>. 
The first argument is then one of: C<$EVT_RISE>, C<$EVT_SET> or C<$EVT_TRANSIT>, the second - either 
C<$STATE_CIRCUMPOLAR> or C<$STATE_NEVER_RISES>.

=back


=head4 List context

When called in list context:
  
  my %res = func();

the function returns a hash:
  
  (
      rise    => $hashref,
      set     => $hashref,
      transit => $hashref  
  )
  
When rise or set takes place, C<$hashref> contains:

  {ok => 1, jd => JD} 

JD is a Standard Julian Date. Otherwise, 
  
  {ok => 0, state => STATE}

STATE is C<$STATE_CIRCUMPOLAR> or C<$STATE_NEVER_RISES>.


=head2 riseset( %args )

Returns function for calculating times of rises and sets of given celestial body. See
L<Astro::Montenbruck::RiseSet::Sunset/riseset_func>.

=head3 Named Arguments

=over

=item * 

B<planet> - celestial body identifier (see L<Astro::Montenbruck::Ephemeris::Planet>)

=item * 

B<date> - array of B<year> (astronomical, zero-based), B<month> [1..12] and B<day>, [1..31].

=item * 

B<phi> - geographical latitude, degrees, positive northward

=item * 

B<lambda> - geographical longitude, degrees, positive westward

=back

=head3 Returns

function, which calculates rise and set times of the planet. It accepts and two callbacks as named arguments: 

=over

=item * 

B<on_event($event, $jd>) 
callback called when the event time is determined. The first argument
is one of: C<$EVT_RISE>, C<$EVT_SET> or C<$EVT_TRANSIT> constants (see L<Astro::Montenbruck::RiseSet::Constants>),
the second - I<Standard Julian Date>.

=item * 

B<on_noevent($state>
callback called when the body is I<circumpolar> or I<never rises>. 
The argument is either C<$STATE_CIRCUMPOLAR> or C<$STATE_NEVER_RISES>.

=back

When called in list context, returns a hash, described in L<rst( %args )/List context>, except
that C<transit> key is missing.

=head2 twilight( %args )

Function for calculating twilight. See L</TWILIGHT EVENT FUNCTION> below.

=head3 Named Arguments

=over

=item * 

B<type> - type of twilight, C<$TWILIGHT_NAUTICAL>, C<$TWILIGHT_ASTRO>
or C<$TWILIGHT_CIVIL>, see L<Astro::Montenbruck::RiseSet::Constants/TYPES OF TWILIGHT>.

=item * 

B<date> - array of B<year> (astronomical, zero-based), B<month> [1..12] and B<day>, [1..31].

=item * 

B<phi> - geographical latitude, degrees, positive northward

=item * 

B<lambda> - geographical longitude, degrees, positive westward

=item * 

B<on_event> - callback called when the event time is determined. The arguments are:

=over

=item * 

Event type, one of C<$EVT_RISE> or C<$EVT_SET>, L<Astro::Montenbruck::RiseSet::Constants/EVENTS>. 
The first indicates I<dawn>, the second - I<dusk>.

=item * 

time of the event, I<Standard Julian date>.

=back

=item * 

B<on_noevent> is called when the event never happens, either because the body never rises, 
or is circumpolar. The argument is respectively C<$STATE_NEVER_RISES> or C<$STATE_CIRCUMPOLAR>, 
see L<Astro::Montenbruck::RiseSet::Constants/STATES>.

=back


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2021 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
