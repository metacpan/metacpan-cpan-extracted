package Astro::Coord::ECI::VSOP87D::_Superior;

use 5.008;

use strict;
use warnings;

use base qw{ Astro::Coord::ECI };

use Astro::Coord::ECI::Mixin qw{
    almanac almanac_hash
    next_quarter_hash
};
use Astro::Coord::ECI::Utils qw{ PI PIOVER2 find_first_true mod2pi };
use Astro::Coord::ECI::VSOP87D qw{ :mixin };
use Carp;

our $VERSION = '0.005';

sub new {
    my ( $class, %arg ) = @_;
    $class->__default( \%arg );
    return $class->SUPER::new( %arg );
}

sub __almanac_event_type_iterator {
    my ( $self, $station ) = @_;

    my $inx = 0;

    my $horizon = $station->__get_almanac_horizon();

    my @events = (
	[ $station, next_elevation => [ $self, $horizon, 1 ],
	    horizon	=> '__horizon_name' ],
	[ $station, next_meridian => [ $self ],
	    transit	=> '__transit_name' ],
	[ $self, next_quarter => [], 'quarter', '__quarter_name' ],
    );

    return sub {
	$inx < @events
	    and return @{ $events[$inx++] };
	return;
    };
}

{
    my $get = sub {
	my ( $self, $name ) = @_;
	return $self->__get_attr()->{$name};
    };

    my %accessor = (
	model_cutoff		=> $get,
	nutation_cutoff		=> $get,
    );

    sub attribute {
	my ( $self, $name ) = @_;
	exists $accessor{$name}
	    and return __PACKAGE__;
	return $self->SUPER::attribute( $name );
    }

    sub get {
	my ( $self, @arg ) = @_;
	my @rslt;
	foreach my $name ( @arg ) {
	    if ( my $code = $accessor{$name} ) {
		push @rslt, $code->( $self, $name );
	    } else {
		push @rslt, $self->SUPER::get( $name );
	    }
	    wantarray
		or return $rslt[0];
	}
	return @rslt;
    }
}

# NOTE that the %opt arguments are UNSUPPORTED and can be changed or
# removed without notice. Caveat coder.
sub next_quarter {
    my ( $self, $quarter, %opt ) = @_;

    my $time = $self->universal();

    my $increment = $self->synodic_period() / 16;

    my @checker = (
	sub {	# 0 = conjunction
	    my ( $time ) = @_;
	    return $self->__longitude_from_sun( $time ) < 0 ? 4 : 0;
	},
	sub {	# 1 = west quadrature
	    my ( $time ) = @_;
	    return $self->__longitude_from_sun( $time, - PIOVER2 ) < 0 ? 1 : 0;
	},
	sub {	# 2 = opposition
	    my ( $time ) = @_;
	    return $self->__longitude_from_sun( $time, PI ) < 0 ? 2 : 0;
	},
	sub {	# 3 = east quadrature
	    my ( $time ) = @_;
	    return $self->__longitude_from_sun( $time, PIOVER2 ) < 0 ? 3 : 0;
	},
    );

    if ( defined $opt{checker_result} ) {
	return $checker[$opt{checker_result}]->( $time );
    }

    my $test;
    if ( defined $quarter ) {
	$test = $checker[$quarter];
	while ( $test->( $time ) ) {
	    $time += $increment;
	}
	while ( ! $test->( $time ) ) {
	    $time += $increment;
	}
    } else {
	my @chk = grep { ! $_->( $time ) } @checker
	    or confess 'Programming error - no false checks';
	my $rslt;
	while ( ! $rslt ) {
	    $time += $increment;
	    foreach my $c ( @chk ) {
		$rslt = $c->( $time )
		    and last;
	    }
	}
	$quarter = $rslt % 4;
	$test = $checker[$quarter];
    }

    my $rslt = find_first_true( $time - $increment, $time, $test );

    $self->universal( $rslt );

    wantarray
	or return $rslt;
    return( $rslt, $quarter, $self->__quarter_name( $quarter ) );
}

sub __quarter_name {
    my ( $self, $event, $name ) = @_;
    $name ||= [
	'%s conjunction',
	'%s west quadrature',
	'%s opposition',
	'%s east quadrature',
    ];
    return sprintf $name->[$event], $self->get( 'name' );
}

{
    my %mutator = (
	model_cutoff		=> \&__mutate_model_cutoff,
	nutation_cutoff		=> \&__mutate_nutation_cutoff,
    );

    sub set {
	my ( $self, @arg ) = @_;
	while ( @arg ) {
	    my ( $name, $value ) = splice @arg, 0, 2;
	    if ( my $code = $mutator{$name} ) {
		$code->( $self, $name, $value );
	    } else {
		$self->SUPER::set( $name, $value );
	    }
	}
	return $self;
    }
}

1;

__END__

=head1 NAME

Astro::Coord::ECI::VSOP87D::_Superior - VSOP87D superior planets

=head1 SYNOPSIS

This abstract Perl class is not intended to be invoked directly by the
user.

=head1 DESCRIPTION

This abstract Perl class represents the VSOP87D model of an superior
planet. It is a subclass of L<Astro::Coord::ECI|Astro::Coord::ECI>.

=head1 METHODS

This class supports the following public methods in addition to those
inherited from the superclass.

=head2 model_cutoff_definition

This method reports, creates, and deletes model cutoff definitions.

The first argument is the name of the model cutoff. If this is the only
argument, a reference to a hash defining the named model cutoff is
returned.  This return is a deep clone of the actual definition.

