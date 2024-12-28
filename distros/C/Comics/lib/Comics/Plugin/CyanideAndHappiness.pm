#! perl

use strict;
use warnings;

package Comics::Plugin::CyanideAndHappiness;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.02";

our $name    = "Cyanide & Happiness (Explosm.net)";
our $url     = "https://explosm.net/comics/latest";
our $pattern =
	    qr{ as="image" \s+
		href="(?<url>https://static.explosm.net
		    /\d+/\d+/\d+/
		    (?<image>[^.]+\.\w+))
	      }x;

# Important: Return the package name!
__PACKAGE__;
