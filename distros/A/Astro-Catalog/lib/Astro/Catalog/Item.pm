package Astro::Catalog::Item;

=head1 NAME

Astro::Catalog::Item - A generic star object in a stellar catalogue.

=head1 SYNOPSIS

    $star = new Astro::Catalog::Item(
        ID           => $id,
        Coords       => new Astro::Coords(),
        Morphology   => new Astro::Catalog::Item::Morphology(),
        Fluxes       => new Astro::Fluxes(),
        Quality      => $quality_flag,
        Field        => $field,
        GSC          => $in_gsc,
        Distance     => $distance_to_centre,
        PosAngle     => $position_angle,
        X            => $x_pixel_coord,
        Y            => $y_pixel_coord,
        WCS          => new Starlink::AST(),
        Comment      => $comment_string
        SpecType     => $spectral_type,
        StarType     => $star_type,
        LongStarType => $long_star_type,
        MoreInfo     => $url,
        InsertDate   => new Time::Piece(),
        Misc         => $hash_ref,
    );

=head1 DESCRIPTION

Stores generic meta-data about an individual stellar object from a catalogue.

If the catalogue has a field center the Distance and Position Angle properties
should be used to store the direction to the field center, e.g. a star from the
USNO-A2 catalogue retrieived from the ESO/ST-ECF Archive will have these
properties.

=cut


use strict;
use warnings;
use Carp;
use Astro::Coords 0.12;
use Astro::Catalog::Item::Morphology;
use Astro::Fluxes;
use Astro::Flux;
use Astro::FluxColor;

# Register an Astro::Catalog::Item warning category
use warnings::register;

our $VERSION = '4.36';

