package Catalyst::Plugin::Geocoding;

use strict;
use LWP::Simple;

our $VERSION = '0.01';

sub geocoding {
    my $c = shift;
    my $location = shift;

    my $url = "http://maps.google.com/maps/geo?q=$location&output=csv&key="
        . $c->config->{gmap_key};
    my $result = get($url);
    $result =~ m[(\d+),(\d+),(.+?),(.+)\z]o;
    return ($result, $1, $2, $3, $4);
}

1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Geocoding - Geocoding plugin

=head1 SYNOPSIS

  # In App.pm
  use Catalyst qw(Geocoding);
  __PACKAGE__->config(gmap_key => 'your_key_to_google_maps');

  # In App/Controller/YourController.pm
  sub index : Private {
     my ($self, $c) = @_;
     my ($result, $status, $accuracy, $latitude, $longitude)
         = $c->geocoding($c->req->params->{location_name});
  }

=head1 DESCRIPTION

This module retrieves geocoding results from google. The returned data
is in CSV format.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yung-chung Lin (henearkrxern@gmail.com)

=cut
