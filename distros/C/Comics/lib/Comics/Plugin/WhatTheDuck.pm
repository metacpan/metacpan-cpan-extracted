#! perl

use strict;
use warnings;

package Comics::Plugin::WhatTheDuck;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "What the Duck";
our $url     = "https://www.whattheduck.net/";
our $disabled = 1;		# stopped

our $pattern =
	    qr{ <img \s+
		src="(?<url>https?://\d+\.media\.tumblr\.com/
		[0-9a-f]{32}/
		(?<image>tumblr_.*?_(?:1280|640)\.\w+))" \s+
	        alt="(?<alt>WTD.*?)" \s+
		width="\d+" \s+
		height="\d+" \s*
		>
	      }x;

# Important: Return the package name!
__PACKAGE__;