# Internal lookup table for Simbad star types
my %STAR_TYPE_LOOKUP = (
    'vid' => 'Underdense region of the Universe',
    'Er*' => 'Eruptive variable Star',
    'Rad' => 'Radio-source',
    'Q?' => 'Possible Quasar',
    'IR' => 'Infra-Red source',
    'SB*' => 'Spectrocopic binary',
    'C*' => 'Carbon Star',
    'Gl?' => 'Possible Globular Cluster',
    'DNe' => 'Dark Nebula',
    'GlC' => 'Globular Cluster',
    'No*' => 'Nova',
    'V*?' => 'Star suspected of Variability',
    'LeG' => 'Gravitationnaly Lensed Image of a Galaxy',
    'mAL' => 'metallic Absorption Line system',
    'LeI' => 'Gravitationnaly Lensed Image',
    'WU*' => 'Eclipsing binary of W UMa type',
    'Be*' => 'Be Star',
    'PaG' => 'Pair of Galaxies',
    'Mas' => 'Maser',
    'LeQ' => 'Gravitationnaly Lensed Image of a Quasar',
    'mul' => 'Composite object',
    'SBG' => 'Starburst Galaxy',
    '*' => 'Star',
    'gam' => 'gamma-ray source',
    'bL*' => 'Eclipsing binary of beta Lyr type',
    'S*' => 'S Star',
    'El*' => 'Elliptical variable Star',
    'GNe' => 'Galactic Nebula',
    'DQ*' => 'Cataclysmic Var. DQ Her type',
    '?' => 'Object of unknown nature',
    'WV*' => 'Variable Star of W Vir type',
    'SR?' => 'SuperNova Remnant Candidate',
    'Bla' => 'Blazar',
    'G' => 'Galaxy',
    'SCG' => 'Supercluster of Galaxies',
    'OH*' => 'Star with envelope of OH/IR type',
    'Lev' => '(Micro)Lensing Event',
    'BNe' => 'Bright Nebula',
    'RV*' => 'Variable Star of RV Tau type',
    'IR0' => 'IR source at lambda < 10 microns',
    'OVV' => 'Optically Violently Variable object',
    'a2*' => 'Variable Star of alpha2 CVn type',
    'IR1' => 'IR source at lambda > 10 microns',
    'Em*' => 'Emission-line Star',
    'PM*' => 'High proper-motion Star',
    'X' => 'X-ray source',
    'HzG' => 'Galaxy with high redshift',
    'Sy*' => 'Symbiotic Star',
    'LXB' => 'Low Mass X-ray Binary',
    '*i*' => 'Star in double system',
    'Sy1' => 'Seyfert 1 Galaxy',
    'Sy2' => 'Seyfert 2 Galaxy',
    'LIN' => 'LINER-type Active Galaxy Nucleus',
    'rG' => 'Radio Galaxy',
    'Cl*' => 'Cluster of Stars',
    'NL*' => 'Nova-like Star',
    'HV*' => 'High-velocity Star',
    'EmG' => 'Emission-line galaxy',
    '*iA' => 'Star in Association',
    'grv' => 'Gravitational Source',
    '*iC' => 'Star in Cluster',
    'SyG' => 'Seyfert Galaxy',
    'RNe' => 'Reflection Nebula',
    'EmO' => 'Emission Object',
    'Ce*' => 'Classical Cepheid variable Star',
    'CV*' => 'Cataclysmic Variable Star',
    '*iN' => 'Star in Nebula',
    'BY*' => 'Variable of BY Dra type',
    'Pe*' => 'Peculiar Star',
    'AM*' => 'Cataclysmic Var. AM Her type',
    'FU*' => 'Variable Star of FU Ori type',
    'HVC' => 'High-velocity Cloud',
    'ClG' => 'Cluster of Galaxies',
    'Ir*' => 'Variable Star of irregular type',
    'PN?' => 'Possible Planetary Nebula',
    'ALS' => 'Absorption Line system',
    'cm' => 'centimetric Radio-source',
    'As*' => 'Association of Stars',
    'V*' => 'Variable Star',
    'Fl*' => 'Flare Star',
    'EB*' => 'Eclipsing binary',
    'CGG' => 'Compact Group of Galaxies',
    'UV' => 'UV-emission source',
    'Ro*' => 'Rotationally variable Star',
    'SN*' => 'SuperNova',
    'pr*' => 'Pre-main sequence Star',
    'CH*' => 'Star with envelope of CH type',
    'Al*' => 'Eclipsing binary of Algol type',
    'Pu*' => 'Pulsating variable Star',
    'Cld' => 'Cloud of unknown nature',
    'QSO' => 'Quasar',
    'Psr' => 'Pulsars',
    'GiC' => 'Galaxy in Cluster of Galaxies',
    'V* RI*' => 'Variable Star with rapid variations',
    'sh' => 'HI shell',
    'GiG' => 'Galaxy in Group of Galaxies',
    'OpC' => 'Open (galactic) Cluster',
    'WR*' => 'Wolf-Rayet Star',
    'BCG' => 'Blue compact Galaxy',
    'blu' => 'Blue object',
    'GiP' => 'Galaxy in Pair of Galaxies',
    'LyA' => 'Ly alpha Absorption Line system',
    'CGb' => 'Cometary Globule',
    '**' => 'Double or multiple star',
    'H2G' => 'HII Galaxy',
    'RR*' => 'Variable Star of RR Lyr type',
    'HB*' => 'Horizontal Branch Star',
    'RC*' => 'Variable Star of R CrB type',
    'SNR' => 'SuperNova Remnant',
    'MoC' => 'Molecular Cloud',
    'HXB' => 'High Mass X-ray Binary',
    'mR' => 'metric Radio-source',
    'TT*' => 'T Tau-type Star',
    'DN*' => 'Dwarf Nova',
    'eg sr*' => 'Semi-regular pulsating Star',
    'HII' => 'HII (ionized) region',
    'HH' => 'Herbig-Haro Object',
    'HI' => 'HI (neutral) region',
    'WD*' => 'White Dwarf',
    'Or*' => 'Variable Star in Orion Nebula',
    'dS*' => 'Variable Star of delta Sct type',
    'DLy' => 'Dumped Ly alpha Absorption Line system',
    'AGN' => 'Active Galaxy Nucleus',
    'GrG' => 'Group of Galaxies',
    'Mi*' => 'Variable Star of Mira Cet type',
    'RS*' => 'Variable of RS CVn type',
    'mm' => 'millimetric Radio-source',
    'red' => 'Very red source',
    'BLL' => 'BL Lac - type object',
    'reg' => 'Region defined in the sky',
    'PN' => 'Planetary Nebula',
    'ZZ*' => 'Variable White Dwarf of ZZ Cet type',
    'gB' => 'gamma-ray Burster',
    'PoC' => 'Part of Cloud',
    'XB*' => 'X-ray Binary',
    'PoG' => 'Part of a Galaxy',
    'Neb' => 'Nebula of unknown nature'
);

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

    $star = new Astro::Catalog::Item(
        ID           => $id,
        Coords       => new Astro::Coords(),
        Morphology   => new Astro::Catalog::Item::Morphology(),
        Fluxes       => new Astro::Fluxes(),
        Quality      => $quality_flag,
        Field        => $field,
        GSC          => $in_gsc,
        Distance     => $distance_to_centre,
        PosAngle     => $position_angle,
        X            => $x_pixel_coord,
        Y            => $y_pixel_coord,
        Comment      => $comment_string
        SpecType     => $spectral_type,
        StarType     => $star_type,
        LongStarType => $long_star_type,
        MoreInfo     => $url,
        InsertDate   => new Time::Piece(),
        Misc         => $misc,
    );

returns a reference to an Astro::Catalog::Item object.

The coordinates can also be specified as individual RA and Dec values
(sexagesimal format) if they are known to be J2000.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # bless the query hash into the class
    my $block = bless {
        ID         => undef,
        FLUXES     => undef,
        MORPHOLOGY => undef,
        QUALITY    => undef,
        FIELD      => undef,
        GSC        => undef,
        DISTANCE   => undef,
        POSANGLE   => undef,
        COORDS     => undef,
        X          => undef,
        Y          => undef,
        WCS        => undef,
        COMMENT    => undef,
        SPECTYPE   => undef,
        STARTYPE   => undef,
        LONGTYPE   => undef,
        MOREINFO   => undef,
        INSERTDATE => undef,
        PREFERRED_MAG_TYPE => undef,
        MISC => undef,
    }, $class;

    # If we have arguments configure the object
    $block->configure( @_ ) if @_;

    return $block;
}

