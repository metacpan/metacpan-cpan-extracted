package Astro::Coord::ECI::Mixin;

use 5.006002;

use strict;
use warnings;

use Carp;

use Astro::Coord::ECI::Utils qw{ __default_station
    ARRAY_REF PIOVER2 SECSPERDAY
    @CARP_NOT
};
use Exporter ();
use POSIX qw{ floor };

our $VERSION = '0.103';

our @EXPORT_OK = qw{
    almanac almanac_hash
    next_quarter next_quarter_hash
};

our %EXPORT_TAGS = (
    almanac	=> [ qw{ almanac almanac_hash } ],
    quarter	=> [ qw{ next_quarter next_quarter_hash } ],
);

BEGIN {
    # Because 5.6.2's Exporter does not export 'import()'.
    *import = \&Exporter::import;
}

sub almanac {
    my ( $self, $station, $start, $end ) = __default_station( @_ );
    defined $start
	or $start = $self->universal();
    defined $end
	or $end = $start + SECSPERDAY;

    my @almanac;

    my $iterator = $self->__almanac_event_type_iterator( $station );

    while ( my ( $obj, $method, $args, $event, $descr ) = $iterator->() ) {

	$obj->universal( $start );
	while ( 1 ) {
	    my ( $time, $which ) = $obj->$method ( @$args );
	    $time >= $end
		and last;
	    defined ( my $text = ARRAY_REF eq ref $descr ?
		$descr->[ $which ] : $self->$descr( $which ) )
		or next;
	    push @almanac, [ $time, $event, $which, $text ];
	}
    }

    return (sort {$a->[0] <=> $b->[0]} @almanac);
}

sub almanac_hash {
    my ( $self, $station, $start, $end ) = __default_station( @_ );
    return map {
	body => $self,
	station => $station,
	time => $_->[0],
	almanac => {
	    event => $_->[1],
	    detail => $_->[2],
	    description => $_->[3],
	}
    }, $self->almanac( $station, $start, $end );
}

sub next_quarter {
    my ( $self, $quarter ) = @_;
    my $next_quarter_inc = $self->NEXT_QUARTER_INCREMENT();

    $quarter = ( defined $quarter ? $quarter :
	floor( $self->__next_quarter_coordinate() / PIOVER2 ) + 1 ) % 4;
    my $begin;
    while ( floor( $self->__next_quarter_coordinate() / PIOVER2 ) == $quarter ) {
	$begin = $self->dynamical();
	$self->dynamical( $begin + $next_quarter_inc );
    }
    while ( floor( $self->__next_quarter_coordinate() / PIOVER2 ) != $quarter ) {
	$begin = $self->dynamical();
	$self->dynamical($begin + $next_quarter_inc);
    }
    my $end = $self->dynamical();

    while ( $end - $begin > 1 ) {
	my $mid = floor( ( $begin + $end ) / 2 );
	my $qq = floor( $self->dynamical($mid )->__next_quarter_coordinate() /
	    PIOVER2 );
	( $begin, $end ) = $qq == $quarter ?
	    ( $begin, $mid ) : ( $mid, $end );
    }

    $self->dynamical( $end );

    return wantarray ? (
	$self->universal, $quarter, $self->__quarter_name( $quarter ),
    ) : $self->universal();
}

sub next_quarter_hash {
    my ( $self, @args ) = @_;
    my ( $time, $quarter, $desc ) = $self->next_quarter( @args );
    my %hash = (
	body => $self,
	almanac => {
	    event => 'quarter',
	    detail => $quarter,
	    description => $desc,
	},
	time => $time,
    );
    return wantarray ? %hash : \%hash;
}

1;

__END__

=head1 NAME

Astro::Coord::ECI::Mixin - Provide common methods without multiple inheritance.

=head1 SYNOPSIS

In a class that wishes to add the C<next_quarter()> method:

 use Astro::Coord::ECI::Mixin qw{ next_quarter };
 
 use constant NEXT_QUARTER_INCREMENT => 6 * 86400;	# Seconds

=head1 DESCRIPTION

This package provides code re-use without multiple inheritance. Classes
that wish to make use of the methods simply import them. Some of the
methods require manifest constants to be defined; these are specified
with the method.

