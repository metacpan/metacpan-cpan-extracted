package Astro::App::Satpass2::Locale::C;

use 5.008;

use strict;
use warnings;

use utf8;	# Not actually needed for C locale, but maybe for others

use Astro::Coord::ECI::TLE 0.059 qw{ :constants };
use Astro::App::Satpass2::Utils qw{ @CARP_NOT };
use Scalar::Util ();

our $VERSION = '0.040';

my @event_names;
$event_names[PASS_EVENT_NONE]		= '';
$event_names[PASS_EVENT_SHADOWED]	= 'shdw';
$event_names[PASS_EVENT_LIT]		= 'lit';
$event_names[PASS_EVENT_DAY]		= 'day';
$event_names[PASS_EVENT_RISE]		= 'rise';
$event_names[PASS_EVENT_MAX]		= 'max';
$event_names[PASS_EVENT_SET]		= 'set';
$event_names[PASS_EVENT_APPULSE]	= 'apls';
$event_names[PASS_EVENT_START]		= 'strt';
$event_names[PASS_EVENT_END]		= 'end';
$event_names[PASS_EVENT_BRIGHTEST]	= 'brgt';

my @sun_quarters = (
    'Spring equinox',
    'Summer solstice',
    'Autumn equinox',
    'Winter solstice',
);

# Any hash reference is a true value, but perlcritic seems not to know
# this.