=back

=head2 Accessor Methods

=over 4

=item B<id>

Return (or set) the ID of the star

    $id = $star->id();
    $star->id( $id );

If an Astro::Coords object is associated with the Star, the name
field is set in the underlying Astro::Coords object as well as in
the current Star object.

=cut

sub id {
    my $self = shift;
    if (@_) {
        $self->{ID} = shift;

        my $c = $self->coords;
        $c->name($self->{ID}) if defined $c;
    }
    return $self->{ID};
}

=item B<coords>

Return or set the coordinates of the star as an C<Astro::Coords>
object.

    $c = $star->coords();
    $star->coords($c);

The object returned by this method is the actual object stored
inside this Star object and not a clone. If the coordinates
are changed through this object the coordinate of the star is
also changed.

Currently, if you modify the RA or Dec through the ra()
or dec() methods of Star, the internal object associated with
the Star will change.

Returns undef if the coordinates have never been specified.

If the name() field is defined in the Astro::Coords object
the id() field is set in the current Star object. Similarly for
the comment field.

=cut

sub coords {
    my $self = shift;
    if (@_) {
        my $c = shift;
        croak "Coordinates must be an Astro::Coords object"
            unless UNIVERSAL::isa($c, "Astro::Coords");

        # force the ID and comment to match
        $self->id($c->name) if defined $c->name;
        $self->comment($c->comment) if $c->comment;

        # Store the new coordinate object
        # Storing it late stops looping from the id and comment methods
        $self->{COORDS} = $c;
    }
    return $self->{COORDS};
}

=item B<ra>

Return (or set) the current object R.A. (J2000).

    $ra = $star->ra();

If the Star is associated with a moving object such as a planet,
comet or asteroid this method will return the J2000 RA associated
with the time and observer position associated with the coordinate
object itself (by default current time, longitude of 0 degrees).
Returns undef if no coordinate has been associated with this star.

    $star->ra($ra);

The RA can be changed using this method but only if the coordinate
object is associated with a fixed position. Attempting to change the
J2000 RA of a moving object will fail. If an attempt is made to
change the RA when no coordinate is associated with this object then
a new Astro::Coords object will be created (with a
Dec of 0.0).

RA accepted by this method must be in sexagesimal format, space or
colon-separated. Returns a space-separated sexagesimal number.


=cut

sub ra {
    my $self = shift;
    if (@_) {
        my $ra = shift;

        # Issue a warning specifically for this call
        my @info = caller();
        warnings::warnif("deprecated","Use of ra() method for setting RA now deprecated. Please use the coords() method instead, at $info[1] line $info[2]");


        # Get the coordinate object
        my $c = $self->coords;
        if (defined $c) {
            # Need to tweak RA?
            croak "Can only adjust RA with Astro::Coords::Equatorial coordinates"
                unless $c->isa("Astro::Coords::Equatorial");

            # For now need to kluge since Astro::Coords does not allow
            # you to change the position (it is an immutable object)
            $c = $c->new(
                type => 'J2000',
                dec => $c->dec(format => 's'),
                ra => $ra,
            );

        }
        else {
            $c = new Astro::Coords(
                type => 'J2000',
                ra => $ra,
                dec => '0',
            );
        }

        # Update the object
        $self->coords($c);
    }

    my $outc = $self->coords;
    return unless defined $outc;

    # Astro::Coords inserts colons by default. Grab the old delimiter
    # and number of decimal places if we're using a recent enough
    # version of Astro::Coords.
    my $ra = $outc->ra;
    if (UNIVERSAL::isa($ra, "Astro::Coords::Angle")) {
        $ra->str_delim(' ');
        $ra->str_ndp(2);
        return "$ra";
    }
    else {
        my $outra = $outc->ra(format => 's');
        $outra =~ s/:/ /g;
        $outra =~ s/^\s*//;

        return $outra;
    }
}

=item B<dec>

Return (or set) the current object Dec (J2000).

    $dec = $star->dec();

If the Star is associated with a moving object such as a planet,
comet or asteroid this method will return the J2000 Dec associated
with the time and observer position associated with the coordinate
object itself (by default current time, longitude of 0 degrees).
Returns undef if no coordinate has been associated with this star.

    $star->dec( $dec );

The Dec can be changed using this method but only if the coordinate
object is associated with a fixed position. Attempting to change the
J2000 Dec of a moving object will fail. If an attempt is made to
change the Dec when no coordinate is associated with this object then
a new Astro::Coords object will be created (with a
Dec of 0.0).

Dec accepted by this method must be in sexagesimal format, space or
colon-separated. Returns a space-separated sexagesimal number
with a leading sign.

=cut

