#! perl

use strict;
use warnings;

package Comics::Plugin::Russmo;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Russmo";
our $url     = "http://russmo.com";
our $pattern =
	    qr{ <img \s+ class="alignleft \s+ wp-image-530" \s+
		src="(?<url>https?://russmo.com/wp-content/
		uploads/\d+/\d+/(?<image>\d+.+?))" \s*
	      }x;

# Important: Return the package name!
__PACKAGE__;
