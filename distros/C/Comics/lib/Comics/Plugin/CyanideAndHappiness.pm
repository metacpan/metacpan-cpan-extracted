#! perl

use strict;
use warnings;

package Comics::Plugin::CyanideAndHappiness;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Cyanide & Happiness (Explosm.net)";
our $url     = "http://explosm.net/";
our $pattern =
	    qr{ <img \s+
		id="main-comic" \s+
		src="(?<url>//files.explosm.net/comics/
		(?:.+?/)?
		(?<image>[^./]+\.\w+))
	      }x;

# Important: Return the package name!
__PACKAGE__;
