package Date::ManipX::Almanac::Lang::english;

use 5.010;

use strict;
use warnings;

use parent qw{ Date::ManipX::Almanac::Lang };

use Carp;

our $VERSION = '0.003';

our $LangName = 'English';

# See the Date::ManipX::Almanac::Lang POD for __body_data
sub __body_data {
    my ( $self ) = @_;
    my @season = $self->__season_to_detail();
    return [
	[ 'Astro::Coord::ECI::Sun'	=>
	    qr/ (?: (?: when | at ) \s* )? (?: the \s* )? sun /smxi,
	    qr/ (?: at \s* )? (?: the \s* )? (?:
		(?<detail> beginn? | end ) (?: ing )? (?: \s* of )? \s*
		    (?<qual> astronomical | civil | nautical )? \s*
		    (?<specific> twilight ) |
		(?<qual> astronomical | civil | nautical )? \s*
		    (?<specific> twilight ) \s* (?<detail> begin | end ) s? |
		(?<detail> morning | evening ) \s*
		    (?<qual> astronomical | civil | nautical )? \s*
		    (?<specific> twilight ) |
		(?<specific> local ) \s* (?<detail> noon | midnight ) |
		(?<detail> spring | vernal | march | september ) \s*
		    (?<specific> equinox ) |
		(?<detail> autumn ) (?: al )? \s* (?<specific> equinox ) |
		(?<detail> summer | winter | june | december ) \s*
		    (?<specific> solstice )
	    ) /smxi,
	    {	# Iterpret (?<specific> ... )
		#
		# The required data are described in the
		# Date::ManipX::Almanac::Lang POD, under __body_re().
		#
		equinox		=> [ quarter => {
			autumn		=> $season[ 2 ],
			march		=> 0,
			september	=> 2,
			spring		=> $season[ 0 ],
			vernal		=> $season[ 0 ],
		    },
		],
		solstice	=> [ quarter => {
			december	=> 3,
			june		=> 1,
			summer		=> $season[ 1 ],
			winter		=> $season[ 3 ],
		    },
		],
		local		=> [ meridian => {
			noon		=> 1,
			midnight	=> 0,
		    },
		],
		twilight	=> [ twilight => {
			begin	=> 1,
			beginn	=> 1,
			end	=> 0,
			evening	=> 0,
			morning	=> 1,
		    },
		    {
			astronomical	=> 'astronomical',
			civil		=> 'civil',
			nautical	=> 'nautical',
		    },
		],
	    },
	],
	[ 'Astro::Coord::ECI::Moon'	=>
	    qr/ (?: (?: when | at ) \s* )? (?: the \s* )? moon /smxi,
	    qr/ (?: at \s* )? (?: the \s* )? (?:
		(?<specific> first | last ) \s* \s* quarter (?: \s* moon )? |
		(?<specific> full | new ) (?: \s* moon )?
	    ) /smxi,
	    {	# Iterpret (?<specific> ... )
		#
		# The required data are described in the
		# Date::ManipX::Almanac::Lang POD, under __body_re().
		#
		new	=> [ quarter	=> 0 ],
		first	=> [ quarter	=> 1 ],
		full	=> [ quarter	=> 2 ],
		last	=> [ quarter	=> 3 ],
	    }
	],
	# A map {} makes sense in English, but not in any other
	# language.
	# NOTE we don't need the Sun here, because ::VSOP87D::Sun is a
	# subclass of ::Sun.
	[ 'Astro::Coord::ECI::VSOP87D::Mercury'	=>
	    qr/ (?: when \s* )? mercury /smxi ],
	[ 'Astro::Coord::ECI::VSOP87D::Venus'	=>
	    qr/ (?: when \s* )? venus /smxi ],
	[ 'Astro::Coord::ECI::VSOP87D::Mars'	=>
	    qr/ (?: when \s* )? mars /smxi ],
	[ 'Astro::Coord::ECI::VSOP87D::Jupiter'	=>
	    qr/ (?: when \s* )? jupiter /smxi ],
	[ 'Astro::Coord::ECI::VSOP87D::Saturn'	=>
	    qr/ (?: when \s* )? saturn /smxi ],
	[ 'Astro::Coord::ECI::VSOP87D::Uranus'	=>
	    qr/ (?: when \s* )? uranus /smxi ],
	[ 'Astro::Coord::ECI::VSOP87D::Neptune'	=>
	    qr/ (?: when \s* )? neptune /smxi ],
    ];
}

# See the Date::ManipX::Almanac::Lang POD for __general_event_re
#
# Return a regular expression that matches any event that must be paired
# with the name of a body. The internal name of the event must be
# captured by named capture (?<general> ... )
sub __general_event_re {
    return qr/
	(?: the \s* )? (?<general> culminat ) (?: es? | ion ) (?: \s* of )? |
	(?: is \s* )? (?: the \s* )? (?<general> highest ) |
	(?<general> rise | set ) s? |
	(?: the \s* )? (?<general> rising ) (?: \s* of )? |
	(?: the \s* )? (?<general> setting ) (?: \s* of )? |
	(?: is \s* )? (?<general> up | down )
    /smxi;
}

