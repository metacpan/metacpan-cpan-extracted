#! perl

use strict;
use warnings;

package Comics::Plugin::DieselSweeties;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    # Ceased

    shift->SUPER::register
      ( { name    => "Diesel Sweeties",
	  url     => "http://www.dieselsweeties.com/",
	  pat     =>
	    qr{ <img \s+
		 class="xomic" \s+
		 title="(?<alt>.*?)" \s+
		 alt="(?<title>.*?)" \s+
		 src="(?<url>/strips666/(?<image>.*?\.\w+))" \s*
		 />

	      }six,
	} );
}

# Important: Return the package name!
__PACKAGE__;
