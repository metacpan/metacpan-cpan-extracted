#! perl

use strict;
use warnings;

package Comics::Plugin::CyanideAndHappiness;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Cyanide & Happiness (Explosm.net)";
our $url     = "https://explosm.net/";
our $pattern =
	    qr{ <img \s+
		src="(?<url>https://static.explosm.net
		    /\d+/\d+/\d+/
		    (?<image>[^.]+\.\w+))
	      }x;

# Important: Return the package name!
__PACKAGE__;
