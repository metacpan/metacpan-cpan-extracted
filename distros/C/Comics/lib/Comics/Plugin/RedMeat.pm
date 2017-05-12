#! perl

use strict;
use warnings;

package Comics::Plugin::RedMeat;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    shift->SUPER::register
      ( { name    => "Red Meat",
	  url     => "http://redmeat.com/max-cannon/FreshMeat/",
	  pat     =>
	    qr{ <meta \s+
		 name="description" \s+
		 content="(?<title>.*?)" \s* />
		.*?
		<div \s+ class="comicStrip"> \s+
		<a \s+
		 href="http://www.redmeat.com/max-cannon/.*?"> \s*
		<img \s+
		 src="(?<url>http://.*?\.fdncms\.com/
		        redmeat/imager/u/redmeat/
			\d+/(?<image>.*?\.\w+))" \s+
		 width="\d+" \s+ height="\d+" \s+
		 alt="(?<alt>.*?)" \s*
		 /> \s* </a> \s*
		</div>
	      }sx,
	} );
}

# Important: Return the package name!
__PACKAGE__;
