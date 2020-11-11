#! perl

use strict;
use warnings;

package Comics::Plugin::DoYouKnowFlo;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.05";

our $name    = "Do you know Flo?";
our $url     = "https://www.doyouknowflo.nl/";
our $pattern =
	    qr{ <img \s+ (?:loading="lazy" \s+)?
		 class="alignright \s+ wp-image-\d+ \s+ size-full" \s+
		 src="(?<url>https?://doyouknowflo.nl/
		        uploads/\d+/\d+/
			(?<image>.*?\.\w+))" \s+
	      }sx;

# Important: Return the package name!
__PACKAGE__;
