#!/usr/bin/perl

=head1 NAME

capitals.pl - Show the world capitals

=head1 DESCRIPTION

This program takes you into a magical trip and displays the world capital cities
one by one. The list of capitals are fetched on the fly from Wikipedia.

=cut

use strict;
use warnings;
use open ':std', ':utf8';

use Glib qw(TRUE FALSE);
use Clutter qw(-threads-init -init);
use Champlain;

use XML::LibXML;


exit main();


sub main {

	my $stage = Clutter::Stage->get_default();
	$stage->set_size(800, 600);

	# Create the map stuff
	my $map = Champlain::View->new();
	$map->set_size($stage->get_size);
	$map->center_on(0, 0);
	$map->set_scroll_mode('kinetic');
	$map->set_zoom_level(3);
	$stage->add($map);

	my $layer = Champlain::Layer->new();
	$map->add_layer($layer);

	$stage->show_all();

	
	my $capitals_url = "http://en.wikipedia.org/wiki/List_of_national_capitals";
	my $soup = My::Soup->new($capitals_url);

	my $data = {
		map     => $map,
		layer   => $layer,
		markers => [],
	};

	# Download the next map after the go-to animation has been completed
	$map->signal_connect('animation-completed::go-to' => sub {
		Glib::Timeout->add (1_000, sub {
			download_capital($soup, $data);
			return FALSE;
		});
	});
	
	# Start the program by downloading the capital list
	$soup->do_get($capitals_url, \&capitals_main_callback, $data);
	
	
	Clutter->main();
	
	
	return 0;
}


#
# Called when the main page with all the capitals is downloaded.
#
sub capitals_main_callback {
	my ($soup, $uri, $response, $data) = @_;
	
	my $parser = XML::LibXML->new();
	$parser->recover_silently(1);
	$data->{parser} = $parser;

	# Find the table with the capitals
	my $document = $parser->parse_html_string($response->content);
	my @nodes = $document->findnodes('//table[@class="wikitable sortable"]/tr/td[1]/a');
	
	# Get the capitals
	my @capitals = ();
	foreach my $node (@nodes) {
		my $uri = $node->getAttribute('href') or next;
		my $name = $node->getAttribute('title') or next;
		my $capitals = {
			uri => $uri,
			name => $name,
		};
		push @capitals, $capitals;
	}
	
	# Download the capitals (the download is node one capital at a time)
	$data->{capitals} = \@capitals;
	download_capital($soup, $data);
}


#
# Called when the page of a capital is downloaded. The page is expected to have
# the coordinates of the capital. If the capital's coordinates can be found then
# a marker will be displayed for this capital.
#
sub capital_callback {
	my ($soup, $uri, $response, $data) = @_;

	my $document = $data->{parser}->parse_html_string($response->content);
	my $heading = $document->getElementById('firstHeading');
	if (!$heading) {
		download_capital($soup, $data);
		return;
	}

	my $name = $document->getElementById('firstHeading')->textContent;
			
	my ($geo) = $document->findnodes('id("coordinates")//span[@class="geo"]');
	if (!$geo) {
		# The capital has no geographical location, download the next capital
		download_capital($soup, $data);
		return;
	}

	my ($latitude, $longitude) = split /\s*;\s*/, $geo->textContent;
	$data->{current}{latitude} = $latitude;
	$data->{current}{longitude} = $longitude;
	printf "$name %.4f, %.4f\n", $latitude, $longitude;
	
	my $font = "Sans 15";
	my $layer = $data->{layer};
	my @markers = @{ $data->{markers} };
	# Keep only a few capitals at each iteration we remove a capital
	if (@markers == 5) {
		my $marker = shift @markers;
		$layer->remove($marker);
	}
	
	if (@markers) {
		# Reset the color of the previous marker
		my $marker = $markers[-1];
		$marker->set_text_color(undef);
		$marker->set_color(undef);
	}
	$data->{markers} = \@markers;
		
	my $white = Clutter::Color->new(0xff, 0xff, 0xff, 0xff);
	my $orange = Clutter::Color->new(0xf3, 0x94, 0x07, 0xbb);
	my $marker = Champlain::Marker->new_with_text($name, $font, $white, $orange);
	$marker->{name} = $name;
	$marker->set_position($latitude, $longitude);
	push @markers, $marker;
	$layer->add($marker);
	$marker->raise_top();

	# Remember that the map view has a signal handler for
	# 'animation-completed::go-to', this means that once the view is placed on the
	# location of the new capital that the next capital will be downloaded.
	$data->{map}->go_to($latitude, $longitude);
	return;
}


