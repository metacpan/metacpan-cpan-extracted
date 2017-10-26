#! perl

use strict;
use warnings;

package Comics::Plugin::RedMeat;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Red Meat";
our $url     = "http://redmeat.com/max-cannon/FreshMeat/";
our $pattern =
	    qr{ <meta \s+
		 name="description" \s+
		 content="(?<title>.*?)" \s* />
		.*?
		<div \s+ class="comicStrip"> \s+
		<a \s+
		 href="https?://www.redmeat.com/max-cannon/.*?"> \s*
		<img \s+
		 src="(?<url>https?://.*?\.fdncms\.com/
		        redmeat/imager/u/redmeat/
			\d+/(?<image>.*?\.\w+))" \s+
		 width="\d+" \s+ height="\d+" \s+
		 alt="(?<alt>.*?)" \s*
		 /> \s* </a> \s*
		</div>
	      }sx;

# Important: Return the package name!
__PACKAGE__;
