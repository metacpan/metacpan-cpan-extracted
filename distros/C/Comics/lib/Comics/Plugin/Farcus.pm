#! perl

use strict;
use warnings;

package Comics::Plugin::Farcus;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Farcus",
	  url     => "https://www.gocomics.com/farcus",
	} );
}

# Important: Return the package name!
__PACKAGE__;