{	## no critic (Modules::RequireEndWithOne)
    '+message'	=> {
    },
    '+template'	=> {

	# Local coordinates

	az_rng	=> <<'EOD',
[% data.azimuth( arg, bearing = 2 ) %]
    [%= data.range( arg ) -%]
EOD

	azel	=> <<'EOD',
[% data.elevation( arg ) %]
    [%= data.azimuth( arg, bearing = 2 ) -%]
EOD

	azel_rng	=> <<'EOD',
[% data.elevation( arg ) %]
    [%= data.azimuth( arg, bearing = 2 ) %]
    [%= data.range( arg ) -%]
EOD

	equatorial	=> <<'EOD',
[% data.right_ascension( arg ) %]
    [%= data.declination( arg ) -%]
EOD

	equatorial_rng	=> <<'EOD',
[% data.right_ascension( arg ) %]
    [%= data.declination( arg ) %]
    [%= data.range( arg ) -%]
EOD

	# Main templates

	almanac	=> <<'EOD',
[% UNLESS data %]
    [%- SET data = sp.almanac( arg ) %]
[%- END %]
[%- FOREACH item IN data %]
    [%- item.date %] [% item.time %]
        [%= item.almanac( units = 'description' ) %]
[% END -%]
EOD

	flare	=> <<'EOD',
[% UNLESS data %]
    [%- SET data = sp.flare( arg ) %]
[%- END %]
[%- CALL title.title_gravity( TITLE_GRAVITY_BOTTOM ) %]
[%- WHILE title.more_title_lines %]
    [%- title.time %]
        [%= title.name( width = 12 ) %]
        [%= title.local_coord %]
        [%= title.magnitude %]
        [%= title.angle( 'Degrees From Sun' ) %]
        [%= title.azimuth( 'Center Azimuth', bearing = 2 ) %]
        [%= title.range( 'Center Range', width = 6 ) %]

[%- END %]
[%- prior_date = '' -%]
[% FOR item IN data %]
    [%- center = item.center %]
    [%- current_date = item.date %]
    [%- IF prior_date != current_date %]
        [%- prior_date = current_date %]
        [%- current_date %]

    [%- END %]
    [%- item.time %]
        [%= item.name( units = 'title_case', width = 12 ) %]
        [%= item.local_coord %]
        [%= item.magnitude %]
        [%= IF 'day' == item.type( width = '' ) %]
            [%- item.appulse.angle %]
        [%- ELSE %]
            [%- item.appulse.angle( literal = 'night' ) %]
        [%- END %]
        [%= center.azimuth( bearing = 2 ) %]
        [%= center.range( width = 6 ) %]
[% END -%]
EOD

	list	=> <<'EOD',
[% UNLESS data %]
    [%- SET data = sp.list( arg ) %]
[%- END %]
[%- CALL title.title_gravity( TITLE_GRAVITY_BOTTOM ) %]
[%- WHILE title.more_title_lines %]
    [%- title.list %]
[% END %]
[%- FOR item IN data %]
    [%- item.list( arg ) %]
[% END -%]
EOD

	list_inertial	=> <<'EOD',
[% data.oid( align_left = 0, arg ) %] [% data.name( arg ) %]
    [%= data.epoch( arg ) %]
    [%= data.period( arg, align_left = 1 ) -%]
EOD

	list_fixed	=> <<'EOD',
[% data.oid( align_left = 0, arg ) %] [% data.name( arg ) %]
    [%= data.latitude( arg ) %]
    [%= data.longitude( arg ) %] [% data.altitude( arg ) -%]
EOD


	location	=> <<'EOD',
[% UNLESS data %]
    [%- SET data = sp.location( arg ) %]
[%- END -%]
[% localize( 'Location' ) %]: [% data.name( width = '' ) %]
          [% localize( 'Latitude' ) %] [% data.latitude( places = 4,
                width = '' ) %], [% localize( 'longitude' ) %]
            [%= data.longitude( places = 4, width = '' )
                %], [% localize( 'height' ) %]
            [%= data.altitude( units = 'meters', places = 0,
                width = '' ) %] m
EOD

	pass	=> <<'EOD',
[% UNLESS data %]
    [%- SET data = sp.pass( arg ) %]
[%- END %]
[%- CALL title.title_gravity( TITLE_GRAVITY_BOTTOM ) %]
[%- SET do_mag = sp.want_pass_variant( 'brightest' ) %]
[%- WHILE title.more_title_lines %]
    [%- title.time( align_left = 0 ) %]
        [%= title.local_coord %]
        [%= title.latitude %]
        [%= title.longitude %]
        [%= title.altitude %]
        [%= title.illumination %]
	[%- IF do_mag %]
	    [%= title.magnitude %]
	[%- END %]
        [%= title.event( width = '' ) %]

[%- END %]
[%- FOR pass IN data %]
    [%- events = pass.events %]
    [%- evt = events.first %]

    [%- evt.date %]    [% evt.oid %] - [% evt.name( width = '' ) %]

    [%- FOREACH evt IN events %]
        [%- evt.time %]
            [%= evt.local_coord %]
            [%= evt.latitude %]
            [%= evt.longitude %]
            [%= evt.altitude %]
            [%= evt.illumination %]
	    [%- IF do_mag %]
		[%= evt.magnitude %]
	    [%- END %]
            [%= evt.event( width = '' ) %]
        [%- IF 'apls' == evt.event( units = 'string', width = '' ) %]
            [%- apls = evt.appulse %]

            [%- title.time( '' ) %]
                [%= apls.local_coord %]
                [%= apls.angle %] degrees from [% apls.name( width = '' ) %]
        [%- END %]

    [%- END %]
[%- END -%]
EOD

	pass_events	=> <<'EOD',
[% UNLESS data %]
    [%- SET data = sp.pass( arg ) %]
[%- END %]
[%- CALL title.title_gravity( TITLE_GRAVITY_BOTTOM ) %]
[%- WHILE title.more_title_lines %]
    [%- title.date %] [% title.time %]
        [%= title.oid %] [% title.event %]
        [%= title.illumination %] [% title.local_coord %]

[%- END %]
[%- FOREACH evt IN data.events %]
    [%- evt.date %] [% evt.time %]
        [%= evt.oid %] [% evt.event %]
        [%= evt.illumination %] [% evt.local_coord %]
[% END -%]
EOD

	phase	=> <<'EOD',
[% UNLESS data %]
    [%- SET data = sp.phase( arg ) %]
[%- END %]
[%- CALL title.title_gravity( TITLE_GRAVITY_BOTTOM ) %]
[%- WHILE title.more_title_lines %]
    [%- title.date( align_left = 0 ) %]
        [%= title.time( align_left = 0 ) %]
        [%= title.name( width = 8, align_left = 0 ) %]
        [%= title.phase( places = 0, width = 4 ) %]
        [%= title.phase( width = 16, units = 'phase',
            align_left = 1 ) %]
        [%= title.fraction_lit( title = 'Lit', places = 0, width = 4,
            units = 'percent', align_left = 0 ) %]

[%- END %]
[%- FOR item IN data %]
    [%- item.date %] [% item.time %]
        [%= item.name( width = 8, align_left = 0 ) %]
        [%= item.phase( places = 0, width = 4 ) %]
        [%= item.phase( width = 16, units = 'phase',
            align_left = 1 ) %]
        [%= item.fraction_lit( places = 0, width = 4,
            units = 'percent' ) %]%
[% END -%]
EOD

	position	=> <<'EOD',
[% UNLESS data %]
    [%- SET data = sp.position( arg ) %]
[%- END %]
[%- CALL title.title_gravity( TITLE_GRAVITY_BOTTOM ) %]
[%- data.date %] [% data.time %]
[%- WHILE title.more_title_lines %]
    [%- title.name( align_left = 0, width = 16 ) %]
        [%= title.local_coord %]
        [%= title.epoch( align_left = 0 ) %]
        [%= title.illumination %]

[%- END %]
[%- FOR item IN data.bodies() %]
    [%- item.name( width = 16, missing = 'oid', align_left = 0 ) %]
        [%= item.local_coord %]
        [%= item.epoch( align_left = 0 ) %]
        [%= item.illumination %]

    [%- FOR refl IN item.reflections() %]
        [%- item.name( literal = '', width = 16 ) %]
            [%= item.local_coord( literal = '' ) %] MMA
        [%- IF refl.status( width = '' ) %]
            [%= refl.mma( width = '' ) %] [% refl.status( width = '' ) %]
        [%- ELSE %]
            [%= refl.mma( width = '' ) %] mirror angle [%
                refl.angle( width = '' ) %] magnitude [%
                refl.magnitude( width = '' ) %]
        [%- END %]

    [%- END -%]
[% END -%]
EOD

	tle		=> <<'EOD',
[% UNLESS data %]
    [%- SET data = sp.tle( arg ) %]
[%- END %]
[%- FOR item IN data %]
    [%- item.tle -%]
[% END -%]
EOD

	tle_verbose	=> <<'EOD',
[% UNLESS data %]
    [%- SET data = sp.tle( arg ) %]
[%- END %]
[%- CALL title.fixed_width( 0 ) -%]
[% FOR item IN data -%]
[% UNLESS item.tle -%]
[% NEXT -%]
[% END -%]
[% CALL item.fixed_width( 0 ) -%]
[% title.oid %]: [% item.oid %]
    [% title.name %]: [% item.name %]
    [% title.international %]: [% item.international %]
    [% title.epoch %]: [% item.epoch( units = 'zulu' ) %] GMT
    [% title.effective_date %]: [%
        item.effective_date( units = 'zulu',
        missing = '<none>' ) %] GMT
    [% title.classification %]: [% item.classification %]
    [% title.mean_motion %]: [% item.mean_motion( places = 8 )
        %] degrees/minute
    [% title.first_derivative %]: [%
        item.first_derivative( places = 8 ) %] degrees/minute squared
    [% title.second_derivative %]: [%
        item.second_derivative( places = 5 ) %] degrees/minute cubed
    [% title.b_star_drag %]: [% item.b_star_drag( places = 5 ) %]
    [% title.ephemeris_type %]: [% item.ephemeris_type %]
    [% title.inclination %]: [% item.inclination( places = 4 ) %] degrees
    [% title.ascending_node %]: [% item.ascending_node(
        places = 0 ) %] in right ascension
    [% title.eccentricity %]: [% item.eccentricity( places = 7 ) %]
    [% title.argument_of_perigee %]: [%
        item.argument_of_perigee( places = 4 )
        %] degrees from ascending node
    [% title.mean_anomaly %]: [%
        item.mean_anomaly( places = 4 ) %] degrees
    [% title.element_number %]: [% item.element_number %]
    [% title.revolutions_at_epoch %]: [% item.revolutions_at_epoch %]
    [% title.period %]: [% item.period %]
    [% title.semimajor %]: [% item.semimajor( places = 1 ) %] kilometers
    [% title.perigee %]: [% item.perigee( places = 1 ) %] kilometers
    [% title.apogee %]: [% item.apogee( places = 1 ) %] kilometers
[% END -%]
EOD
    },
    '-flare'	=> {
	string	=> {
	    'Degrees From Sun'	=> 'Degrees From Sun',
	    'Center Azimuth'	=> 'Center Azimuth',
	    'Center Range'	=> 'Center Range',
	    'night'		=> 'night',
	},
    },
    '-location'	=> {
	string	=> {
	    'Location'		=> 'Location',
	    'Latitude'		=> 'Latitude',
	    'longitude'		=> 'longitude',
	    'height'		=> 'height',
	},
    },
    almanac	=> {
	title	=> 'Almanac',
	Moon	=> {
	    horizon	=> [ 'Moon set', 'Moon rise' ],
	    quarter	=> [
			    'New Moon',
			    'First quarter Moon',
			    'Full Moon',
			    'Last quarter Moon',
	    ],
	    transit	=> [ undef, 'Moon transits meridian' ],
	},
	Sun	=> {
	    horizon	=> [ 'Sunset', 'Sunrise' ],
	    quarter	=> sub {
		my ( $key, $arg ) = @_;
		Scalar::Util::blessed( $arg )
		    and return $arg->__quarter_name( $key,
		    \@sun_quarters );
		return $sun_quarters[$key];
	    },
	    transit	=> [ 'local midnight', 'local noon' ],
	    twilight	=> [ 'end twilight', 'begin twilight' ],
	},
    },
    altitude	=> {
	title	=> 'Altitude',
    },
    angle	=> {
	title	=> 'Angle',
    },
    apoapsis	=> {
	title	=> 'Apoapsis',
    },
    apogee	=> {
	title	=> 'Apogee',
    },
    argument_of_perigee	=> {
	title	=> 'Argument Of Perigee',
    },
    ascending_node	=> {
	title	=> 'Ascending Node',
    },
    azimuth	=> {
	title	=> 'Azimuth',
    },
    bearing	=> {
	table	=> [
	    [ qw{ N E S W } ],
	    [ qw{ N NE E SE S SW W NW } ],
	    [ qw{ N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW
		NNW } ],
	],
    },
    b_star_drag	=> {
	title	=> 'B Star Drag',
    },
    classification	=> {
	title	=> 'Classification',
    },
    date	=> {
	title	=> 'Date',
    },
    declination	=> {
	title	=> 'Declination',
    },
    eccentricity	=> {
	title	=> 'Eccentricity',
    },
    effective_date	=> {
	title	=> 'Effective Date',
    },
    element_number	=> {
	title	=> 'Element Number',
    },
    elevation	=> {
	title	=> 'Elevation',
    },
    ephemeris_type	=> {
	title	=> 'Ephemeris Type',
    },
    epoch	=> {
	title	=> 'Epoch',
    },
    event	=> {
	table	=> [ @event_names ],
	title	=> 'Event',
    },
    first_derivative	=> {
	title	=> 'First Derivative',
    },
    fraction_lit	=> {
	title	=> 'Fraction Lit',
    },
    illumination	=> {
	title	=> 'Illumination',
    },
    inclination	=> {
	title	=> 'Inclination',
    },
    international	=> {
	title	=> 'International Launch Designator',
    },
    latitude	=> {
	title	=> 'Latitude',
    },
    longitude	=> {
	title	=> 'Longitude',
    },
    magnitude	=> {
	title	=> 'Magnitude',
    },
    maidenhead	=> {
	title	=> 'Maidenhead Grid Square',
    },
    mean_anomaly	=> {
	title	=> 'Mean Anomaly',
    },
    mean_motion	=> {
	title	=> 'Mean Motion',
    },
    mma	=> {
	title	=> 'MMA',
    },
    name	=> {
	title	=> 'Name',
	localize_value	=> {
	    Sun		=> 'Sun',
	    Moon	=> 'Moon',
	},
    },
    oid	=> {
	title	=> 'OID',
    },
    operational	=> {
	title	=> 'Operational',
    },
    periapsis	=> {
	title	=> 'Periapsis',
    },
    perigee	=> {
	title	=> 'Perigee',
    },
    period	=> {
	title	=> 'Period',
    },
    phase	=> {
	table	=> [
	    [ 6.1	=> 'new' ],
	    [ 83.9	=> 'waxing crescent' ],
	    [ 96.1	=> 'first quarter' ],
	    [ 173.9	=> 'waxing gibbous' ],
	    [ 186.1	=> 'full' ],
	    [ 263.9	=> 'waning gibbous' ],
	    [ 276.1	=> 'last quarter' ],
	    [ 353.9	=> 'waning crescent' ],
	],
	title	=> 'Phase',
    },
    range	=> {
	title	=> 'Range',
    },
    revolutions_at_epoch	=> {
	title	=> 'Revolutions At Epoch',
    },
    right_ascension	=> {
	title	=> 'Right Ascension',
    },
    second_derivative	=> {
	title	=> 'Second Derivative',
    },
    semimajor	=> {
	title	=> 'Semimajor Axis',
    },
    semiminor	=> {
	title	=> 'Semiminor Axis',
    },
    status	=> {
	title	=> 'Status',
    },
    time	=> {
	title	=> 'Time',
    },
    tle	=> {
	title	=> 'TLE',
    },
    type	=> {
	title	=> 'Type',
    },
};

