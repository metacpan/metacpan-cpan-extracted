#! perl

use strict;
use warnings;

package Comics::Plugin::MyJetpack;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "You're all just jealous of my Jetpack";
our $url     = "http://myjetpack.tumblr.com/";
our $pattern =
	    qr{ <a \s+
		 href="http://myjetpack.tumblr.com/image/\d+"> \s*
		 <img \s+
		 src="(?<url>http://.*?\.media\.tumblr\.com/
		 [0-9a-f]+/(?<image>.*?\.\w+))" \s+
		 alt=".*?" \s+ /></a>
	      }xs;

# Important: Return the package name!
__PACKAGE__;
