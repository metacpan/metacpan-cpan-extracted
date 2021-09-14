#! perl

use strict;
use warnings;

package Comics::Plugin::Sinfest;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Sinfest";
our $url     = "https://sinfest.xyz/";
our $pattern =
	    qr{ <img \s+
		src="(?<url>btphp/comics/(?<image>\d+-\d+-\d+\.(?:jpg|gif)))" \s+
		alt="(?<alt>.*?)">
	      }x;

# Important: Return the package name!
__PACKAGE__;
