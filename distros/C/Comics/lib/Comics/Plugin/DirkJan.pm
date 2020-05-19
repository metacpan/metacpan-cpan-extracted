#! perl

use strict;
use warnings;

package Comics::Plugin::DirkJan;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "DirkJan";
our $url     = "https://dirkjan.nl/";
our $pattern =
	    qr{ <meta \s+ property="og:image" \s*
		 content="(?<url>https://dirkjan.nl/wp-content/uploads/
		            \d+/\d+/(?<image>.*?\.\w+))" \s* />
	      }x;

# Important: Return the package name!
__PACKAGE__;
