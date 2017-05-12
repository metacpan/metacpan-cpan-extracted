#! perl

use strict;
use warnings;

package Comics::Plugin::GarfieldMinusGarfield;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Garfield minus Garfield";
our $url     = "http://garfieldminusgarfield.net/";
our $pattern =
	    qr{ <div \s+
		class="photo"> \s*
		<a \s+ href=".*?"> \s*
		<img \s+
		 src="(?<url>http://.*?\.media\.tumblr\.com/
		 [0-9a-f]+/
		 (?<image>.*?\.\w+))" \s+
	         alt=".*?"/> \s*
		 </a>
	      }six;

# Important: Return the package name!
__PACKAGE__;