If the second argument is C<undef>, the named model cutoff is deleted.
If the model cutoff does not exist, the call does nothing. It is an
error to try to delete built-in cutoffs C<'none'> and C<'Meeus'>.

If the second argument is a reference to a hash, this defines or
redefines a model cutoff. The keys to the hash are the names of VSOP87D
series (C<'L0'> through C<'L5'>, C<'B0'> through C<'B5'>, and C<'R0'>
through C<'R5'>), and the value of each key is the number of terms of
that series to use. If one of the keys is omitted or has a false value,
that series is not used.

If the second argument is a scalar, it is expected to be a number, and a
model cutoff is generated consisting of all terms whose coefficient
(C<'A'> in Meeus' terminology) is equal to or greater than the number.

If the second argument is a code reference, this code is expected to
return a reference to a valid model cutoff hash as described two
paragraphs previously. Its arguments are the individual series hashes,
extracted from the model. Each hash will have the following keys:

=over

=item series

The name of the series (e.g. 'L0').

=item terms

An array reference containing the terms of the series.
Each term is a reference to an array containing in order, in Meeus'
terms, values C<'A'>, C<'B'>, and C<'C'>.

=back

=head2 next_quarter

 my ( $time, $quarter, $desc ) = $body->next_quarter( $want );

This method calculates the time of the next quarter event after the
current time setting of the $body object. The return is the time, which
event it is as a number from 0 to 3, and a string describing the event.
If called in scalar context, you just get the time.

Quarters are defined as positions in the orbit, not phases. This is the
usage throughout the L<Astro::Coord::ECI|Astro::Coord::ECI> hierarchy,
even the Moon. The name C<'quarter'> seems ill-chosen, but it is
probably too late to do anything about it now.

Specifically, for superior planets the quarters are:

 0 - conjunction
 1 - east quadrature
 2 - opposition
 3 - west quadrature

The optional $want argument says which event you want.

As a side effect, the time of the $body object ends up set to the
returned time.

The method of calculation is successive approximation, and actually
returns the second B<after> the calculated event.

=head2 nutation

 my ( $delta_psi, $delta_epsilon ) =
     $self->nutation( $dynamical_time, $cutoff );

This method calculates the nutation in ecliptic longitude
(C<$delta_psi>) and latitude (C<$delta_epsilon>) at the given dynamical
time in seconds since the epoch (i.e. Perl time), according to the IAU
1980 model.

The C<$time> argument is optional, and defaults to the object's current
dynamical time.

The C<$cutoff> argument is optional; if specified as a number larger
than C<0>, terms whose amplitudes are smaller than the nutation cutoff
(in milli arc seconds) are ignored. The Meeus version of the algorithm
is specified by a value of C<3>. The default is specified by the
L<nutation_cutoff|/nutation_cutoff> attribute.

The model itself is the IAU 1980 nutation model. Later models exist, but
this was chosen because of the desire to be compatible with Meeus'
examples. The implementation itself actually comes from Meeus chapter
22. The model parameters were not transcribed from that source, however,
but were taken from the source IAU C reference implementation of the
algorithm, F<src/nut80.c>, with the minimum modifications necessary to
make the C code into Perl code. This file is contained in
L<http://www.iausofa.org/2018_0130_C/sofa_c-20180130.tar.gz>.

=head2 obliquity

 $epsilon = $self->obliquity( $time );

This method calculates the obliquity of the ecliptic in radians at
the given B<dynamical> time. If the time is omitted or specified as
C<undef>, the current dynamical time of the object is used.

The algorithm is equation 22.3 from Jean Meeus' "Astronomical
Algorithms", 2nd Edition, Chapter 22, pages 143ff.

=head2 order

 say 'Order from Sun: ', $self->order();

This method returns the order of the body from the Sun, with the Sun
itself being C<0>. The number C<3> is skipped, since that would
represent the Earth.

=head2 period

 $self->period()

This method returns the sidereal period of the object, calculated from
the coefficient of its first C<L1> term.

The algorithm is the author's, and is a first approximation. That is. it
is just the tropical period plus however long it takes the object to
cover the amount of precession during the tropical year.

=head2 synodic_period

 $self->synodic_period()

This method returns the synodic period of the object -- that is to say
the mean interval between oppositions or conjunctions of superior
planets or between corresponding conjunctions of inferior planets.

=head2 time_set

 $self->time_set()

This method is not normally called by the user. It is called by
L<Astro::Coord::ECI|Astro::Coord::ECI> to compute the position once the
time has been set.

It returns the invocant.

=head2 year

 $self->year()

This method returns the length of the tropical year of the object,
calculated from the coefficient of its first C<L1> term.

=head1 ATTRIBUTES

This class has the following attributes in addition to those of its
superclass:

=head2 model_cutoff

This attribute specifies how to truncate the calculation. Valid values
are:

=over

=item C<'none'> specifies no model cutoff (i.e. the full series);

=item C<'Meeus'> specifies the Meeus Appendix III series.

=back

The default is C<'Meeus'>.

=head2 nutation_cutoff

The nutation_cutoff value specifies how to truncate the nutation
calculation. All terms whose magnitudes are less than the nutation
cutoff are ignored. The value is in terms of 0.0001 seconds of arc, and
must be a non-negative number.

The default is C<3>, which is the value Meeus uses.

=head1 SEE ALSO

L<Astro::Coord::ECI|Astro::Coord::ECI>

L<Astro::Coord::ECI::VSOP87D|Astro::Coord::ECI::VSOP87D>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-Coord-ECI-VSOP87D>,
L<https://github.com/trwyant/perl-Astro-Coord-ECI-VSOP87D/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
