#! perl

use strict;
use warnings;

package Comics::Plugin::Frogpants;
# FKA Comics::Plugin::MyExtraLife;

use parent qw(Comics::Fetcher::Cascade);

our $VERSION = "1.01";

our $name    = "Extralife";
our $url     = "http://www.frogpants.com/";
our $patterns = [
	    qr{ <a \s+ href="(?<url>.*?)" \s* >Comics \s+ &amp; \s+ art</a>
            }xi,
	    qr{ <img \s+
		data-load="false" \s+
		data-src="(?<url>https?://static\d.squarespace.com/static/
		[0-9a-f]+/
		[0-9a-f]+/
		[0-9a-f]+/
		[0-9]+/
		(?<image>[^./]+\.\w+))"
	       }xi,
	 ];

# Important: Return the package name!
__PACKAGE__;
