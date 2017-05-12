#! perl

use strict;
use warnings;

package Comics::Plugin::KevinAndKell;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Kevin and Kell",
	  url     => "http://www.kevinandkell.com/",
	  pat	  =>
	    qr{ <img \s+
		src="(?<url>/\d+/strips/(?<image>kk\d+.\w+))" \s+
		alt="(?<alt>Comic \s Strip)"
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
