#! perl

use strict;
use warnings;

package Comics::Plugin::UserFriendly;

use parent qw(Comics::Fetcher::Cascade);

our $VERSION = "1.00";

our $name    = "User Friendly";
our $url     = "http://ars.userfriendly.org";
our $patterns = [
		 qr{ <a \s+ href="(?<url>.*?)">
                     <img \s+ alt="latest\s+strip"
	           }ix,
		 qr{ <img \s+
		     border="0" \s+
		     src="(?<url>https?://www.userfriendly.org/cartoons/archives/.+?/(?<image>[^.]+\.gif))" \s+
		     width="\d+" \s+ height="\d+" \s+
		     alt="Strip \s+ for \s+
	           }ix,
		 ];

# Important: Return the package name!
__PACKAGE__;
