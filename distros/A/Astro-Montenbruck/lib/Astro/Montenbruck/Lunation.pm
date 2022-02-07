package Astro::Montenbruck::Lunation;

use strict;
use warnings;

use Exporter qw/import/;
use Readonly;
use Math::Trig qw/deg2rad rad2deg/;
use POSIX qw /floor/;

use Astro::Montenbruck::Time qw/cal2jd jd2cal $J1900/;
use Astro::Montenbruck::MathUtils qw/reduce_deg diff_angle/;

Readonly our $NEW_MOON      => 'New Moon';
Readonly our $FIRST_QUARTER => 'First Quarter';
Readonly our $FULL_MOON     => 'Full Moon';
Readonly our $LAST_QUARTER  => 'Last Quarter';
Readonly our $WAXING_CRESCENT => 'Waxing Crescent';
Readonly our $WAXING_GIBBOUS => 'Waxing Gibbous';
Readonly our $WANING_GIBBOUS => 'Waning Gibbous';
Readonly our $WANING_CRESCENT => 'Waning Crescent';

Readonly our @PHASES =>  
    qw/$NEW_MOON $WAXING_CRESCENT $FIRST_QUARTER $WAXING_GIBBOUS 
       $FULL_MOON $WANING_GIBBOUS $LAST_QUARTER $WANING_CRESCENT/;

my @funcs = qw/mean_phase search_event lunar_month moon_phase/;

