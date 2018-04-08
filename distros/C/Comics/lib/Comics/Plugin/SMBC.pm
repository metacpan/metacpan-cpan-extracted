#! perl

use strict;
use warnings;

package Comics::Plugin::SMBC;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Saturday Morning Breakfast Cereal";
our $url     = "http://www.smbc-comics.com/";
our $pattern =
	    qr{ <img \s+
	        title="(?<title>.*?)" \s+
		src="(?<url>/comics/
		  (?<image>[^./]+\.\w+))" \s+
	        id="cc-comic" \s+
		border="\d+" \s+
		/>
	      }x;

# Important: Return the package name!
__PACKAGE__;
