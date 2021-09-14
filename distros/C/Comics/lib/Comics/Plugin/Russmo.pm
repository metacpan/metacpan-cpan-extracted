#! perl

use strict;
use warnings;

package Comics::Plugin::Russmo;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.02";

our $name    = "Russmo";
our $url     = "http://russmo.com";
our $pattern =
	    qr{ <figure \s+ class="wp-block-image \s+ is-resized"> \s*
		<img \s+
		src="(?<url>https?://russmo.com/wp-content/
		uploads/\d+/\d+/(?<image>\d+.+?))" \s+
	        alt="" \s+
	        class="wp-image-\d+"
	      }x;

our $disabled = 1;		# ceased?

# Important: Return the package name!
__PACKAGE__;
