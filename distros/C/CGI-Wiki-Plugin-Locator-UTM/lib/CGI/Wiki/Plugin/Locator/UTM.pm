package CGI::Wiki::Plugin::Locator::UTM;

use strict;

use vars qw( $VERSION @ISA );
$VERSION = '0.04';

use Carp qw( croak );
use CGI::Wiki::Plugin;

@ISA = qw( CGI::Wiki::Plugin );

use Geo::Coordinates::UTM;

=head1 NAME

CGI::Wiki::Plugin::Locator::UTM - A CGI::Wiki plugin to manage international location data.

=head1 SYNOPSIS

  use CGI::Wiki;
  use CGI::Wiki::Plugin::Locator::UTM;

  my $wiki = CGI::Wiki->new( ... );
  my $locator = CGI::Wiki::Plugin::Locator::UTM->new('International');
  $wiki->register_plugin( $locator );

  $wiki->write_node( "King's Head",
                     "Tip top pride",
                     $checksum,
		     { lat => 51.507497,
                       long => -0.271797
                     }
                    );

  # Just retrieve the location
  my ( $lat, $long ) = $locator->location( node => "King's Head" );

  # or as coordinates
  my ( $zone, $east, $north ) = $locator->coordinates( node => "King's Head" );

  # Find the straight-line distance between two nodes, in kilometres.
  my $distance = $locator->distance( from_node => "King's Head",
                                     to_node   => "Calthorpe Arms" );

  # Find all the things within 200 metres of a given place.
  my @others = $locator->find_within_distance( node   => "Albion",
                                               metres => 200 );

=head1 DESCRIPTION

This module provides access to the Universal Transverse Mercator 
international coordinates system. It is a thin wrapper for the module
L<Geo::Coordinates::UTM>. To use this module, you must specify an 
ellipsoid, on which the mercator projection is based.

=head1 METHODS

=over 4

=item B<new>

  my $locator = CGI::Wiki::Plugin::Locator::UK->new('Clarke 1880');

The parameter is the name of the ellipsoid to be used for coordinate
conversion. The default value of this is 'International'. Please see
L<Geo::Coordinates::UTM> for explanation and for the full list of
valid values.

Note that you can only do coordinate conversion within one ellipsoid.

=cut

sub new {
    my ( $class, $ellipsoid ) = @_;
    $ellipsoid ||= 'International';
    my $self = { ellipsoid => $ellipsoid };
    bless $self, $class;
    return $self;
}

=item B<location>

  my ($lat, $long) = $locator->coordinates( node => "King's Head" );

Returns the latitude and longitude co-ordinates stored as metadata 
last time the node was written.

=cut

sub location {
    my ( $self, %args ) = @_;
    my $store     = $self->datastore;
    my %node_data = $store->retrieve_node( $args{node} );
    my %metadata  = %{ $node_data{metadata} };
    return ( $metadata{lat}[0], $metadata{long}[0] );
}

=item B<coordinates>

  my ($zone, $x, $y) = $locator->coordinates( node => "King's Head" );
  
  my ($zone, $x, $y) = $locator->coordinates( lat => 51.507497,
  					     long => -0.271797);
  					     
Returns the UTM easting and northing co-ordinates. 
See L<Geo::Coordinates::UTM> for the meaning of the zone value.

=cut

sub coordinates {
    my ( $self, %args ) = @_;
    my ( $lat, $long, $zone, $east, $north );

    return @args{qw(zone easting northing)}
      if exists( $args{zone} )
      && exists( $args{easting} )
      && exists( $args{northing} );

    if ( exists $args{lat} ) {
        ( $lat, $long ) = @args{qw/lat long/};
    }
    else {
        my $store     = $self->datastore;
        my %node_data = $store->retrieve_node( $args{node} );
        $lat  = $node_data{metadata}{lat}[0];
        $long = $node_data{metadata}{long}[0];

        # Use UTM metadata if it is available
        $zone  = $node_data{metadata}{zone}[0];
        $east  = $node_data{metadata}{easting}[0];
        $north = $node_data{metadata}{northing}[0];
    }
    if ( !defined($zone) && !defined($east) && !defined($north) ) {
        return undef unless defined($lat) && defined($long);
        ( $zone, $east, $north ) =
          latlon_to_utm( $self->{ellipsoid}, $lat, $long );
    }
    ( $zone, $east, $north );
}

