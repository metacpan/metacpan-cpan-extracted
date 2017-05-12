#! perl

use strict;
use warnings;

package Comics::Plugin::CyanideAndHappiness;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Cyanide & Happiness (Explosm.net)",
	  url     => "http://explosm.net/",
	  pat	  =>
	    qr{ <img \s+
		id="featured-comic" \s+
		src="(?<url>//files.explosm.net/comics/
		(?:.+?/)?
		(?<image>[^./]+\.\w+))
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
