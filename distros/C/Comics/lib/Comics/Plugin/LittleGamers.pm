#! perl

use strict;
use warnings;

package Comics::Plugin::LittleGamers;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.02";

our $name    = "Little Gamers";
our $url     = "http://www.little-gamers.com/";
our $pattern =
	    qr{ <meta \s+
		 property="og:image" \s+
		 content="(?<url>https?://little-gamers.com/comics/
		           (?<image>.*?\.\w+))" \s* /?>
	      }six;

# Important: Return the package name!
__PACKAGE__;