=item B<distance>

  # Find the straight-line distance between two nodes, in kilometres.
  my $distance = $locator->distance( from_node => "King's Head",
                                     to_node   => "Duke Of York" );

  # Or in metres between a node and a point.
  my $distance = $locator->distance(from_lat  => 51.507497,
                                    from_long => -0.271797,
				    to_node   => "Duke of Cambridge",
				    unit      => "metres" );

Defaults to kilometres if C<unit> is not supplied or is not recognised.
Recognised units at the moment: C<metres>, C<kilometres>.

Returns C<undef> if one of the endpoints does not exist, or does not
have both co-ordinates defined. 

B<Note:> Works to the nearest metre. Well, actually, calls C<int> and
rounds down, but if anyone cares about that they can send a patch.

=cut

sub distance {
    my ( $self, %args ) = @_;

    $args{unit} ||= "kilometres";

    # Split off the prefix from_ or to_
    my ( %from, %to );
    while ( my ( $arg, $val ) = each %args ) {
        $from{$1} = $val if $arg =~ /from_(.*)/;
        $to{$1}   = $val if $arg =~ /to_(.*)/;
    }

    my @from = $self->coordinates(%from);
    my @to   = $self->coordinates(%to);

    return undef unless ( $from[0] and $from[1] and $to[0] and $to[1] );

    croak("Locations are in different zones") unless $from[0] eq $to[0];

    my $metres =
      int( sqrt( ( $from[1] - $to[1] )**2 + ( $from[2] - $to[2] )**2 ) + 0.5 );

    if ( $args{unit} eq "metres" ) {
        return $metres;
    }
    else {
        return $metres / 1000;
    }
}

=item B<find_within_distance>

  # Find all the things within 200 metres of a given place.
  my @others = $locator->find_within_distance( node   => "Albion",
                                               metres => 200 );

  # Or within 200 metres of a given location.
  my @things = $locator->find_within_distance( lat => 51.507497,
                                               long => -0.271797,
                                               metres => 200 );

Requires the node metadata to be stored in the database, in particular
zone, easting and northing.

Units currently understood: C<metres>, C<kilometres>. If both C<node>
and C<os_x>/C<os_y> are supplied then C<node> takes precedence. Croaks
if insufficient start point data supplied.

=cut

sub find_within_distance {
    my ( $self, %args ) = @_;

    my $store = $self->datastore;
    my $dbh = eval { $store->dbh; }
      or croak "find_within_distance is only implemented for database stores";
    my $metres = $args{metres}
      || ( $args{kilometres} * 1000 )
      || croak "Please supply a distance";
    my ( $zone, $sx, $sy ) = $self->coordinates(%args);
    croak "Insufficient start location data supplied"
      unless defined($sx) && defined($sy);

    # Only consider nodes within the square containing the circle of
    # radius $distance.  The SELECT DISTINCT is needed because we might
    # have multiple versions in the table.
    my $sql = "SELECT DISTINCT x.node
                FROM metadata AS x, metadata AS y, metadata AS z
                WHERE x.node = y.node
                  AND x.node = z.node
                  AND x.metadata_type = 'easting'
                  AND x.metadata_value >= ? 
                  AND x.metadata_value <= ?
                  AND y.metadata_type = 'northing'
                  AND y.metadata_value >= ? 
                  AND y.metadata_value <= ?
                  AND z.metadata_type = 'zone'
                  AND z.metadata_value = ?
                  AND x.node != ?";

    # Postgres is a fussy bugger.
    if ( ref $store eq "CGI::Wiki::Store::Pg" ) {
        $sql =~ s/([xy]\.metadata_value)/$1::float/gs;
    }
    my $node = $args{node} || '';

    my $sth = $dbh->prepare($sql);
    $sth->execute(
        $sx - $metres,
        $sx + $metres,
        $sy - $metres,
        $sy + $metres,
        $zone, $node
    );
    my @results;
    while ( my ($result) = $sth->fetchrow_array ) {
        my $dist = $self->distance(
            from_easting  => $sx,
            from_northing => $sy,
            from_zone     => $zone,
            to_node       => $result,
            unit          => "metres"
        );
        if ( $dist && $dist <= $metres ) {
            push @results, $result;
        }
    }
    return @results;
}

