#! perl

use strict;
use warnings;

package Comics::Plugin::Glasbergen;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.03";

our $name    = "Glasbergen";
our $url     = "http://www.glasbergen.com";
our $pattern =
	    qr{ <div \s+ class="ngg-widget \s+ entry-content" \s* > \s*
		<a \s+ href="(?<url>https?://www.glasbergen.com/wp-content/
		gallery/cartoons/(?<image>.+?))" \s*
	      }x;

# Important: Return the package name!
__PACKAGE__;
