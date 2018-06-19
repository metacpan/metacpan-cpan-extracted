#! perl

use strict;
use warnings;

package Comics::Plugin::SMBC;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Saturday Morning Breakfast Cereal";
our $url     = "https://www.smbc-comics.com/";
our $pattern =
	    qr{ <div \s+ id="cc-comicbody"> \s*
		<img \s+
	        title="(?<title>.*?)" \s+
		src="(?:https?://www.smbc-comics.com)?(?<url>/comics/
		  (?<image>[^./]+\.\w+))" \s+
	        id="cc-comic" \s+
		/>
	      }x;

# Important: Return the package name!
__PACKAGE__;
