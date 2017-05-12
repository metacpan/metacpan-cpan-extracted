#! perl

use strict;
use warnings;

package Comics::Plugin::TheJoyOfTech;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "The Joy of Tech";
our $url     = "http://www.joyoftech.com/joyoftech/";
our $pattern =
	    qr{ <img \s+
		src="(?<url>joyimages/
		  (?<image>[^./]+\.\w+))" \s+
	        alt="(?<alt>.*?)" \s+
		width="\d+" \s+
		height="\d+" \s*
	      }x;

# Important: Return the package name!
__PACKAGE__;
