#! perl

use strict;
use warnings;

package Comics::Plugin::Nozzman;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {
    shift->SUPER::register
      ( { name    => "Nozzman",
	  url     => "http://www.nozzman.nl/cartoons/",
	  pat    =>
	    qr{ data-image="(?<url>https://static.*?squarespace.com/static/
		[0-9a-f]+/t/(?<image>[0-9a-f]+/\d+/))"
	      }six,
	} );
}

# Important: Return the package name!
__PACKAGE__;