__END__

=head1 NAME

Astro::App::Satpass2::Locale::C - Define the C locale for Astro::App::Satpass2

=head1 SYNOPSIS

 my $c_locale = require Astro::App::Satpass2::Locale::C;

=head1 DESCRIPTION

This Perl module defines the C locale (which is the default locale )for
L<Astro::App::Satpass2|Astro::App::Satpass2>.

All you do with this is load it. On a successful load it returns the
locale hash.

=head1 SUBROUTINES

None.

=head1 THE LOCALE DATA

The locale data are stored in a hash. The top-level key is always locale
code. This is either a two-character language code, lower-case (e.g.
C<'en'>, a language code and upper-case country code delimited by an
underscore (e.g. C<'en_US'>, or C<'C'> for the default locale.

The data for each locale key are a reference to a hash. The keys of this
hash are the names of
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
formats (e.g. C<{azimuth}>), the names of top-level reporting templates
preceded by a dash (e.g. C<{'-flare'}>, or the special keys
C<'{+message}'> (error messages) or C<'{+template}'> (templates).

The content of these second level hashes varies with its type, as
follows:

=head2 Format Effectors (e.g. C<{azimuth}>)

These are hashes containing data relevant to that format effector. The
C<{title}> key contains the title for that format effector. Other keys
relevant to the specific formatter may also appear, such as the
C<{table}> key in C<{phase}>, which defines the names of phases in terms
of phase angle. These extra keys are pretty much ad-hoc as required by
the individual format effector. In general they are cascades of C<HASH>
and/or C<ARRAY> references, though the last can be a C<CODE> reference.
The C<HASH> and C<ARRAY> references are resolved one at a time using
successive C<__localize()> arguments. A C<CODE> reference is resolved by
calling it passing the current C<__locale()> argument, and the original
C<__locale()> call's invocant argument (or C<undef> if none). See the
C<almanac> definition above for an example.

=head2 Top-level reporting (e.g. C<{'-flare'}>

The only key defined at the moment is C<{string}>, whose content is a
hash reference. This hash is keyed by text appearing as the values in
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
C<literal>, C<missing>, and C<title> arguments, and the corresponding
values are the translations of that text into the relevant locale.

For example, a Spanish localization for C<{'-flare'}> might be something
like

 {
   es => {
     string => {
       night => 'noche',
       ...
     }
   }
 }

=head2 C<{'+message'}>

The value of this key is a hash whose keys are message text as coded in
this program, and whose values are the message text as it should appear
in the relevant locale. These are typically to be consumed by the locale
system's C<__message()> subroutine.

=head2 C<{'+template'}>

The value of this key is a hash whose keys are template names used by
L<Astro::App::Satpass2::Format::Template|Astro::App::Satpass2::Format::Template>,
and whose values are the templates themselves in the relevant locale.

=head1 SEE ALSO

L<Astro::App::Satpass2::Locale|Astro::App::Satpass2::Locale>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