sub dec {
    my $self = shift;
    if (@_) {
        my $dec = shift;

        # Issue a warning specifically for this call
        my @info = caller();
        warnings::warnif("deprecated","Use of ra() method for setting RA now deprecated. Please use the coords() method instead, at $info[1] line $info[2]");

        # Get the coordinate object
        my $c = $self->coords;
        if (defined $c) {
            # Need to tweak RA?
            croak "Can only adjust Dec with Astro::Coords::Equatorial coordinates"
                unless $c->isa("Astro::Coords::Equatorial");

            # For now need to kluge since Astro::Coords does not allow
            # you to change the position (it is an immutable object)
            $c = $c->new(
                type => 'J2000',
                ra => $c->ra(format => 's'),
                dec => $dec,
            );

        }
        else {
            $c = new Astro::Coords(
                type => 'J2000',
                dec => $dec,
                ra => 0,
            );
        }

        # Update the object
        $self->coords($c);
    }

    my $outc = $self->coords;
    return unless defined $outc;

    # Astro::Coords inserts colons by default. Grab the old delimiter
    # and number of decimal places if we're using a recent enough
    # version of Astro::Coords.
    my $dec = $outc->dec;
    if (UNIVERSAL::isa($dec, "Astro::Catalog::Angle")) {
        $dec->str_delim(' ');
        $dec->str_ndp(2);
        $dec = "$dec";
        $dec = (substr($dec, 0, 1) eq '-' ? '' : '+') . $dec;
        return $dec;
    }
    else {
        my $outdec = $outc->dec(format => 's');
        $outdec =~ s/:/ /g;
        $outdec =~ s/^\s*//;

        # require leading sign for backwards compatibility
        # Sign will be there for negative
        $outdec = (substr($outdec, 0, 1) eq '-' ? '' : '+') . $outdec;

        return $outdec;
    }
}

=item B<fluxes>

Return or set the flux measurements of the star as an C<Astro::Fluxes>
object.

    $f = $star->fluxes();
    $star->fluxes($f);

    $star->fluxes($f, 1);  # will replace instead of appending


The object returned by this method is the actual object stored
inside this Item object and not a clone. If the flux values
are changed through this object the flu values of the star is
also changed.

If an optional flag is passed as set to the routine it will replace
instead of appending (default action) to an existing fluxes object
in the catalogue.

Returns undef if the fluxes have never been specified.

=cut

sub fluxes {
    my $self = shift;
    if (@_) {
        my $flux = shift;
        my $flag = shift;
        croak "Flux must be an Astro::Fluxes object"
            unless UNIVERSAL::isa($flux, "Astro::Fluxes");

        if (defined $self->{FLUXES}) {
            if (defined $flag) {
                $self->{FLUXES} = $flux;
            }
            else {
                $self->{FLUXES}->merge( $flux );
            }
        }
        else {
            $self->{FLUXES} = $flux;
        }
    }
    return $self->{FLUXES};
}

=item B<what_filters>

Returns a list of the wavebands for which the object has defined values.

    @filters = $star->what_filters();
    $num = $star->what_filters();

if called in a scalar context it will return the number of filters which
have defined magnitudes in the object. It will included 'derived' values,
see C<Astro::Flux> for details.

=cut

sub what_filters {
    my $self = shift;

    my $fluxes = $self->{FLUXES};

    my @mags = $fluxes->original_wavebands('filters') if defined $fluxes;

    # return array of filters or number if called in scalar context
    return wantarray ? @mags : scalar(@mags);
}

=item B<what_colours>

Returns a list of the colours for which the object has defined values.

    @colours = $star->what_colours();
    $num = $star->what_colours();

if called in a scalar context it will return the number of colours which
have defined values in the object.

=cut

sub what_colours {
    my $self = shift;

    my $fluxes = $self->{FLUXES};
    my @cols = $fluxes->original_colors() if defined $fluxes;

    # return array of colours or number if called in scalar context
    return wantarray ? @cols : scalar(@cols);
}

=item B<get_magnitude>

Returns the magnitude for the supplied filter if available

    $magnitude = $star->get_magnitude('B');

=cut

sub get_magnitude {
  my $self = shift;

  my $magnitude;
  if (@_) {
     # grab passed filter
     my $filter = shift;
     my $fluxes = $self->{FLUXES};
     $magnitude = $fluxes->flux(
        waveband => $filter,
        type => $self->preferred_magnitude_type);

     if (defined($magnitude)) {
       return $magnitude->quantity($self->preferred_magnitude_type);
     }
     else {
       return undef;
     }
  }
}

=item B<get_flux_quantity>

Returns the flux quantity for the given waveband and flux type.

    my $flux = $star->get_flux_quantity(
        waveband => 'B',
        type => 'mag');

The arguments are passed as a hash. The value for the waveband
argument can be either a string describing a filter or an
Astro::WaveBand object. The value for the flux type is
case-insensitive.

Returns a scalar.

=cut

sub get_flux_quantity {
    my $self = shift;
    my %args = @_;

    unless (defined $args{'waveband'}) {
        croak "Must supply waveband to Astro::Catalog::Item->get_flux_quantity()";
    }
    unless (defined $args{'type'}) {
        croak "Must supply flux type to Astro::Catalog::Item->get_flux_quantity()";
    }

    my $waveband;
    unless (UNIVERSAL::isa($args{'waveband'}, "Astro::WaveBand")) {
        $waveband = new Astro::WaveBand(Filter => $args{'waveband'});
    }
    else {
        $waveband = $args{'waveband'};
    }

    my $fluxes = $self->fluxes;
    if (defined $fluxes) {
        my $flux = $fluxes->flux(waveband => $waveband, type => $args{'type'});
        if (defined $flux) {
            return $flux->quantity($args{'type'} );
        }
    }
    return undef;
}

