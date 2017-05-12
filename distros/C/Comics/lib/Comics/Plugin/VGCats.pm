#! perl

use strict;
use warnings;

package Comics::Plugin::VGCats;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {
    shift->SUPER::register
      ( { name    => "VG Cats",
	  url     => "http://www.vgcats.com/comics/",
	  pat     =>
	    qr{ <img \s+
		 src="(?<url>images/(?<image>.*?\.\w+))" \s+
		 width="\d+" \s+
		 height="\d+"
	      }six,
	} );
}

# Important: Return the package name!
__PACKAGE__;
