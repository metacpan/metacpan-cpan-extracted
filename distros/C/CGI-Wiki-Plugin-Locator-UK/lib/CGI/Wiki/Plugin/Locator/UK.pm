package CGI::Wiki::Plugin::Locator::UK;

use strict;

use vars qw( $VERSION @ISA );
$VERSION = '0.09';

use Carp qw( croak );
use CGI::Wiki::Plugin;
use Geography::NationalGrid;
use Geography::NationalGrid::GB;

@ISA = qw( CGI::Wiki::Plugin );

=head1 NAME

CGI::Wiki::Plugin::Locator::UK - A CGI::Wiki plugin to manage UK location data.

=head1 DESCRIPTION

Access to and calculations using British National Grid location
metadata supplied to a CGI::Wiki wiki when writing a node. (For
converting between British National Grid co-ordinates and
latitude/longitude, you may wish to look at L<Geography::NationalGrid>.)

B<Note:> This is I<read-only> access. If you want to write to a node's
metadata, you need to do it using the C<write_node> method of
L<CGI::Wiki>.

=head1 SYNOPSIS

  use CGI::Wiki;
  use CGI::Wiki::Plugin::Locator::UK;

  my $wiki = CGI::Wiki->new( ... );
  my $locator = CGI::Wiki::Plugin::Locator::UK->new;
  $wiki->register_plugin( plugin => $locator );

  $wiki->write_node( "Jerusalem Tavern",
                     "A good pub",
                     $checksum,
		     { os_x => 531674,
                       os_y => 181950
                     }
                    );

  # Just retrieve the co-ordinates.
  my ( $x, $y ) = $locator->coordinates( node => "Jerusalem Tavern" );

  # Find the straight-line distance between two nodes, in kilometres.
  my $distance = $locator->distance( from_node => "Jerusalem Tavern",
                                     to_node   => "Calthorpe Arms" );

  # Find all the things within 200 metres of a given place.
  my @others = $locator->find_within_distance( node   => "Albion",
                                               metres => 200 );

=head1 METHODS

=over 4

=item B<new>

  my $locator = CGI::Wiki::Plugin::Locator::UK->new;

=cut

