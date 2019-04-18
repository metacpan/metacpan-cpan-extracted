#! perl

use strict;
use warnings;

package Comics::Plugin::Dilbert;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Dilbert";
our $url     = "http://dilbert.com/";
our $pattern =
	    qr{ <img \s+
		class="img-responsive \s img-comic" \s+
		width="\d+" \s+
		height="\d+" \s+
		alt="(?<alt>[^"]+)" \s+
		src="(?<url>(?:https?:)?//assets.amuniversal.com/
		       (?<image>.*?))"  \s+ />
	      }x;

# Important: Return the package name!
__PACKAGE__;
