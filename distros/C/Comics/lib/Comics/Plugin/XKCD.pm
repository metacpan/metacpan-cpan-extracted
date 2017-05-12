#! perl

use strict;
use warnings;

package Comics::Plugin::XKCD;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "XKCD",
	  url     => "http://www.xkcd.com",
	  pat     =>
	    qr{ <img \s+
		src="(?<url>//imgs\.xkcd\.com/comics/
		(?<image>.*?\.png))" \s+
	        title="(?<title>.*?)" \s+
	        alt="(?<alt>.*?)" \s* />
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
