#!/usr/bin/env perl

use 5.10.0;     

# Linux: Path to libraries (local) 
use lib qw(/home/bislinks/perl5/lib/perl5);

my %sys;
%sys = (
	images_dir => "/home/bislinks/public_html/images/a1z-html5-template",
	thumbs_dir => "/home/bislinks/public_html/images/a1z-html5-template/thumbnails",
		
	images_url => "/images/a1z-html5-template/",
	thumbs_url => "/images/a1z-html5-template/thumbnails",
);

use A1z::HTML5::Template;
my $h = A1z::HTML5::Template->new();

my $images;  
$images = $h->display_gallery_thumbnails(

	images_dir => "$sys{images_dir}",
	thumbs_dir => "$sys{thumbs_dir}",
		
	images_url => "$sys{images_url}",
	thumbs_url => "$sys{thumbs_url}",

	width => "100",
	height => "100",
);

say $h->head( 
	-title => "Simple Template",
	-cssLinks => "https://blueimp.github.io/Gallery/css/blueimp-gallery.min.css",
	
);
say $h->body( 

	-h1 => "Simple Template", 
	-onload => "",
	-content => qq{
	<div class="container"><h2>Slideshow</h2>
		<div id="links">$images</div>
	</div>
	},
	-nbmenu => "More",
);

