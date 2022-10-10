package Date::ManipX::Almanac::Lang;

use 5.010;

use strict;
use warnings;

use Carp;

our $VERSION = '0.003';

use constant REF_ARRAY			=> ref [];

=begin comment

=head2 __new

 my $dmal = Date::ManipX::Almanac::Lang->__new(
   sky => \@sky,
 );

This static method instantiates the object. The C<sky> argument is
required.

=end comment

=cut

sub __new {
    my ( $class, %arg ) = @_;

    REF_ARRAY eq ref $arg{sky}
	or confess 'Bug - sky must be an ARRAY ref';

    # For seasons in the Southern hemisphere. We rely on all astonomical
    # bodies having the same station attribute. If there is none we
    # assume the Northern hemisphere.
    my @season = ( 0 .. 3 );
    my $sta;
    @{ $arg{sky} }
	and $sta = $arg{sky}[0]->get( 'station' )
	and ( $sta->geodetic() )[0] < 0
	and push @season, splice @season, 0, 2;

    return bless {
	season	=> \@season,
	sky	=> $arg{sky},
    }, $class;
}

=begin comment

=head2 __body_data

 my $data = $self->__body_data();

This method returns the table that drives L<__body_re()|/__body_re>. It
B<must> be implemented by the subclass.

The return is an array reference. Each element is a reference to an
array as returned by L<__body_re()|/__body_re>, except that the first
element is the name of the represented class.

=end comment

=cut

=begin comment

=head2 __body_re

 my ( $body_re, $spec_re, $interp_spec ) =
   $self->__body_re( $body );

Given an astronomical body, return one to three pieces of data:

=over

=item $body_re

This is a regular expression that matches the name of the body in the
currently-set language. This regular expression is not expected to
capture anything.

=item $spec_re

If defined, this is a regular expression that matches any specific
events in the currently-set language that imply this body. This regular
expression must capture the event name in C<< (?<specific> ... ) >>. If
the event name captured in C<< (?<specific> ... ) >> does not imply an
event detail, that must be captured in C<< (?<detail> ... ) >>.

=item $interp_spec

If defined, this is a reference to a hash that converts the captured
specific events into internal form. This B<must> be defined if
C<$spec_re> is.

The keys are the strings captured by C<< (?<specific> ... ) >>,
normalized by converting to lower case, stripping diacriticals, and
removing white space.

The values are array references.

The first element of the array must be the internal name of the event.

The second element depends on whether the regular expression captured
C<< (?<detail> ... ) >>. If it did, the second element is a reference to
a hash keyed on the normalized capture, and whose values are detail
specifications. If not, the second element is a detail specification.

The detail specification is an L<Astro::Coord::ECI|/Astro::Coord::ECI>
event detail number.

The third element of the array depends on whether the regular expression
captured C<< (?<qual> ... ) >>. If it did, the third element is a
reference to a hash keyed on the normalized capture, and whose values
are qualifier specifications. If not, the third element is ignored, and
need not be specified.

As of this writing, the C<< (?<qual> ... ) >> capture is used only by
twilight events, to translate the local equivalents of C<'civil'>,
C<'nautical'>, and C<'astronomical'>.

=back

=end comment

=cut

