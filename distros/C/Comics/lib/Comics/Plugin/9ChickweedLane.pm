#! perl

use strict;
use warnings;

package Comics::Plugin::9ChickweedLane;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "9 Chickweed Lane",
	  url     => "https://www.gocomics.com/9_chickweed_lane",
	} );
}

# Important: Return the package name!
__PACKAGE__;
