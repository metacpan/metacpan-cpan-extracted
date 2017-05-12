package Catmandu::Geocode;

=head1 NAME

Catmandu::Geocode - Catmandu modules for the Google Maps geocoding api

=head1 SYNOPSIS

   geocode(address)         # address: 'Hollywood and Highland, Los Angeles, CA' 
   reverse_geocode(latlng)   # latlng:  '34.1015473,-118.3387288'

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This code requires you to create a Google MAP API key:

 https://console.developers.google.com//flows/enableapi?apiid=geocoding_backend&keyType=SERVER_SIDE

Your UNIX environment should contain two variabels:

    export GMAP_CLIENT=<your_google_address>
    export GMAP_KEY=<your_api_key>

As a free service a maximum of 5 requests per second are permitted, 2500 requests per day.

=head1 MODULES

=over

=item * L<Catmandu::Fix::geocode>

=item * L<Catmandu::Fix::reverse_geocode>

=back

=head1 SEE ALSO

L<Catmandu::Fix> , L<Geo::Coder::Google>

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ghent University Library

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;