=item B<get_errors>

Returns the error in the magnitude value for the supplied filter if available

    $mag_errors = $star->get_errors('B');

=cut

sub get_errors {
    my $self = shift;

    my $mag_error;
    if (@_) {
        # grab passed filter
        my $filter = shift;
        my $fluxes = $self->{FLUXES};
        my $magnitude = $fluxes->flux(
            waveband => $filter,
            type => $self->preferred_magnitude_type);
        if (defined $magnitude) {
            return $magnitude->error( $self->preferred_magnitude_type );
        }
        else {
            return undef;
        }
    }
    return $mag_error;
}

=item B<get_flux_error>

Returns the flux error for the given waveband and flux type.

    my $flux = $star->get_flux_error(
        waveband => 'B',
        type => 'mag');

The arguments are passed as a hash. The value for the waveband
argument can be either a string describing a filter or an
Astro::WaveBand object. The value for the flux type is
case-insensitive.

Returns a scalar.

=cut

sub get_flux_error {
    my $self = shift;
    my %args = @_;

    unless (defined $args{'waveband'}) {
        croak "Must supply waveband to Astro::Catalog::Item->get_flux_error()";
    }
    unless(defined $args{'type'}) {
        croak "Must supply flux type to Astro::Catalog::Item->get_flux_error()";
    }

    my $waveband;
    unless (UNIVERSAL::isa($args{'waveband'}, "Astro::WaveBand")) {
        $waveband = new Astro::WaveBand(Filter => $args{'waveband'});
    }
    else {
        $waveband = $args{'waveband'};
    }
    my $fluxes = $self->fluxes;
    if (defined $fluxes) {
        my $flux = $fluxes->flux(waveband => $waveband, type => $args{'type'});
        if (defined $flux) {
            return $flux->error($args{'type'});
        }
    }
    return undef;
}

=item B<get_colour>

Returns the value of the supplied colour if available

    $colour = $star->get_colour('B-V');

=cut

sub get_colour {
    my $self = shift;

    my $value;
    if (@_) {
        # grab passed colour
        my $colour = shift;
        my @filters = split "-", $colour;
        my $fluxes = $self->{FLUXES};
        my $color = $fluxes->color(
            upper => new Astro::WaveBand(Filter => $filters[0]),
            lower => new Astro::WaveBand(Filter => $filters[1]));
        $value = $color->quantity('mag');
    }
    return $value;
}

=item B<get_colourerror>

Returns the error in the colour value for the supplied colour if available

    $col_errors = $star->get_colourerr('B-V');

=cut

sub get_colourerr {
    my $self = shift;

    my $col_error;
    if (@_) {
        # grab passed colour
        my $colour = shift;
        my @filters = split "-", $colour;
        my $fluxes = $self->{FLUXES};
        my $color = $fluxes->color(
            upper => new Astro::WaveBand(Filter => $filters[0]),
            lower => new Astro::WaveBand(Filter => $filters[1]));

        $col_error = $color->error('mag');
    }
    return $col_error;
}

=item B<preferred_magnitude_type>

Get or set the preferred magnitude type to be returned from the get_magnitude method.

    my $type = $item->preferred_magnitude_type;
    $item->preferred_magnitude_type('MAG_ISO');

Defaults to 'MAG'.

=cut

sub preferred_magnitude_type {
    my $self = shift;
    if (@_) {
        my $type = shift;
        $self->{PREFERRED_MAG_TYPE} = $type;
    }

    unless (defined $self->{PREFERRED_MAG_TYPE}) {
        $self->{PREFERRED_MAG_TYPE} = 'MAG';
    }

    return $self->{PREFERRED_MAG_TYPE};
}

=item B<morphology>

Get or set the morphology of the star as an C<Astro::Catalog::Item::Morphology>
object.

    $star->morphology($morphology);

The object returned by this method is the actual object stored
inside this Star object and not a clone. If the morphology
is changed through this object the morphology of the star is
also changed.

=cut

sub morphology {
    my $self = shift;
    if (@_) {
        my $m = shift;
        croak "Morphology must be an Astro::Catalog::Item::Morphology object"
            unless UNIVERSAL::isa($m, "Astro::Catalog::Item::Morphology");

        # Store the new coordinate object
        # Storing it late stops looping from the id and comment methods
        $self->{MORPHOLOGY} = $m;
    }
    return $self->{MORPHOLOGY};
}

=item B<quality>

Return (or set) the quality flag of the star

    $quality = $star->quailty();
    $star->quality(0);

for example for the USNO-A2 catalogue, 0 denotes good quality, and 1
denotes a possible problem object. In the generic case any flag value,
including a boolean, could be used.