sub __body_re {
    my ( $self, $body ) = @_;

    foreach ( @{ $self->{body_data} ||= $self->__body_data() } ) {
	$body->isa( $_->[0] )
	    and return @{ $_ }[ 1 .. $#$_ ];
    }

    my $name = $self->__body_re_from_name(
	$self->__string_to_re( body_name => $body->get( 'name' ) ) );
    return qr/ $name /smxi;
}

=begin comment

=head2 __body_re_from_name

 my $re = $self->__body_re_from_name( $name );

This is a fallback for anything not covered in
L<__body_data()|/__body_data> (e.g. stars). The argument is the name,
which has already been processed by
L<__string_to_re()|/__string_to_re()>. Despite the name of the method,
the return is a string, not a C<Regexp> object. The return must not
capture anything.

This class' implementation simply returns the argument, but it can be
overridden to allow things like articles and prepositions. In langages
that inflect by gender, the override will need to allow both genders.

=end comment

=cut

sub __body_re_from_name {
    my ( undef, $name ) = @_;
    return $name;
}

=begin comment

=head2 __event_capture

 $self->__event_capture( $interp_spec )

This method is to be called when an event is captured. It is expected to
be called in the replacement side of an C<s///g> operation. The
argument is the same C<$interp_spec> that is
returned by L<__body_re()|/__body_re>. The captures are interpreted and
stashed in the object for later recovery by
L<__event_retrieve()|/__event_retrieve>. The empty string is returned.

=end comment

=cut

sub __event_capture {
    my ( $self, undef, $interp_specific ) = @_;
    delete $self->{captured_event};

    my %capture = map { $_ => $self->__string_to_key( $_ => $+{$_} ) }
	grep { defined $+{$_} } qw{ specific general detail qual };

    foreach (
	[ specific => $interp_specific ],
	[ general => @{ $self->{interp_general} ||=
	    $self->__general_event_interp() } ],
    ) {

	my ( $name, $interp_event ) = @{ $_ };

	next unless $interp_event && $capture{$name};

	my $evt = $interp_event->{$capture{$name}}
	    or confess "Bug - Event '$capture{$name}' not recognized";
	( $evt, my $det, my $qual ) = @{ $evt };

	if ( defined $capture{detail} ) {
	    defined( $det = $det->{$capture{detail}} )
		or confess "Bug - $capture{$name} detail ",
		    "'$capture{detail}' not recognized";
	}

	if ( defined $capture{qual} ) {
	    $qual
		or confess "Bug - $capture{$name} qualifiers not defined";
	    defined( $qual = $qual->{$capture{qual}} )
		or confess "Bug - $capture{$name} qualifier ",
		    "'$capture{qual}' not recognized";
	}

	$self->{captured_event} = [ $evt, $det, $qual ];

	return '';
    }
    confess 'Bug - No event captured';
}

=begin comment

=head2 __event_retrieve

 my ( $body, $event, $detail ) = $dmal->__event_retrieve()

This method retrieves the body and event found in the string being
parsed. If none was found it returns the empty list.

=end comment

=cut

sub __event_retrieve {
    my ( $self ) = @_;
    return @{ $self->{captured_event} || [] };
}

=begin comment

=head2 __general_event_interp

 my ( $interp_general ) = @{
     $self->_general_event_interp() };

This method returns a reference to an array containing the hashes that
interpret the data captured by C<$general_re> (returned by
L<__general_event_re()|/__general_event_re>, below). It B<must> be
implemented by the subclass.

The return corresponds in structure and use to C<$interp_spec> as
described above in the documentation to L<__body_re()|/__body_re>,
except that the hash returned in C<$interp_general> is keyed by
C<< $+<general> >>.

=head2 __general_event_re

 my $general_re = $self->__general_event_re();

This method returns the regular expression that matches general events
in the currently-set language.  It B<must> be implemented by the
subclass.

This regular expression B<must> capture the event name in
C<< (?<general> ... ) >>. If the event name captured in
C<< (?<general> ... ) >> does not imply an event detail, that B<must> be
captured in C<< (?<detail> ... ) >>.

=end comment

=cut

=begin comment

=head2 __ignore_after_re

 my $ignore_after_re = $self->__ignore_after_re()

This method returns a language-specific regular expression which is
removed if it appears after the language-specific almanac event
specification, but is otherwise ignored. The idea is that you can use
this to allow the language-specific version of

 summer solstice on or after july 4 2020

where the C<'on or after'> was matched by the returned expression.

This implementation returns an expression that matches nothing.

=end comment

=cut

sub __ignore_after_re {
    return qr< .{0} >smx;
}

=begin comment

=head2 __ignore_before_re

 my $ignore_before_re = $self->__ignore_before_re()

This method returns a language-specific regular expression which is
removed if it appears before the language-specific almanac event
specification, but is otherwise ignored. It is intended to be analogous
to C<__ignore_after_re()>, but at the moment I know of no use for it,
and have provided it simply for orthogonality's sake.

This implementation returns an expression that matches nothing.

=end comment

=cut

sub __ignore_before_re {
    return qr< .{0} >smx;
}

=begin comment

=head2 __midnight

 say 'Midnight is ', $dmal->__midnight();

This method returns the representation of midnight in the current
language. This may be substituted into the string given to
L<Date::Manip|Date::Manip> to parse.

This class provides a default implementation that returns C<'00:00:00'>,
which ought to be pretty portable among languages, but individual
subclasses are free to override this as necessary.

=end comment

=cut

sub __midnight {
    return '00:00:00';
}

=begin comment

=head2 __normalize_capture

 my $normalized_capture = $dmad->__normalize_capture( $capture_name, $capture_content );

This method is called by L<__event_capture()|/__event_capture> when a
string is captured.  The arguments are the capture name and its
contents. The return is the contents normalized appropriately to the
language.

By default, it simply returns the capture buffer converted to lower
case, but individual languages can override it to do things like strip
diacriticals.

=end comment

=cut

sub __normalize_capture { return lc $_[2] }

=begin comment

=head2 __parse_pre

 my ( $modified_string, $body, @event ) =
   $dmal->__parse_pre( $string );

This method is intended to be called by a parse method before handing
off the parse to the superclass. If an almanac event is recognized, it
returns the a modification of the original string, the astronomical
body, and the event name and detail. If no almanac event is recognized,
only the originial string is returned.

The modified string has been processed by being converted to lower case,
having diacriticals stripped (heavy lifting done by
L<Unicode::Diacritic::Strip|Unicode::Diacritic::Strip>), and the event
replaced by the language equivalent of midnight.

The event name and detail are those expected by
L<Astro::Coord::ECI|Astro::Coord::ECI> (q.v.).

=end comment

=cut

sub __parse_pre {
    my ( $self, $string ) = @_;
    wantarray
	or confess 'Bug - must call in list context';

    unless ( $self->{_sky} ) {
	$self->{_sky} = \my @res;
	my $general_re = $self->__general_event_re();
	my $ignore_after_re = $self->__ignore_after_re();
	my $ignore_before_re = $self->__ignore_before_re();
	foreach my $body ( @{ $self->{sky} } ) {
	    my ( $body_re, $specific_re, $interp_specific ) =
		$self->__body_re( $body )
		or confess 'Bug - no re computed for ', $body->get( 'name' );
	    my $re = $specific_re ? qr/ \b $ignore_before_re? (?:
		$specific_re |
		(?: $body_re \s* $general_re ) |
		(?: $general_re \s* $body_re )
		) $ignore_after_re? \b /smxi
	    : qr/ \b $ignore_before_re? (?: (?: $body_re \s* $general_re ) |
		(?: $general_re \s* $body_re ) ) $ignore_after_re? \b /smxi;
	    push @res, [ $re, $body, $interp_specific ];
	}
    }

    ( my $match = $string ) =~ s/ \s+ / /smxg;

    foreach ( @{ $self->{_sky} } ) {
	my ( $re, $body, @se ) = @{ $_ };
	$match =~ s/ $re / $self->__event_capture( $body, @se ) /smxie
	    or next;
	# We may have captured the entire string. If so, we want today
	# at midnight. 'Today' is out because it is language-specific.
	# Midnight is considerably less so, and implies today.
	$match =~ m/ \S /smx
	    or $match = $self->__midnight();
	return ( $match, $body, $self->__event_retrieve() );
    }

    return ( $string );
}

=begin comment

=head2 __season_to_detail

 my @detail = $self->__season_to_detail();

This method returns an array that maps season number (Spring = 0 through
Winter = 3) to an L<Astro::Coord::ECI|Astro::Coord::ECI> seasonal event
detail number.  This is C<( 0 .. 3 )> in the Northern hemisphere, but
C<( 2, 3, 0, 1 )> in the Southern hemisphere.

With no justification but computational convenience, the Equator is
considered to be in the Northern hemisphere.

=end comment

=cut

sub __season_to_detail {
    my ( $self ) = @_;
    return @{ $self->{season} };
}

=begin comment

 my $key = $dmal->__string_to_key( $capture_name, $string );

This method converts a string to an equivalent (for our purposes)
hash key.

The idea is to mimic (probably badly) something like
L<Unicode::Collate|Unicode::Collate> level C<1>, but in a regular
expression. This is done by:

=over

=item 1) Calling __normalize_capture()