=item B<og_config>

  my $config = OpenGuides::Config->new(file => 'wiki.conf');
  $locator->og_config($config);
  ...
  $ellipsoid = $locator->og_config->ellipsoid;

This is a get-and-set method, used in conjunction with the L<OpenGuides> 
package to make all the information from the configuration available to the
plugin. 

=cut

sub og_config {
    my $self = shift;

    if (@_) {
        my $config = shift;
        if ($config->geo_handler eq 3) {
            $self->{ellipsoid} = $config->ellipsoid;
        }
        $self->{og_config} = $config;
    }
    $self->{og_config};
}

=item B<pre_write>

  $ap->despatch( 'pre_write', $node, $content, \%metadata );

This is a L<CGI::Wiki::AutoPlugin> compatible method, which should be called
before committing data to the wiki store. This performs the necessary geodata
convertions needed between coordinate systems. 

This is a refactoring of code in L<OpenGuides::Template> which deals with 
converting input data into the coordinate system used on a particular guide.
This pre-write method updates the metadata hash to populate the remaining 
fields of latitude, longitude, x, y, which are not already populated.

=cut

our @geo_mechanism = (
    {},
    {
        x       => 'os_x',
        y       => 'os_y',
        module  => 'Geography::NationalGrid::GB',
    },
    {
        x       => 'osie_x',
        y       => 'osie_y',
        module  => 'Geography::NationalGrid::IE',
    },
    {
        x       => 'easting',
        y       => 'northing',
        module  => 'Geo::Coordinates::UTM',
    },
    ) ;
    

sub pre_write {
    my ($self, $node, $content, $metadata) = @_;

    my $config = $self->og_config or croak "No config set";
    my $geo_handler = $config->geo_handler;
    my %geo_mech = %{$geo_mechanism[$geo_handler]};
    
    # Case 1 : all geodata missing

    return 1 if !exists ($metadata->{latitude}) &&
                !exists ($metadata->{longitude}) &&
                !exists ($metadata->{$geo_mech{x}}) &&
                !exists ($metadata->{$geo_mech{y}});
                
    # Case 2 : all geodata present - do no convertions

    return 1 if exists ($metadata->{latitude}) &&
                exists ($metadata->{longitude}) &&
                exists ($metadata->{$geo_mech{x}}) &&
                exists ($metadata->{$geo_mech{y}});

    eval "require $geo_mech{module}";

    if ($geo_handler == 3) {
        my $lat = $metadata->{latitude}[0];
        my $long = $metadata->{longitude}[0];
        if ( $lat && $long ) {
            my ($zone, $easting, $northing) = 
                Geo::Coordinates::UTM::latlon_to_utm (
                        $self->{ellipsoid}, $lat, $long );
            $easting  =~ s/\..*//; # chop off decimal places
            $northing =~ s/\..*//; # - metre accuracy enough
            $metadata->{easting}[0] = $easting;
            $metadata->{northing}[0] = $northing;
        }
    }
    else {
        my $x = $metadata->{$geo_mech{x}}[0];
        my $y = $metadata->{$geo_mech{y}}[0];
        if ($x && $y) {
            my $point = $geo_mech{module}->new ( Easting => $x, 
                                                Northing => $y );
            $metadata->{latitude}[0]  = sprintf "%.6f", $point->latitude;
            $metadata->{longitude}[0] = sprintf "%.6f", $point->longitude;
        }
        else {
            my $lat = $metadata->{latitude}[0];
            my $long = $metadata->{longitude}[0];
            my $point = $geo_mech{module}->new ( Latitude => $lat, 
                                                Longitude => $long );
            $metadata->{$geo_mech{x}}[0] = $point->easting;
            $metadata->{$geo_mech{y}}[0] = $point->northing;
        }
    }
}

=back
 
=head1 SEE ALSO

=over 4

=item * L<CGI::Wiki>

=item * L<CGI::Wiki::Plugin::Locator::UK>

=item * L<Geo::Coordinates::UTM>

=back

=head1 AUTHOR

Ivor Williams (ivorw at CPAN dot org)

=head1 ACKNOWLEDGEMENT

This module is derived from CGI::Wiki::Plugin::Locator::UK, written by
Kate Pugh.

=head1 COPYRIGHT

     Copyright (C) 2004 Ivor Williams.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
