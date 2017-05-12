package Catmandu::Fix::reverse_geocode;

use Catmandu::Sane;
use Geo::Coder::Google;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;

    "if (is_string(${var})) {" .
        "${var} = Geo::Coder::Google->new(apiver => 3)->reverse_geocode(latlng => ${var}) // {};" .
    "}";
}

=head1 NAME

Catmandu::Fix::reverse_geocode - Provide access to the Google geocoding API

=head1 SYNOPSIS

   # Lookup the location of
   #  latlng: '34.1015473,-118.3387288'
   
   reverse_geocode(latlng)
   
   #  address:
   #    address_components:
   #    - long_name: Highland Avenue
   #      short_name: Highland Ave
   #      types:
   #      - route
   #    - long_name: Central LA
   #      short_name: Central LA
   #      types:
   #      - neighborhood
   #      - political
   #    - long_name: Hollywood
   #      short_name: Hollywood
   #      types:
   #      - sublocality_level_1
   #      - sublocality
   #      - political
   #    - long_name: Los Angeles
   #      short_name: LA
   #      types:
   #      - locality
   #      - political
   #    - long_name: Los Angeles County
   #      short_name: Los Angeles County
   #      types:
   #      - administrative_area_level_2
   #      - political
   #    - long_name: California
   #      short_name: CA
   #      types:
   #      - administrative_area_level_1
   #      - political
   #    - long_name: United States
   #      short_name: US
   #      types:
   #      - country
   #      - political
   #    - long_name: '90028'
   #      short_name: '90028'
   #      types:
   #      - postal_code
   #    formatted_address: Highland Avenue & Hollywood Boulevard, Los Angeles, CA 90028, USA
   #    geometry:
   #      location:
   #        lat: 34.1015473
   #        lng: -118.3387288
   #      location_type: APPROXIMATE
   #      viewport:
   #        northeast:
   #          lat: 34.1028962802915
   #          lng: -118.337379819709
   #        southwest:
   #          lat: 34.1001983197085
   #          lng: -118.340077780291
   #    partial_match: !!perl/scalar:JSON::PP::Boolean 1
   #    place_id: EkFIaWdobGFuZCBBdmVudWUgJiBIb2xseXdvb2QgQm91bGV2YXJkLCBMb3MgQW5nZWxlcywgQ0EgOTAwMjgsIFVTQQ
   #    types:
   #    - intersection

=head1 DESCRIPTION

This code requires you to create a Google MAP API key:

 https://console.developers.google.com//flows/enableapi?apiid=geocoding_backend&keyType=SERVER_SIDE

Your UNIX environment should contain two variabels:

    export GMAP_CLIENT=<your_google_address>
    export GMAP_KEY=<your_api_key>

As a free service a maximum of 5 requests per second are permitted, 2500 requests per day.

=head1 SEE ALSO

L<Catmandu::Fix> , L<Geo::Coder::Google>

=cut

1;