#!/usr/bin/perl

=head1 NAME

image.pl - Download an image from the internet and display it

=head1 DESCRIPTION

This sample scripts shows how to use an image from another source than a local
file.

=cut

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2;
use Clutter qw(-threads-init -init);
use Champlain;
use LWP::UserAgent;

exit main();

sub main {

	my $stage = Clutter::Stage->get_default();
	$stage->set_size(800, 600);

	# Create the map view
	my $map = Champlain::View->new();
	$map->set_size($stage->get_size);
	$map->center_on(47.130885, -70.764141);
	$map->set_scroll_mode('kinetic');
	$map->set_zoom_level(5);
	$stage->add($map);

	# Create the markers and marker layer
	my $layer = create_marker_layer($map);
	$map->add_layer($layer);

	$stage->show_all();

	Clutter->main();

	return 0;
}


#
# Adds a marker which has a picture taken from the Internet.
#
sub create_marker_layer {
	my ($map) = @_;
	my $layer = Champlain::Layer->new();

	# Download the image as an actor (Clutter::Texture)
	my $texture = download_texture('http://hexten.net/cpan-faces/potyl.jpg');

	my $marker = Champlain::Marker->new_with_image($texture);
	$marker->set_position(47.130885, -70.764141);
	$layer->add($marker);

	$layer->show();
	return $layer;
}


#
# Download an image from an arbitrary URL and construct a texture
# (Clutter::Texture) with it.
#
sub download_texture {
	my ($url) = @_;

	# Download the image
	my $ua = LWP::UserAgent->new();
	my $response = $ua->get($url);
	if (! $response->is_success) {
		die $response->status_line;
	}

	# Load the image with a Pixbuf Loader
	my $mime = $response->header('content-type');
	my $loader = Gtk2::Gdk::PixbufLoader->new_with_mime_type($mime);
	$loader->write($response->content);
	$loader->close;
	my $pixbuf = $loader->get_pixbuf;

	# Transform the Pixbuf into a Clutter::Texture
	my $actor = Clutter::Texture->new();
	$actor->set_from_rgb_data(
		$pixbuf->get_pixels,
		$pixbuf->get_has_alpha,
		$pixbuf->get_width,
		$pixbuf->get_height,
		$pixbuf->get_rowstride,
		($pixbuf->get_has_alpha ? 4 : 3),
		[]
	);

	return $actor;
}

