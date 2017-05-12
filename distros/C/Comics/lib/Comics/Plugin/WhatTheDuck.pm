#! perl

use strict;
use warnings;

package Comics::Plugin::WhatTheDuck;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "What the Duck",
	  url     => "http://www.whattheduck.net/",
	  pat	  =>
	    qr{ <img \s+
		src="(?<url>http://\d+\.media\.tumblr\.com/
		[0-9a-f]{32}/
		(?<image>tumblr_.*?_1280\.\w+))" \s+
	        alt="(?<alt>WTD.*?)" \s+
		width="\d+" \s+
		height="\d+" \s*
		>
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
