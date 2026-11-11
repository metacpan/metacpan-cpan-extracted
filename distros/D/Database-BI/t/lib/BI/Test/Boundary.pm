package BI::Test::Boundary;

# A stand-in for Nominatim's reverse lookup, for Database::BI::Model::Boundary:
# given areas as boxes, it answers a point with the most detailed box holding
# it that the zoom allows (zoom 5 a rank up to 8, 6 and 7 up to 10, 8 up to 12;
# the first listed of equal rank), as Nominatim answers with the county a point
# is in, and with "Unable to geocode" elsewhere (the sea).  An area with a
# country gives the reply an address with its country_code.  It records each
# URL it is asked, and can fail every request instead.  No test reaches the
# network through it.
#
#   my $ua = BI::Test::Boundary->new(areas => [
#       { name => 'Square County', id => 101, box => [ 10, 20, 11, 21 ] },   # south, west, north, east
#       { name => 'Holed County',  id => 102, box => [ ... ], hole => [ ... ] },
#       { name => 'A State',       id => 103, box => [ ... ], rank => 8 },
#       { name => 'A District',    id => 104, box => [ ... ], rank => 10, country => 'in' },
#   ]);
#   $ua->asked;    # the URLs asked, in order
#
# with_ua($ua, sub { ... }) makes it the user agent Geocode::nominatim_ua()
# hands out, which is the one Boundary asks with, for the length of the block.

use strict;
use warnings;

use HTTP::Response ();
use JSON::PP ();
use URI ();

# The most detailed rank Nominatim's reverse lookup returns at each zoom.
my %MAX_RANK = (5 => 8, 6 => 10, 7 => 10, 8 => 12);

sub new {
	my ($class, %args) = @_;
	return bless { areas => $args{areas} // [], fail => $args{fail}, asked => [] }, $class;
}

sub asked { return @{ $_[0]->{asked} } }

sub clear { @{ $_[0]->{asked} } = (); return }

# A closed ring round a box, as GeoJSON has it: [lon, lat], first point last.
sub ring {
	my ($south, $west, $north, $east) = @_;
	return [ [ $west, $south ], [ $east, $south ], [ $east, $north ], [ $west, $north ], [ $west, $south ] ];
}

sub _inside {
	my ($box, $lat, $lon) = @_;
	return $lat >= $box->[0] && $lat <= $box->[2] && $lon >= $box->[1] && $lon <= $box->[3];
}

sub get {
	my ($self, $url) = @_;
	push @{ $self->{asked} }, "$url";
	return HTTP::Response->new(500, 'Internal Server Error', [], 'down') if $self->{fail};

	my %query = URI->new($url)->query_form;
	my ($lat, $lon) = @query{qw(lat lon)};
	my $most = $MAX_RANK{ $query{zoom} // '' } // 30;
	my ($area) = sort { ($b->{rank} // 12) <=> ($a->{rank} // 12) }
		grep {
			_inside($_->{box}, $lat, $lon)
			&& !($_->{hole} && _inside($_->{hole}, $lat, $lon))
			&& ($_->{rank} // 12) <= $most
		} @{ $self->{areas} };
	if ($area) {
		my $polygon = [ ring(@{ $area->{box} }), ($area->{hole} ? ring(@{ $area->{hole} }) : ()) ];
		return _reply({
			category     => 'boundary',
			type         => 'administrative',
			osm_type     => 'relation',
			osm_id       => $area->{id},
			place_rank   => $area->{rank} // 12,
			addresstype  => 'county',
			name         => $area->{name},
			display_name => "$area->{name}, Somewhere",
			geojson      => { type => 'Polygon', coordinates => $polygon },
			($area->{country} ? (address => { country_code => $area->{country} }) : ()),
		});
	}
	return _reply({ error => 'Unable to geocode' });
}

sub _reply {
	return HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'application/json; charset=utf-8' ],
		JSON::PP->new->utf8->canonical->encode($_[0]));
}

sub with_ua {
	my ($ua, $code) = @_;
	require Database::BI::Model::Geocode;
	no warnings qw(redefine);
	local *Database::BI::Model::Geocode::nominatim_ua = sub { $ua };
	return $code->();
}

1;
