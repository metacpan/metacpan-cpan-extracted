#! perl

use strict;
use warnings;

package Comics::Plugin::AMultiverse;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Scenes From A Multiverse";
our $url     = "http://amultiverse.com/";
our $pattern =
	    qr{ <div \s+ id="comic"> \s*
		<img \s+
		 src="(?<url>(?:http:)?//amultiverse.com/
		              wp-content/uploads/\d+/\d+/
			      (?<image>.*?\.\w+))" \s+
		 alt="(?<alt>.*?)"
	      }six;

# Important: Return the package name!
__PACKAGE__;