sub new {
    my ($class, @args) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

=item B<coordinates>

  my ($x, $y) = $locator->coordinates( node => "Jerusalem Tavern" );

Returns the OS x and y co-ordinates stored as metadata last time the
node was written.

=cut

sub coordinates {
    my ($self, %args) = @_;
    my $store = $self->datastore;
    # This is the slightly inefficient but neat and tidy way to do it -
    # calling on as much existing stuff as possible.
    my %node_data = $store->retrieve_node( $args{node} );
    my %metadata  = %{$node_data{metadata}};
    return ($metadata{os_x}[0], $metadata{os_y}[0]);
}

=item B<distance>

  # Find the straight-line distance between two nodes, in kilometres.
  my $distance = $locator->distance( from_node => "Jerusalem Tavern",
                                     to_node   => "Calthorpe Arms" );

  # Or in metres between a node and a point.
  my $distance = $locator->distance(from_os_x => 531467,
                                    from_os_y => 183246,
				    to_node   => "Duke of Cambridge",
				    unit      => "metres" );

  # Or specify the point via latitude and longitude.
  my $distance = $locator->distance(from_lat  => 51.53,
                                    from_long => -0.1,
				    to_node   => "Duke of Cambridge",
				    unit      => "metres" );

Defaults to kilometres if C<unit> is not supplied or is not recognised.
Recognised units at the moment: C<metres>, C<kilometres>.

Returns C<undef> if one of the endpoints does not exist, or does not
have both co-ordinates defined. The C<node> specification of an
endpoint overrides the x/y co-ords if both specified (but don't do
that).

B<Note:> Works to the nearest metre. Well, actually, calls C<int> and
rounds down, but if anyone cares about that they can send a patch.

=cut

sub distance {
    my ($self, %args) = @_;

    $args{unit} ||= "kilometres";
    my (@from, @to);

    if ( $args{from_node} ) {
        @from = $self->coordinates( node => $args{from_node} );
    } elsif ( $args{from_os_x} and $args{from_os_y} ) {
        @from = @args{ qw( from_os_x from_os_y ) };
    } elsif ( $args{from_lat} and $args{from_long} ) {
        my $point = Geography::NationalGrid::GB->new(
                                                 Latitude  => $args{from_lat},
                                                 Longitude => $args{from_long},
                                                    );
        @from = ( $point->easting, $point->northing );
    }

    if ( $args{to_node} ) {
        @to = $self->coordinates( node => $args{to_node} );
    } elsif ( $args{to_os_x} and $args{to_os_y} ) {
        @to = @args{ qw( to_os_x to_os_y ) };
    }

    return undef unless ( $from[0] and $from[1] and $to[0] and $to[1] );

    my $metres = int( sqrt(   ($from[0] - $to[0])**2
                            + ($from[1] - $to[1])**2 ) + 0.5 );

    if ( $args{unit} eq "metres" ) {
        return $metres;
    } else {
        return $metres/1000;
    }
}

=item B<find_within_distance>

  # Find all the things within 200 metres of a given place.
  my @others = $locator->find_within_distance( node   => "Albion",
                                               metres => 200 );

  # Or within 200 metres of a given location.
  my @things = $locator->find_within_distance( os_x => 530774,
                                               os_y => 182260,
                                               metres => 200 );

Units currently understood: C<metres>, C<kilometres>. If both C<node>
and C<os_x>/C<os_y> are supplied then C<node> takes precedence. Croaks
if insufficient start point data supplied.

=cut

sub find_within_distance {
    my ($self, %args) = @_;
    my $store = $self->datastore;
    my $dbh = eval { $store->dbh; }
      or croak "find_within_distance is only implemented for database stores";
    my $metres = $args{metres}
               || ($args{kilometres} * 1000)
               || croak "Please supply a distance";
    my ($sx, $sy);
    if ( $args{node} ) {
        ($sx, $sy) = $self->coordinates( node => $args{node} );
    } elsif ( $args{os_x} and $args{os_y} ) {
        ($sx, $sy) = @args{ qw( os_x os_y ) };
    } elsif ( $args{lat} and $args{long} ) {
        my $point = Geography::NationalGrid::GB->new(
                                                      Latitude  => $args{lat},
                                                      Longitude => $args{long},
                                                    );
        $sx = $point->easting;
        $sy = $point->northing;
    } else {
        croak "Insufficient start location data supplied";
    }

    # Only consider nodes within the square containing the circle of
    # radius $distance.  The SELECT DISTINCT is needed because we might
    # have multiple versions in the table.
    my $sql = "SELECT DISTINCT x.node
                FROM metadata AS x, metadata AS y
                WHERE x.metadata_type = 'os_x'
                  AND y.metadata_type = 'os_y'
                  AND x.metadata_value >= " . ($sx - $metres)
            . "   AND x.metadata_value <= " . ($sx + $metres)
            . "   AND y.metadata_value >= " . ($sy - $metres)
            . "   AND y.metadata_value <= " . ($sy + $metres)
            . "   AND x.node = y.node";
    $sql .= "     AND x.node != " . $dbh->quote($args{node})
        if $args{node};
    # Postgres is a fussy bugger.
    if ( ref $store eq "CGI::Wiki::Store::Pg" ) {
        $sql =~ s/metadata_value/metadata_value::integer/gs;
    }
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    my @results;
    while ( my ($result) = $sth->fetchrow_array ) {
        my $dist = $self->distance( from_os_x => $sx,
                                    from_os_y => $sy,
				    to_node   => $result,
				    unit      => "metres" );
        if ( defined $dist && $dist <= $metres ) {
            push @results, $result;
	}
    }
    return @results;
}

=head1 SEE ALSO

=over 4

=item * L<CGI::Wiki>

=item * L<Geography::NationalGrid>

=item * My test wiki that uses this plugin - L<http://the.earth.li/~kake/cgi-bin/cgi-wiki/wiki.cgi>

=back

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2003 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

Nicholas Clark found a very silly bug in a pre-release version, oops
:) Stephen White got me thinking in the right way to implement
C<find_within_distance>. Marcel Gruenauer helped me make
C<find_within_distance> work properly with postgres.

=cut


1;
