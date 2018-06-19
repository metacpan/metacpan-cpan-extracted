#! perl

use strict;
use warnings;

package Comics::Plugin::MyJetpack;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.02";

our $name    = "You're all just jealous of my Jetpack";
our $url     = "https://twitter.com/tomgauld";
our $pattern =
	    qr{ <div \s+
		 class="AdaptiveMedia-photoContainer \s+
		 js-adaptive-photo \s* "
		 \s+
		 data-image-url="(?<url>https://pbs.twimg.com/media/(?<image>.*?\.\w+))"
	      }xs;

# Important: Return the package name!
__PACKAGE__;
