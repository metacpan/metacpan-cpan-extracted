#! perl

use strict;
use warnings;

package Comics::Plugin::Nozzman;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Nozzman";
our $url     = "http://www.nozzman.nl/cartoons/";

our $pattern =
  qr{ <noscript>
      <img \s+
       src="(?<url>https://images.squarespace-cdn.com/
	     content/v1/
		[-_0-9a-z]+/
		[-_0-9a-z]+/
		[-_0-9a-z]+/
		(?<image>[^./]+\.\w+))"
    }ix;

# Important: Return the package name!
__PACKAGE__;
