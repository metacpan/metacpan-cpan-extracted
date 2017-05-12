package App::Cerberus::Plugin::GeoIP;
$App::Cerberus::Plugin::GeoIP::VERSION = '0.11';
use strict;
use warnings;
use Geo::IP();
use Carp;
use parent 'App::Cerberus::Plugin';

#===================================
sub init {
#===================================
    my $self = shift;
    $self->{data} = shift
        or croak "No data file configured. \n"
        . "You can download it from: "
        . 'http://www.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz';
}

#===================================
sub request {
#===================================
    my ( $self, $req, $response ) = @_;
    my $ip = $req->param('ip') or return;
    my $geo = $self->{geo} ||= Geo::IP->open( $self->{data} );

    my %data;
    if ( my $record = $geo->record_by_addr($ip) ) {
        %data = map { $_ => $record->$_ } qw(
            country_code country_name region region_name city
            postal_code latitude longitude area_code time_zone
        );
    }
    $response->{geo} = \%data;
    $response->{tz}{name} = delete $data{time_zone} || '';

}

1;

# ABSTRACT: Add geo-location information the user's IP address

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cerberus::Plugin::GeoIP - Add geo-location information the user's IP address

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This plugin uses the freely available L<GeoLite City|http://www.maxmind.com/app/geolite>
database from L<MaxMind|http://www.maxmind.com> to add geo-location data to
Cerberus.

For instance:

    "geo": {
        "area_code": 201,
        "longitude": "-74.0781",
        "country_name": "United States",
        "region_name": "New Jersey",
        "country_code": "US",
        "region": "NJ",
        "city": "Jersey City",
        "postal_code": "07304",
        "latitude": "40.7167"
    }

=head1 CONFIGURATION

To use this plugin, add this to your config file:

    plugins:
      - GeoIP:    /opt/geoip/GeoLiteCity.dat

=head1 REQUEST PARAMS

Geo information is returned when an IPv4 address is passed in:

    curl http://host:port/?ip=80.1.2.3

=head1 INSTALLING GEO::IP

To work properly, you should install the C API before installing L<Geo::IP>.
You can do this as follows: (I'm assuming you have write permissions on C</opt>):

    wget http://www.maxmind.com/download/geoip/api/c/GeoIP.tar.gz

    tar -xzf GeoIP.tar.gz
    cd GeoIP-*/

    libtoolize -f
    ./configure --prefix=/opt/geoip
    make && make check && make install

Then, find the latest version of L<Geo::IP> from L<https://metacpan.org/release/Geo-IP>
and install it as follows:

    wget http://cpan.metacpan.org/authors/id/B/BO/BORISZ/Geo-IP-1.40.tar.gz

    tar -xzf Geo-IP-*
    cd Geo-IP-*

    perl Makefile.PL LIBS='-L/opt/geoip/lib64' INC='-I/opt/geoip/include'
    # make && make test && make install
    make && make install

I<B<Note:> If you're installing GeoIP in a non-standard location (as above),
then testing the Perl API won't work, because the path to the data file is
hard coded. See L<https://rt.cpan.org/Public/Bug/Display.html?id=49531>.>

You will also need a copy of the GeoLite City database:

    cd /opt/geoip
    wget http://www.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
    gunzip GeoLiteCity.dat.gz

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