=item 2) Removing everything that is not a word character

=back

=end comment

=cut

sub __string_to_key {
    my ( $self, $name, $string ) = @_;
    my $key = $self->__normalize_capture( $name, $string );
    $key =~ s/ \W+ //smxg;
    return $key;
}

=begin comment

 my $re_string = $dmal->__string_to_re( $name, $string );

This method converts a string to an equivalent (for our purposes)
regular expression. The return is a string, not a C<Regexp> object,
though that is subject to change.

The C<$name> object says what the string is used for, and is simply
passed through to L<__normalize_capture()|/__normalize_capture>, which
does most of the work.

The idea is to mimic (probably badly) something like
L<Unicode::Collate|Unicode::Collate> level C<1>, but in a regular
expression. This is done by:

=over

=item 1) Calling __normalize_capture()

=item 2) Removing everything that is not a word character or a space

=item 3) Converting spaces to C<\s*>

=back

=end comment

=cut

sub __string_to_re {
    my ( $self, $name, $string ) = @_;
    my $re = $self->__normalize_capture( $name, $string );
    $re =~ s/ [^\w\s]+ //smxg;
    $re =~ s/ \s+ /\\s*/smxg;
    return $re;
}

1;

__END__

=head1 NAME

Date::ManipX::Almanac::Lang - Language support for Date::ManipX::Almanac

