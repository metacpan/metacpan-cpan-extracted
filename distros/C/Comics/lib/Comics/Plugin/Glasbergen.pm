#! perl

use strict;
use warnings;

package Comics::Plugin::Glasbergen;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Glasbergen";
our $url     = "http://www.glasbergen.com";
our $pattern =
	    qr{ <img \s+ class="ngg-singlepic" \s+
		(?: title="(?<title>.*?)" \s+ )?
		(?: alt="(?<alt>.*?)" \s+ )?
		src="(?<url>http://www.glasbergen.com/wp-content/
		gallery/cartoons/(?<image>.+?))" \s*
	      }x;

# Important: Return the package name!
__PACKAGE__;