This package is B<private> to the L<Astro::Coord::ECI|Astro::Coord::ECI>
package.  Documentation is for the benefit of the author only. I am not
opposed to making the interface public, but in the early going would
like the liberty of being able to modify it without prior notice.

=head1 METHODS

This package supplies the following public methods:

=head2 almanac

 my @almanac = $body->almanac( $station, $start, $end );

This method produces almanac data for the C<$body> for the given
observing station, between the given start and end times. The station is
assumed to be Earth-Fixed - that is, you can't do this for something in
orbit.

The C<$station> argument may be omitted if the C<station> attribute has
been set. That is, this method can also be called as

 my @almanac = $body->almanac( $start, $end )

The start time defaults to the current time setting of the $sun
object, and the end time defaults to a day after the start time.

The almanac data consists of a list of list references. Each list
reference points to a list containing the following elements:

 [0] => time
 [1] => event (string)
 [2] => detail (integer)
 [3] => description (string)

The @almanac list is returned sorted by time.

This mixin makes use of the following methods:

=head3 __almanac_event_type_iterator

 my $iterator = $self->__almanac_event_type_iterator( $station );

This method is passed an object representing the observing station, and
must return a code reference to be used as an iterator.

The iterator is called without arguments. Each call returns a list
representing a specific event to be reported on. The list consists of

 ( $invocant, $method, $args, $name, $detail )

where:

 $invocant is the object that generates the event;
 $method is the name of the method to call on the invocant;
 $args is a reference to an array of arguments to be passed
     to the method when it is called;
 $name is the name of the event type;
 $detail is the event detail.

The C<$detail> return is either a reference to an array of event detail
descriptions, or the name of a method to be called on the invocant and
passed the event detail number. In the latter case the method is to
return the event detail description.

=head2 almanac_hash

 my @almanac = $body->almanac_hash( $station, $start, $end );

This convenience method wraps $body->almanac(), but returns a list of
hash references, sort of like Astro::Coord::ECI::TLE->pass()
does. The hashes contain the following keys:

  {almanac} => {
    {event} => the event type;
    {detail} => the event detail (typically 0 or 1);
    {description} => the event description;
  }
  {body} => the original object ($sun);
  {station} => the observing station;
  {time} => the time the quarter occurred.

The {time}, {event}, {detail}, and {description} keys correspond to
elements 0 through 3 of the list returned by almanac().

=head2 next_quarter

 my ( $time, $quarter, $desc ) = $body->next_quarter( $want );

This method calculates the time of the next quarter event after the
current time setting of the $body object. The return is the time, which
event it is as a number from 0 to 3, and a string describing the event.
If called in scalar context, you just get the time.

The optional $want argument says which event you want.

As a side effect, the time of the $body object ends up set to the
returned time.

The method of calculation is successive approximation, and actually
returns the second B<after> the calculated event.

This mixin makes use of the following methods:

=head3 NEXT_QUARTER_INCREMENT

This manifest constant is the approximate number of seconds to the next
event. The approximation B<must> undershoot in all cases.

=head3 __next_quarter_coordinate

This method calculates the coordinate that determines the next quarter.
Typically it would be an alias for a longitude or phase method. This
method is called in scalar context.

=head3 __quarter_name

This method calculates the name of a quarter given its number, and an
optional reference to an array of quarter names. The optional argument
is for the benefit of localization code.

=head2 next_quarter_hash

 my $hash_reference = $body->next_quarter_hash( $want );

This convenience method wraps $body->next_quarter(), but returns the
data in a hash reference, sort of like Astro::Coord::ECI::TLE->pass()
does. The hash contains the following keys:

  {body} => the original object ($body);
  {almanac} => {
    {event} => 'quarter',
    {detail} => the quarter number (0 through 3);
    {description} => the quarter description;
  }
  {time} => the time the quarter occurred.

The {time}, {detail}, and {description} keys correspond to elements 0
through 2 of the list returned by next_quarter().

This mixin makes use of the following method:

=head2 next_quarter

This is assumed to be the mixin described above.

=head1 ATTRIBUTES

This package can not define any public attributes.

=head1 SEE ALSO

The L<Astro::Coord::ECI::OVERVIEW|Astro::Coord::ECI::OVERVIEW>
documentation for a discussion of how the pieces/parts of this
distribution go together and how to use them.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
