#! perl

use strict;
use warnings;

package Comics::Plugin::Garfield;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Garfield",
	  url     => "https://www.gocomics.com/garfield",
	} );
}

# Important: Return the package name!
__PACKAGE__;
