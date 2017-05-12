#! perl

use strict;
use warnings;

package Comics::Plugin::OverTheHedge;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Over the hedge",
	  url     => "http://www.comics.com/over_the_hedge",
	} );
}

# Important: Return the package name!
__PACKAGE__;
