#! perl

use strict;
use warnings;

package Comics::Plugin::AMultiverse;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.02";

our $name    = "Scenes From A Multiverse";
our $url     = "https://amultiverse.com/";
our $disabled = 1;		# deceased

our $pattern =
	    qr{ <meta \s+ property="og:image" \s+
		 content="(?<url>(?:https?:)?//i\d.wp.com/amultiverse.com/
		              wp-content/uploads/\d+/\d+/
			      (?<image>.*?\.\w+))
	      }six;

# Important: Return the package name!
__PACKAGE__;