These quality flags are standardised sybolically across catalogues and
have the following definitions:

    STARGOOD
    STARBAD

TBD. Need to provide quality constants and mapping to and from these
constants on catalog I/O.

=cut

sub quality {
    my $self = shift;
    if (@_) {

        # 2MASS hack
        # ----------
        # quick, dirty and ultimately icky hack. The entire quality flag
        # code is going to have to be rewritten so it works like mag errors,
        # and gets assocaited with a magnitude. For now, if the JHK QFlag
        # for 2MASS is A,B or C then the internal quality flag is 0 (good),
        # otherwise it gets set to 1 (bad). This pretty much sucks.

        # Yes Tim, I know I'm doing this in the wrong place. I'm panicing
        # I'll fix it later. I've moved the Cluster specific hack about the
        # star ID's out of Astro::Catalog::query::USNOA2 and into the Cluster
        # IO module and used Scalar::Util to figure out whether I've got a
        # number (neat solution) before blowing it away.

        # Anyway...
        my $quality = shift;

        # Shouldn't happen?
        unless (defined $quality) {
            $self->{QUALITY} = undef;
            return undef;
        }

        if ($quality =~ /^[A-Z][A-Z][A-Z]$/) {
            $_ = $quality;
            m/^([A-Z])([A-Z])([A-Z])$/;

            my $j_quality = $1;
            my $h_quality = $2;
            my $k_quality = $3;

            if (($j_quality eq 'A' || $j_quality eq 'B' || $j_quality eq 'C') &&
                    ($h_quality eq 'A' || $h_quality eq 'B' || $h_quality eq 'C')) {
                # good quality
                $self->{QUALITY} = 0;
            }
            else {
                # bad quality
                $self->{QUALITY} = 1;
            }
        }
        else {
            $self->{QUALITY} = $quality;
        }

    }
    return $self->{QUALITY};
}

=item B<field>

Return (or set) the field parameter for the star

    $field = $star->field();
    $star->field('0080');

=cut

sub field {
    my $self = shift;
    if (@_) {
        $self->{FIELD} = shift;
    }
    return $self->{FIELD};
}

=item B<gsc>

Return (or set) the GSC flag for the object

    $gsc = $star->gsc();
    $star->gsc( 'TRUE' );

the flag is TRUE if the object is known to be in the Guide Star Catalogue,
and FALSE otherwise.

=cut

sub gsc {
    my $self = shift;
    if (@_) {
        $self->{GSC} = shift;
    }
    return $self->{GSC};
}

=item B<distance>

Return (or set) the distance from the field centre

    $distance = $star->distance();
    $star->distance('0.009');

e.g. for the USNO-A2 catalogue.

=cut

sub distance {
    my $self = shift;
    if (@_) {
        $self->{DISTANCE} = shift;
    }
    return $self->{DISTANCE};
}

=item B<posangle>

Return (or set) the position angle from the field centre

    $position_angle = $star->posangle();
    $star->posangle('50.761');

e.g. for the USNO-A2 catalogue.

=cut

sub posangle {
    my $self = shift;
    if (@_) {
        $self->{POSANGLE} = shift;
    }
    return $self->{POSANGLE};
}

=item B<x>

Return (or set) the X pixel co-ordinate of the star

    $x = $star->x();
    $star->id($x);

=cut

sub x {
    my $self = shift;
    if (@_) {
        $self->{X} = shift;
    }

    if (! defined($self->{X}) &&
            defined($self->wcs) &&
            defined($self->coords)) {

        # We need to get a template FK5 SkyFrame to be able to convert
        # properly between RA/Dec and X/Y, but we can only do this if
        # we load Starlink::AST. So that we don't have a major dependency
        # on that module, load it here at runtime.
        eval {require Starlink::AST;};
        if ($@) {
            croak "Attempted to convert from RA/Dec to X position and cannot load Starlink::AST. Error: $@";
        }
        my $template = new Starlink::AST::SkyFrame("System=FK5");
        my $wcs = $self->wcs;
        my $frameset = $wcs->FindFrame($template, "");
        unless (defined $frameset) {
            croak "Could not find FK5 SkyFrame to do RA/Dec to X position translation";
        }
        my ($ra, $dec) = $self->coords->radec();
        my ($x, $y) = $frameset->Tran2(
            [$ra->radians],
            [$dec->radians],
            0);
        $self->{X} = $x->[0];
    }
    return $self->{X};
}

=item B<y>

Return (or set) the Y pixel co-ordinate of the star

    $y = $star->y();
    $star->id($y);

=cut