our %EXPORT_TAGS = (
    phases    => \@PHASES,
    functions => \@funcs,
    all       => [ @PHASES, @funcs ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION   = 1.00;

Readonly::Hash our %COEFFS => (
    $NEW_MOON      => 0.0,
    $FIRST_QUARTER => 0.25,
    $FULL_MOON     => 0.5,
    $LAST_QUARTER  => 0.75
);

sub mean_phase {
    my ( $frac, $ye, $mo, $da ) = @_;
    my $j1 = cal2jd( $ye,     $mo, $da );
    my $j0 = cal2jd( $ye - 1, 12,  31.5 );

    my $k1 = ( $ye - 1900 + ( ( $j1 - $j0 ) / 365 ) ) * 12.3685;
    int( $k1 + 0.5 ) + $frac;
}

# Calculates delta for Full and New Moon.
sub nf_delta {
    my ( $t, $ms, $mm, $tms, $tmm, $tf ) = @_;

    ( 1.734e-1 - 3.93e-4 * $t ) * sin($ms)
        + 2.1e-3 * sin($tms)
        - 4.068e-1 * sin($mm)
        + 1.61e-2 * sin($tmm)
        - 4e-4 * sin( $mm + $tmm )
        + 1.04e-2 * sin($tf)
        - 5.1e-3 * sin( $ms + $mm )
        - 7.4e-3 * sin( $ms - $mm )
        + 4e-4 * sin( $tf + $ms )
        - 4e-4 * sin( $tf - $ms )
        - 6e-4 * sin( $tf + $mm )
        + 1e-3 * sin( $tf - $mm )
        + 5e-4 * sin( $ms + $tmm );
}

# Calculates delta for First ans Last quarters .
sub fl_delta {
    my ( $t, $ms, $mm, $tms, $tmm, $tf ) = @_;

    ( 0.1721 - 0.0004 * $t ) * sin($ms)
        + 0.0021 * sin($tms)
        - 0.6280 * sin($mm)
        + 0.0089 * sin($tmm)
        - 0.0004 * sin( $tmm + $mm )
        + 0.0079 * sin($tf)
        - 0.0119 * sin( $ms + $mm )
        - 0.0047 * sin( $ms - $mm )
        + 0.0003 * sin( $tf + $ms )
        - 0.0004 * sin( $tf - $ms )
        - 0.0006 * sin( $tf + $mm )
        + 0.0021 * sin( $tf - $mm )
        + 0.0003 * sin( $ms + $tmm )
        + 0.0004 * sin( $ms - $tmm )
        - 0.0003 * sin( $tms + $mm );
}

sub search_event {
    my ( $date, $quarter ) = @_;
    my ( $ye, $mo, $da ) = @$date;

    my $k = mean_phase( $COEFFS{$quarter}, @$date );

    my $t1 = $k / 1236.85;
    my $t2 = $t1 * $t1;
    my $t3 = $t2 * $t1;

    my $c = deg2rad( 166.56 + ( 132.87 - 9.173e-3 * $t1 ) * $t1 );

    # time of the mean phase
    my $j
        = 0.75933 + 29.53058868 * $k
        + 0.0001178 * $t2
        - 1.55e-07 * $t3
        + 3.3e-4 * sin($c);

    my $assemble = sub {
        deg2rad(
            reduce_deg( $_[0] + $_[1] * $k + $_[2] * $t2 + $_[3] * $t3 ) );
    };

    my $ms = $assemble->( 359.2242, 29.105356080, -0.0000333, -0.00000347 );
    my $mm = $assemble->( 306.0253, 385.81691806, 0.0107306,  0.00001236 );
    my $f  = $assemble->( 21.2964,  390.67050646, -0.0016528, -0.00000239 );
    my $delta = do {
        my $tms = $ms + $ms;
        my $tmm = $mm + $mm;
        my $tf  = $f + $f;
        if ( $quarter eq $NEW_MOON || $quarter eq $FULL_MOON ) {
            nf_delta( $t1, $ms, $mm, $tms, $tmm, $tf );
        }
        else {
            my $w = 0.0028 - 0.0004 * cos($ms) + 0.0003 * cos($ms);
            $w = -$w if $quarter eq $LAST_QUARTER;
            fl_delta( $t1, $ms, $mm, $tms, $tmm, $tf ) + $w;
        }
    };
    $j += $delta + $J1900;
    wantarray() ? ($j, rad2deg($f))
                : $j

}

sub _find_quarter {
    my ( $q, $y, $m, $d ) = @_;
    my $j = search_event( [ $y, $m, floor($d) ], $q );
    { type => $q, jd => $j };
}

sub _find_newmoon {
    my $ye  = shift;
    my $mo  = shift;
    my $da  = shift;
    my %arg = ( find_next => sub { }, step => 28, @_ );

    # find New Moon closest to the date
    my $data = _find_quarter( $NEW_MOON, $ye, $mo, $da );
    if ( $arg{find_next}->( $data->{jd} ) ) {
        my ( $y, $m, $d ) = jd2cal( $data->{jd} + $arg{step} );
        return _find_newmoon( $y, $m, $d, %arg );
    }
    $data;
}

sub lunar_month {
    my $jd = shift;
    my ( $ye, $mo, $da ) = jd2cal($jd);
    my $head = _find_newmoon(
        $ye, $mo, $da,
        find_next => sub { $_[0] > $jd },
        step      => -28
    );
    my $tail = _find_newmoon(
        $ye, $mo, $da,
        find_next => sub { $_[0] < $jd },
        step      => 28
    );
    my ( $y, $m, $d ) = jd2cal $head->{jd};
    my @trunc = map { _find_quarter( $_, $y, $m, $d ) }
        ( $FIRST_QUARTER, $FULL_MOON, $LAST_QUARTER );

    my $pre;
    map {
        my $cur = $_;
        $cur->{current} = 0;
        if ( defined $pre ) {
            $pre->{current} = $jd >= $pre->{jd} && $jd < $cur->{jd} ? 1 : 0; 
        }
        $pre = $cur;
    } ( $head, @trunc, $tail );
}

sub moon_phase {
    my %arg = (sun => undef, moon => undef, @_);
    my $d = reduce_deg(diff_angle($arg{sun}, $arg{moon})); # age in degrees
    my $days = $d / 12.1907;
    my $get_phase = sub {
        return $NEW_MOON if $d >= 0 && $d < 45;
        return $WAXING_CRESCENT if $d >= 45 && $d < 90;
        return $FIRST_QUARTER if $d >= 90 && $d < 135;
        return $WAXING_GIBBOUS if $d >= 135 && $d < 180;
        return $FULL_MOON if $d >= 180 && $d < 225;
        return $WANING_GIBBOUS if $d >= 225 && $d < 270;
        return $LAST_QUARTER if $d >= 270 && $d < 315;
        return $WANING_CRESCENT if $d >= 315 && $d < 360;
    };
    my $phase = $get_phase->();
    return wantarray() ? ($phase, $d, $days) : $phase 
}



1;
__END__


=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Lunation - Lunar quarters.

=head1 SYNOPSIS

  use Astro::Montenbruck::Lunation qw/:all/;

  # find instant of New Moon closest to 2019 Aug, 12
  $jd = search_event([2019, 8, 12], $NEW_MOON);
  # returns 2458696.63397517

  # find, which lunar phase corresponds to Moon longitude of 9.926
  # and Sun longitude of 316.527
  $phase = lunar_phase(moon => 9.926, sun => 316.527); 
  # returns 'Waxing Crescent'

=head1 DESCRIPTION

Searches lunar quarters. Algorithms are based on
I<"Astronomy with your PC"> by I<Peter Duffett-Smith>, I<Second Edition>, I<Cambridge University Press}, 1990>.


=head1 EXPORT

=head2 CONSTANTS

=head3 PHASES

=over

=item * C<$NEW_MOON>

=item * C<$WAXING_CRESCENT>

=item * C<$FIRST_QUARTER>

=item * C<$WAXING_GIBBOUS>

=item * C<$FULL_MOON>

=item * C<$WANING_GIBBOUS>

=item * C<$LAST_QUARTER>

=item * C<$WANING_CRESCENT>

=back



=head1 SUBROUTINES

=head2 search_event(date => $arr, quarter => $scalar)

Calculate instant of apparent lunar phase closest to the given date.

=head3 Named Arguments

=over

=item * B<date> — array of B<year> (astronomical, zero-based), B<month> [1..12]
and B<day>, [1..31].

=item * B<quarter> — which quarter, one of: C<$NEW_MOON>, C<$FIRST_QUARTER>,
C<$FULL_MOON> or C<$LAST_QUARTER>.

=back

=head3 Returns

In scalar context returns I<Standard Julian day> of the event, dynamic time.

In list context:

=over

=item * I<Standard Julian day> of the event, dynamic time.

=item * Argument of latitude, arc-degrees. This value is required for detecting elipses.

=back

=head2 lunar_month($jd)

Find lunar quarters around the given date

=head3 Arguments

=over

=item * B<jd> — Standard Julian date

=head3 Returns

Array of 5 hashes, each hash representing a successive lunar quarter. Their order is always the same:

=over

=item 1. 

B<New Moon>

=item 2. 

B<First Quarter>

=item 3. 

B<Full Moon>

=item 4. 

B<Last Quarter>

=back

=item 4. 

B<The next New Moon>

=back


Each hash contains 3 elements:

=over

=item * B<type>

One of the constants representing the main Quarter: C<$NEW_MOON>, C<$FIRST_QUARTER>, C<$FULL_MOON>, C<$LAST_QUARTER>.

=item * B<jd>

Standard Julian Date of the event,

=item * B<current>

I<True> if the the given date lies within the quarter.

=back

=head4 Example

    lunar_month(2459614.5) gives: 

    (
        {
            type => 'New Moon',
            jd => 2459611.74248269, # time when the quarter starts
            current => 1 # since 2459611.74248269 < 2459614.5 < 2459619.07819525, our date belongs to New Moon phase.
        },
        {
            type => 'First Quarter',
            current => 0,
            jd => 2459619.07819525
        },
        {
            type => 'Full Moon',
            current => 0,
            jd => 2459627.20811964
        },
        {
            current => 0,
            jd => 2459634.44073709'
            type => 'Last Quarter'
        },
        {
            current => 0,
            type => 'New Moon',
            jd => 2459641.23491532
        }
    );


=head2 lunar_phase(sun => $decimal, moon => $decimal)

Given Sun and Moon longitudes, detects a lunar phase. 

=head3 Named Arguments

=over

=item * B<sun> — longitude of the Sun, in arc-degrees

=item * B<moon> — longitude of the Moon, in arc-degrees
=back

=head3 Returns

In scalar context the phase name, one of the L<PHASES>.

In list context:

=over

=item * name of the phase.

=item * Moon age in arc-degrees

=item * Moon age in days

=back


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2022 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
