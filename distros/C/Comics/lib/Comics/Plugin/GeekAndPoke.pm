#! perl

use strict;
use warnings;

package Comics::Plugin::GeekAndPoke;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Geek&Poke",
	  url     => "http://geek-and-poke.com/",
	  pat	  =>
	    qr{ <noscript><img \s+
		src="(?<url>https://static1.squarespace.com/static/
		      [0-9a-f]+/t/[0-9a-f]+/
		      (?<image>[0-9a-f]+)/)" \s+
		/>
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
