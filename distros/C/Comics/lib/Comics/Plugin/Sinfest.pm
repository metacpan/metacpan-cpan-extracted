#! perl

use strict;
use warnings;

package Comics::Plugin::Sinfest;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Sinfest",
	  url     => "http://www.sinfest.net/",
	  pat	  =>
	    qr{ <img \s+
		src="(?<url>btphp/comics/(?<image>\d+-\d+-\d+\.gif))" \s+
		alt="(?<alt>.*?)">
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
