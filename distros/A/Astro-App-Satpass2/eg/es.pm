# package Astro::App::Satpass2::Locale::es;

use 5.008;

use strict;
use warnings;

use utf8;

use Astro::Coord::ECI::TLE 0.059 qw{ :constants };
our $VERSION = '0.040';

my @event_names;
$event_names[PASS_EVENT_NONE]		= '';
$event_names[PASS_EVENT_SHADOWED]	= 'somb';
$event_names[PASS_EVENT_LIT]		= 'ilum';
$event_names[PASS_EVENT_DAY]		= 'diur';
$event_names[PASS_EVENT_RISE]		= 'sali';
$event_names[PASS_EVENT_MAX]		= 'culm';
$event_names[PASS_EVENT_SET]		= 'pues';
$event_names[PASS_EVENT_APPULSE]	= 'apls';
$event_names[PASS_EVENT_START]		= 'inic';
$event_names[PASS_EVENT_END]		= 'term';
$event_names[PASS_EVENT_BRIGHTEST]	= 'bril';

my @sun_quarters = (
    'Equinoccio de primavera',
    'Solsticio de verano',
    'Equinoccio de otoño',
    'Solsticio de invierno',
);

# Any hash reference is a true value, but perlcritic seems not to know
# this.

{	## no critic (Modules::RequireEndWithOne)
    '-flare'	=> {
	string	=> {
	    'Degrees From Sun'	=> 'Ángulo desde el sol',
	    'Center Azimuth'	=> 'Azimut del centro',
	    'Center Range'	=> 'Distancia desde el centro',
	    'night'		=> 'noche',
	},
    },
    '-location'	=> {
	string	=> {
	    'Location'		=> 'Posición',
	    'Latitude'		=> 'Latitud',
	    'longitude'		=> 'longitud',
	    'height'		=> 'altura',
	},
    },
    almanac	=> {
	title	=> 'Almanaque',
	Moon	=> {
	    horizon	=> [ 'Puesta de la Luna', 'Salida de la luna' ],
	    quarter	=> [
			    'La luna nueva',
			    'Primer cuarto de la luna',
			    'La luna llena',
			    'Último cuarto de la luna',
	    ],
	    transit	=> [ undef, 'La luna tránsitos meridianos' ],
	},
	Sun	=> {
	    horizon	=> [ 'Puesta del sol', 'Salida del sol' ],
	    quarter	=> sub {
		my ( $key, $arg ) = @_;
		Scalar::Util::blessed( $arg )
		    and return $arg->__quarter_name( $key,
		    \@sun_quarters );
		return $sun_quarters[$key];
	    },
	    transit	=> [ 'La medianoche local', 'La mediodía local' ],
	    twilight	=> [ 'El fin del crepúsculo', 'El comienzo del crepúsculo' ],
	},
    },
    altitude	=> {
	title	=> 'Altitud',
    },
    angle	=> {
	title	=> 'Ángulo',
    },
    apoapsis	=> {
	title	=> 'Apoapsis',
    },
    apogee	=> {
	title	=> 'Apogeo',
    },
    argument_of_perigee	=> {
	title	=> 'Argumento De Perigeo',
    },
    ascending_node	=> {
	title	=> 'Nodo Ascendante',
    },
    azimuth	=> {
	title	=> 'Azimut',
    },
    bearing	=> {
	table	=> [
	    [ qw{ N E S O } ],
	    [ qw{ N NE E SE S SO O NO } ],
	    [ qw{ N NNE NE ENE E ESE SE SSE S SSO SO OSO O ONO NO NNO } ],
	],
    },
    b_star_drag	=> {
	title	=> 'B Asterisco Arrastre',
    },
    classification	=> {
	title	=> 'Clasificación',
    },
    date	=> {
	title	=> 'Fecho',
    },
    declination	=> {
	title	=> 'Declinación',
    },
    eccentricity	=> {
	title	=> 'Excentricidad',
    },
    effective_date	=> {
	title	=> 'Fecha de Vigencia',
    },
    element_number	=> {
	title	=> 'Número de Elemento',
    },
    elevation	=> {
	title	=> 'Elevación',
    },
    ephemeris_type	=> {
	title	=> 'Tipo de Efemérides',
    },
    epoch	=> {
	title	=> 'Época',
    },
    event	=> {
	table	=> [ @event_names ],
	title	=> 'Evento',
    },
    first_derivative	=> {
	title	=> 'Primera Derivada',
    },
    fraction_lit	=> {
	title	=> 'Fracción Iluminada',
    },
    illumination	=> {
	title	=> 'Iluminación',
    },
    inclination	=> {
	title	=> 'Inclinación',
    },
    international	=> {
	title	=> 'Designador de Lanzamiento Internacional',
    },
    latitude	=> {
	title	=> 'Latitud',
    },
    longitude	=> {
	title	=> 'Longitud',
    },
    magnitude	=> {
	title	=> 'Magnitud',
    },
    maidenhead	=> {
	title	=> 'Maidenhead Localizador de cuadrícula',
    },
    mean_anomaly	=> {
	title	=> 'Anomalía Media',
    },
    mean_motion	=> {
	title	=> 'Movimiento Medio',
    },
    mma	=> {
	title	=> 'MMA',
    },
    name	=> {
	title	=> 'Nombre',
	localize_value	=> {
	    Sun		=> 'El sol',
	    Moon	=> 'La luna',
	},
    },
    oid	=> {
	title	=> 'OID',
    },
    operational	=> {
	title	=> 'Operacional',
    },
    periapsis	=> {
	title	=> 'Periapsis',
    },
    perigee	=> {
	title	=> 'Perigeo',
    },
    period	=> {
	title	=> 'Periodo',
    },
    phase	=> {
	table	=> [
	    [ 6.1	=> 'nueva' ],
	    [ 83.9	=> 'creciente' ],
	    [ 96.1	=> 'primer cuarto' ],
	    [ 173.9	=> 'creciente gibosa' ],
	    [ 186.1	=> 'llena' ],
	    [ 263.9	=> 'menguante gibosa' ],
	    [ 276.1	=> 'último cuarto' ],
	    [ 353.9	=> 'menguante' ],
	],
	title	=> 'Fase',
    },
    range	=> {
	title	=> 'Distancia',
    },
    revolutions_at_epoch	=> {
	title	=> 'Las Revoluciones en Época',
    },
    right_ascension	=> {
	title	=> 'Ascensión Recta',
    },
    second_derivative	=> {
	title	=> 'Segunda Derivada',
    },
    semimajor	=> {
	title	=> 'Semieje Mayor',
    },
    semiminor	=> {
	title	=> 'Semieje Menor',
    },
    status	=> {
	title	=> 'Estatus',
    },
    time	=> {
	title	=> 'Hora',
    },
    tle	=> {
	title	=> 'TLE',
    },
    type	=> {
	title	=> 'Tipo',
    },
};

__END__

=head1 NAME

es - Define the es locale for Astro::App::Satpass2, user-specific.

=head1 SYNOPSIS

 my $es_locale = do 'locale/es.pm';

=head1 DESCRIPTION

This chunk of Perl code defines the C<es> locale. It is intended to go
in the user's configuration directory. If it had a proper package
declaration and were in the right directory, it would work as a global
es locale.

All you do with this is load it. On a successful load it returns the
locale hash.

=head1 SUBROUTINES

None.

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
