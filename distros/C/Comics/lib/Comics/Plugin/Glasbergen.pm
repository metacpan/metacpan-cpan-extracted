#! perl

use strict;
use warnings;

package Comics::Plugin::Glasbergen;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.04";

our $name    = "Glasbergen";
our $url     = "https://www.glasbergen.com";
our $pattern =
	    qr{ <meta \s+
		 name="twitter:image" \s+
		 content="(?<url>https?://www.glasbergen.com/wp-content/
		     uploads/\d+/\d+/(?<image>.+?))"
	      }x;

# Important: Return the package name!
__PACKAGE__;