# See the Date::ManipX::Almanac::Lang POD for __general_event_interp
#
# The interpretation of the events captured in (?<general> ... ) above.
sub __general_event_interp {
    state $rise		= [ horizon	=> 1 ];
    state $set		= [ horizon	=> 0 ];
    state $highest	= [ meridian	=> 1 ];
    return [
	{
	    culminat	=> $highest,
	    down	=> $set,
	    highest	=> $highest,
	    rise	=> $rise,
	    rising	=> $rise,
	    set		=> $set,
	    setting	=> $set,
	    up		=> $rise,
	},
    ];
}

sub __ignore_after_re {
    return qr< \s* (?: (?: on | at ) \s+ or \s+ )? after >smxi;
}

1;

__END__

=head1 NAME

Date::ManipX::Almanac::Lang::english - English support for Date::ManipX::Almanac

=head1 SYNOPSIS

The user does not directly interface with this module.

=head1 DESCRIPTION

This module provides English-language support for parsing almanac
events.

=head1 ASTRONOMICAL BODIES

The following astronomical bodies are recognized:

 the sun
 the moon
 mercury
 venus
 mars
 jupiter
 saturn
 uranus
 neptune

The word C<'the'> is optional. So is the word C<'when'> before the
entire body name string; that is, C<'when the sun'> but not
C<'the when sun'>.

=head1 ALMANAC EVENTS

This section describes the events that this class provides. Descriptions
are in terms of the superclass' documentation, and so will look a bit
redundant in English.

Incidental words like C<'the'> and C<'of'> are supported where the
author found them natural and bothered to allow for them, but do (or at
least should) not affect the parse.

For the purpose of discussion, events are divided into two classes.
L<General Events|/General Events> are those that apply to any
astronomical body, and which therefore require the specification of the
body they apply to. L<Specific Events|/Specific Events> only apply to
one body, and therefore do not require the naming of a specific body.

=head1 General Events

The following general events should be recognized by this class:

=over

=item Culminates

This is defined as the moment when the body appears highest in the sky.
This module recognizes

 culminates
 the culmination of
 is the highest

The words C<'is'>, C<'the'>, and C<'of'> are optional. So is the word
C<'at'> before the name of the event.

=item Rise

This is defined as the moment when the upper limb of the body appears
above the horizon, after correcting for atmospheric refraction. This
module recognizes

 rise
 rises
 the rising of
 is up

The words C<'the'>, C<'of'>, and C<'is'> are optional. So is the word
C<'at'> before the name of the event.

=item Set

This is defined as the moment when the upper limb of the body disappears
below the horizon, after correcting for atmospheric refraction. This
module recognizes

 set
 sets
 the setting of
 is down

The words C<'the'>, C<'of'>, and C<'is'> are optional. So is the word
C<'at'> before the name of the event.

=back

=head1 Specific Events

The following specific events should be recognized by any subclass:

=over

=item Phases of the Moon

 the new moon
 the first quarter moon
 the full moon
 the last quarter moon

This implies the Moon. It computes the first occurrence of the specified
phase on or after the specified date.

The words C<'the'> and C<'moon'> are optional. So is the word
C<'at'> before the name of the event.

=item Solar quarters

 the december solstice
 the march equinox
 the fall equinox
 the june solstice
 the september equinox
 the spring equinox
 the summer equinox
 the vernal equinox
 the winter solstice

This implies the Sun. It computes the first occurrence of the specified
quarter after the specified date. B<Note> that the time specified by the
seasonal names differs between Northern and Southern Hemispheres.

The word C<'the'> is optional. So is the word
C<'at'> before the name of the event.

=item twilight

 begin twilight
 the beginning of twilight
 twilight begins
 morning twilight
 end twilight
 the ending of twilight
 twilight ends
 evening twilight

This implies the Sun, and specifies the time the center of the Sun
passes above (C<'begin'>) or below (C<'end'>) the twilight setting of
the C<location> object. This defaults to civil twilight (in the U.S. at
least), or 6 degrees below the horizon.

One of the words C<'civil'>, C<'nautical'>, or C<'astronomical'> can
optionally be inserted before C<'twilight'>, specifying that the Sun be
6, 12, or 18 degrees below the horizon, respectively.

The words C<'the'> and C<'of'> are optional. So is the word
C<'at'> before the name of the event.

=item noon

 local noon
 local midnight

This implies the Sun. The C<'local noon'> specification is equivalent to
C<'sun culminates'>.

The word C<'at'> may optionally appear before the name of the event.

=back

=head1 SEE ALSO

L<Date::ManipX::Almanac::Lang|Date::ManipX::Almanac::Lang>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Date-ManipX-Astro-Lang-english>,
L<https://github.com/trwyant/perl-Date-ManipX-Astro-Lang-english/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