sub y {
    my $self = shift;
    if (@_) {
        $self->{Y} = shift;
    }

    if (! defined($self->{Y}) &&
            defined($self->wcs) &&
            defined($self->coords)) {

        # We need to get a template FK5 SkyFrame to be able to convert
        # properly between RA/Dec and X/Y, but we can only do this if
        # we load Starlink::AST. So that we don't have a major dependency
        # on that module, load it here at runtime.
        eval {require Starlink::AST;};
        if ($@) {
            croak "Attempted to convert from RA/Dec to Y position and cannot load Starlink::AST. Error: $@";
        }
        my $template = new Starlink::AST::SkyFrame("System=FK5");
        my $wcs = $self->wcs;
        my $frameset = $wcs->FindFrame($template, "");
        unless (defined $frameset) {
            croak "Could not find FK5 SkyFrame to do RA/Dec to Y position translation";
        }
        my ($ra, $dec) = $self->coords->radec();
        my ($x, $y) = $frameset->Tran2(
            [$ra->radians],
            [$dec->radians],
            0);
        $self->{Y} = $y->[0];
    }

    return $self->{Y};
}

=item B<wcs>

Return (or set) the WCS associated with the star.

    $wcs = $star->wcs;
    $star->wcs($wcs);

The WCS is a C<Starlink::AST> object.

=cut

sub wcs {
    my $self = shift;
    if (@_) {
        my $wcs = shift;
        unless (defined $wcs) {
            $self->{WCS} = undef;
        }
        elsif (UNIVERSAL::isa($wcs, "Starlink::AST")) {
            $self->{WCS} = $wcs;
        }
    }
    return $self->{WCS};
}

=item B<comment>

Return (or set) a comment associated with the star

    $comment = $star->comment();
    $star->comment($comment_string);

The comment is propogated to the underlying coordinate
object (if one is present) if the comment is updated.

=cut

sub comment {
    my $self = shift;
    if (@_) {
        $self->{COMMENT} = shift;

        my $c = $self->coords;
        $c->comment($self->{COMMENT}) if defined $c;
    }
    return $self->{COMMENT};
}

=item B<spectype>

The spectral type of the Star.

    $spec = $star->spectype;

=cut

sub spectype {
    my $self = shift;
    if (@_) {
        $self->{SPECTYPE} = shift;
    }
    return $self->{SPECTYPE};
}

=item B<startype>

The type of star. Usually uses the Simbad abbreviation.
eg. '*' for a star, 'rG' for a Radio Galaxy.

    $type = $star->startype;

See also C<longstartype> for the expanded version of this type.

=cut

sub startype {
    my $self = shift;
    if (@_) {
        $self->{STARTYPE} = shift;
    }
    return $self->{STARTYPE};
}

=item B<longstartype>

The full description of the type of star. Usually uses the Simbad text.
If no text has been provided, a lookup will be performed using the
abbreviated C<startype>.

    $long = $star->longstartype;
    $star->longstartype("A variable star");

See also C<longstartype> for the expanded version of this type.

=cut

sub longstartype {
    my $self = shift;
    if (@_) {
        $self->{LONGTYPE} = shift;
    }
    # if we have nothing, attempt a look up
    if (! defined $self->{LONGTYPE} && defined $self->startype
            && exists $STAR_TYPE_LOOKUP{$self->startype}) {
        return $STAR_TYPE_LOOKUP{$self->startype};
    }
    else {
        return $self->{STARTYPE};
    }
}

=item B<moreinfo>

A link (URL) to more information on the star in question. For example
this might provide a direct link to the full Simbad description.

    $url = $star->moreinfo;

=cut

sub moreinfo {
    my $self = shift;
    if (@_) {
        $self->{MOREINFO} = shift;
    }
    return $self->{MOREINFO};
}

=item B<insertdate>

The time the information for the star in question was gathered. This
is different from the time of observation of the star.

    $insertdate = $star->insertdate;

This is a C<Time::Piece> object.

=cut

sub insertdate {
    my $self = shift;
    if (@_) {
        $self->{INSERTDATE} = shift;
    }
    return $self->{INSERTDATE};
}


=item B<fluxdatestamp>

Apply a datestamp to all the C<Astro::Flux> objects inside the
C<Astro::Fluxes> object contained within this object

    $star->fluxdatestamp(new DateTime());

this is different from the time for which the inormation about the
star was gathered, see the insertdate() method call, and is the
time of observation of the object.

=cut

sub fluxdatestamp {
    my $self = shift;
    if (@_) {
        my $datetime = shift;
        croak "Astro::Catalog::Item::fluxdatestamp()\n".
            "Error: Not a DateTime object\n"
            unless UNIVERSAL::isa($datetime, "DateTime");
        $self->{FLUXES}->datestamp($datetime);
    }
    return $self->{FLUXES};
}


=item B<distancetostar>

The distance from another Item,

    my $distance1 = $star->distancetostar($star2);

returns a tangent plane separation value in arcsec. Returns undef if
the star is too far away.

=cut

sub distancetostar {
    my $self = shift;
    my $other = shift;

    croak "Astro::Catalog::Item::distancetostar()\n".
        "Error: Not an Astro::Catalog::Item object\n"
        unless UNIVERSAL::isa($other, "Astro::Catalog::Item");

    my $sep = $self->coords->distance($other->coords);
    return (defined $sep ? $sep->arcsec : $sep);
}


=item B<within>

Check if the passed star is within $distance_in_arcsec of the object.

    my $status = $star->within($star2, $distance_in_arcsec);

returns true if this is the case.

=cut