#
# This function downloads the page of a capital and then call it self again with
# the next capital to download. This process is repeated until there are no more
# capitals to download.
#
# The capitals to download are taken from $data->{capitals}.
#
sub download_capital {
	my ($soup, $data) = @_;

	my $capital = shift @{ $data->{capitals} };
	if (! defined $capital) {
		print "No more capitals to download\n";
		return;
	}
	
	my $uri = $capital->{uri};
	my $name = $capital->{name};
	$data->{current} = $capital;
	$soup->do_get($uri, \&capital_callback, $data);
}



#
# A very cheap implementation of an asynchronous HTTP client that integrates
# with Glib's main loop. This client implements a rudimentary version of
# 'Keep-Alive'.
#
# Each instance of this class can only make HTTP GET requests and only to a
# single HTTP server.
#
#
# Usage:
#
#   my $soup = My::Soup->new('http://en.wikipedia.com/');
#   $soup->do_get('http://en.wikipedia.com/Bratislava', sub {
#     my ($soup, $uri, $response, $data) = @_;
#     print $response->content;
#   });
#
package My::Soup;

use Glib qw(TRUE FALSE);
use Net::HTTP::NB;
use HTTP::Response;
use URI;


sub new {
	my $class = shift;
	my ($uri) = @_;
	
	my $self = bless {}, ref $class || $class;

	$uri = to_uri($uri);
	$self->{port} = $uri->port;
	$self->{host} = $uri->host;
	
	$self->connect();
	
	return $self;
}


#
# Connects to the remote HTTP server.
#
sub connect {
	my $self = shift;
	my $http = Net::HTTP::NB->new(
		Host      => $self->{host},
		PeerPort  => $self->{port},
		KeepAlive => 1,
	);
	$self->http($http);
}


sub http {
	my $self = shift;
	if (@_) {
		$self->{http} = $_[0];
	}
	return $self->{http};
}


sub to_uri {
	my ($uri) = @_;
	return $uri if ref($uri) && $uri->isa('URI');
	return URI->new($uri);
}


#
# Performs an HTTP GET request asynchronously.
#
sub do_get {
	my $self = shift;
	my ($uri, $callback, $data) = @_;
	$uri = to_uri($uri);
	
	# Note that this is not asynchronous!
	$self->http->write_request(GET => $uri->path_query);
	
	
	my ($code, $message, %headers);
	my $content = "";
	Glib::IO->add_watch($self->http->fileno, ['in'], sub {
		my (undef, $condition) = @_;
		
		# Read the headers
		if (!$code) {
			eval {
				($code, $message, %headers) = $self->http->read_response_headers();
			};
			if (my $error = $@) {
				# The server closed the socket reconnect and resume the HTTP GET
				$self->connect();
				$self->do_get($uri, $callback, $data);
				# We abort this I/O watch since another download will be started
				return FALSE;
			}
			
			# We return and continue when the server will have more data
			return TRUE;
		}
		
		
		# Read the content		
		my $line;
		my $n = $self->http->read_entity_body($line, 1024);
		$content .= $line;
		
		if ($self->http->keep_alive) {
			# In the case where the HTTP request has keep-alive we need to see if the
			# content has all arrived as read_entity_body() will not tell when the end
			# of the content has been reached.
			return TRUE unless length($content) == $headers{'Content-Length'};
		}
		elsif ($n) {
			# There's still data to read
			return TRUE;
		}
		
		# End of the document
		my $response = HTTP::Response->new($code, $message, [%headers], $content);
		$callback->($self, $uri, $response, $data);
		return FALSE;
	});
}

# A true value
1;