=head1 SYNOPSIS

The user does not directly interface with this module.

=head1 DESCRIPTION

L<Date::ManipX::Almanac|Date::ManipX::Almanac> supports (in principal)
multiple languages, using a model similar to the
L<Date::Manip|Date::Manip> model. But the language modules have been
given more functionality, since that implementation minimized the need
for access to L<Date::Manip|Date::Manip> internals.

This module and its language-specific subclasses recognize time
specifications that represent almanac events, and ultimately (after the
superclass completes the parse) computes the time of the desired event.

=head1 ASTRONOMICAL BODIES

Subclasses are expected to recognize astronomical bodies by their name
in the implemented language. For L<Astro::Coord::ECI|Astro::Coord::ECI>
subclasses that represent specific bodies, a hard-coded name in the
relevant language is expected. For other classes, the C<'name'>
attribute is used as a last-ditch, and probably-unsatisfactory solution.

Specifically, subclasses are expected to support language-specific names
for the following classes:

 Astro::Coord::ECI::Sun
 Astro::Coord::ECI::Moon
 Astro::Coord::ECI::VSOP87D::Sun
 Astro::Coord::ECI::VSOP87D::Mercury
 Astro::Coord::ECI::VSOP87D::Venus
 Astro::Coord::ECI::VSOP87D::Mars
 Astro::Coord::ECI::VSOP87D::Jupiter
 Astro::Coord::ECI::VSOP87D::Saturn
 Astro::Coord::ECI::VSOP87D::Uranus
 Astro::Coord::ECI::VSOP87D::Neptune

=head1 ALMANAC EVENTS

This section describes the events that subclasses are expected to
support, but B<not> the language-specific names of these events. It is
expected that the event names given will work in English, but others may
also work. See the individual language modules for details.

For the purpose of discussion, events are divided into two classes.
L<General Events|/General Events> are those that apply to any
astronomical body, and which therefore require the specification of the
body they apply to. L<Specific Events|/Specific Events> only apply to
one body, and therefore do not require the naming of a specific body.

=head1 General Events

General events must be immediately preceded or immediately followed by
the name of the astronomical body they apply to.

The following general events should be recognized by any subclass:

=over

=item Culminates

This is defined as the moment when the body appears highest in the sky.

=item Rise

This is defined as the moment when the upper limb of the body appears
above the horizon, after correcting for atmospheric refraction.

=item Set

This is defined as the moment when the upper limb of the body disappears
below the horizon, after correcting for atmospheric refraction.

=back

=head1 Specific Events

The following specific events should be recognized by any subclass:

=over

=item Phases of the Moon

 new
 first
 full
 last

This implies the Moon. It computes the first occurrence of the specified
phase on or after the specified date.

=item Solar quarters

 december solstice
 march equinox
 fall equinox
 june solstice
 september equinox
 spring equinox
 summer equinox
 vernal equinox
 winter solstice

This implies the Sun. It computes the first occurrence of the specified
quarter after the specified date. B<Note> that the time specified by the
seasonal names differs between Northern and Southern Hemispheres.

=item twilight

 begin twilight
 end twilight

This implies the Sun, and specifies the time the center of the Sun
passes above (C<'begin'>) or below (C<'end'>) the twilight setting of
the C<location> object. This defaults to civil twilight (in the U.S. at
least), or 6 degrees below the horizon.

=item noon

 local noon
 local midnight

This implies the Sun. The C<'local noon'> specification is equivalent to
C<'sun culminates'>.

=back

=head1 SEE ALSO

L<Date::ManipX::Almanac::Date|Date::ManipX::Almanac::Date>.

L<Date::ManipX::Almanac::Lang::english|Date::ManipX::Almanac::Lang::english>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Date-ManipX-Astro-Lang>,
L<https://github.com/trwyant/perl-Date-ManipX-Astro-Lang/issues/>, or in
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
