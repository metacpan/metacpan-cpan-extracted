#! perl

use strict;
use warnings;

package Comics::Plugin::Megatokyo;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    shift->SUPER::register
      ( { name    => "Megatokyo",
	  url     => "http://megatokyo.com/",
	  pat     =>
	    qr{ <img \s+
		 align="middle" \s+
		 src="(?<url>strips/(?<image>.*?\.\w+))" \s+
		 alt="(?<alt>.*?)" \s+
		 title="(?<title>.*?)" \s+
		 />
	      }sx,
	} );
}

# Important: Return the package name!
__PACKAGE__;