sub within {
    my $self = shift;
    my $other = shift;
    my $max = shift;

    croak "Astro::Catalog::Item::within()\n".
        "Error: Not an Astro::Catalog::Item object\n"
        unless UNIVERSAL::isa( $other, "Astro::Catalog::Item" );

    my $distance = $self->distancetostar($other);
    return 1 if $distance < $max;
    return 0;
}


=item B<misc>

A hold-all method to contain information not covered by other methods.

    my $misc = $item->misc;
    $item->misc($misc);

This accessor can hold any type of variable, although it is
recommended that a hash reference is used for easier lookups:

    my $misc = $item->misc;
    my $vrad = $misc->{'vrad'};
    my $vopt = $misc->{'vopt'}

=cut

sub misc {
    my $self = shift;
    if (@_) {
        $self->{'MISC'} = shift;
    }
    return $self->{'MISC'};
}

=back

=head2 Obsolete Methods

Several methods were made obsolete with the introduction of V4 of the
Astro::Catalog class. These were magnitudes(), magerr(), colours() and
colerr(). The functionality these supported is now part of the addfluxes()
method.

=cut

sub magnitudes {
    my $self = shift;
    croak "Astro::Catalog::Item::magnitudes()\n" .
        "This method is no longer supported, use fluxes() instead.\n";
}

sub magerr {
    my $self = shift;
    croak "Astro::Catalog::Item::magerr()\n" .
        "This method is no longer supported, use fluxes() instead.\n";
}


sub colours {
    my $self = shift;
    croak "Astro::Catalog::Item::colours()\n" .
        "This method is no longer supported, use fluxes() instead.\n";

}

sub colerr {
    my $self = shift;
    croak "Astro::Catalog::Item::colerr()\n" .
        "This method is no longer supported, use fluxes() instead.\n";

}

=head2 General Methods

=over 4

=item B<configure>

Configures the object from multiple pieces of information.

    $star->configure(%options);

Takes a hash as argument with the list of keywords.
The keys are not case-sensitive and map to accessor methods.

Note that RA and Dec keys are allowed. The values can be supplied in either sexagesimal or decimal degrees.

=cut

sub configure {
    my $self = shift;

    # return unless we have arguments
    return unless @_;

    # grab the argument list
    my %args = @_;

    # First check for duplicate keys (case insensitive) with different
    # values and store the unique lower-cased keys
    my %check;
    for my $key (keys %args) {
        my $lckey = lc($key);
        if (exists $check{$lckey} && $check{$lckey} ne $args{$key}) {
            warnings::warnif("Duplicated key in constructor [$lckey] with differing values ".
                    " '$check{$lckey}' and '$args{$key}'\n");
        }
        $check{$lckey} = $args{$key};
    }

    # Now that we have lower cased keys we can look to see if we have
    # ra & dec as well as coords and also verify that they are actually
    # the same if we have them
    if (exists $check{coords} && (exists $check{ra} || exists $check{dec})) {
        # coords + one of ra or dec is a mistake
        if (exists $check{ra} && exists $check{dec}) {
            # Create a new coords object - assume J2000
            my $c = new Astro::Coords(
                type => 'J2000',
                ra => $check{ra},
                dec => $check{dec},
                # units => 'sex',
            );

            # Make sure we have the same reference place and time
            $c->datetime($check{coords}->datetime)
                if $check{coords}->has_datetime;
            $c->telescope($check{coords}->telescope)
                if defined $check{coords}->telescope;


            # Check the distance
            my $d = $c->distance($check{coords});

            # Raise warn if the error is more than 1 arcsecond
            warnings::warnif( "Coords and RA/Dec were specified and they differ by more than 1 arcsec [".
                    (defined $d ? $d->arcsec : "<undef>")
                    ." sec]. Ignoring RA/Dec keys.\n")
                if (!defined $d || $d->arcsec > 1.0);

        }
        elsif (! exists $check{ra}) {
            warnings::warnif("Dec specified in addition to Coords but without RA. Ignoring it.");
        }
        elsif (! exists $check{dec}) {
            warnings::warnif("RA specified in addition to Coords but without Dec. Ignoring it.");
        }

        # Whatever happens we do not want ra and dec here
        delete $check{dec};
        delete $check{ra};
    }
    elsif (exists $check{ra} || $check{dec}) {
        # Generate a Astro::Coords object here in one go rather than
        # relying on the old ra() dec() methods individually
        my $ra = $check{ra} || 0.0;
        my $dec = $check{dec} || 0.0;
        $check{coords} = new Astro::Coords(
            type => 'J2000',
            ra => $ra,
            dec => $dec);
        delete $check{ra};
        delete $check{dec};
    }

    # Loop over the allowed keys storing the values
    # in the object if they exist. Case insensitive.
    for my $key (keys %check) {
        my $method = lc($key);
        $self->$method($check{$key}) if $self->can($method);
    }
    return;
}

1;

__END__

=back

=head1 COPYRIGHT

Copyright (C) 2001-2002 University of Exeter. All Rights Reserved.
Some modification are Copyright (C) 2003 Particle Physics and
Astronomy Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>tjenness@cpan.orgE<gt>,

=cut
