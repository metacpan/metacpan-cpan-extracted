#! perl

use strict;
use warnings;

package Comics::Plugin::UserFriendly;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

#### TODO: Should use multiple fetcher.

sub register {
    shift->SUPER::register
      ( { name    => "User Friendly",
	  url     => "http://ars.userfriendly.org",
	  pat	  =>
	    qr{ <img \s+
		alt="Latest \s Strip" \s+
		height="\d+" \s+ width="\d+" \s+
		border=0 \s+
		src="(?<url>[^"]+/cartoons/archives/[^"]+/(?<image>[^.]+\.gif))"
	      }ix,
	 } );
}

# Important: Return the package name!
__PACKAGE__;
