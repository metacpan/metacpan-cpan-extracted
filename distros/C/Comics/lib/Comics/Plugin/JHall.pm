#! perl

use strict;
use warnings;

package Comics::Plugin::JHall;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.03";

our $name    = "JHall";
our $url     = "https://jhallcomics.com/";

our $pattern =
	    qr{ <noscript>
		<img \s+ src="(?<url>https?://images.squarespace-cdn.com/
		content/v1/
		[-_0-9a-z]+/
		[-_0-9a-z]+/
		[-_0-9a-z]+/
		(?<image>[^./]+\.\w+))"
	       }xi,

# Important: Return the package name!
__PACKAGE__;
