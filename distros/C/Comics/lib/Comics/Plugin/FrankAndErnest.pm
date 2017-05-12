#! perl

use strict;
use warnings;

package Comics::Plugin::FrankAndErnest;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.01";

sub register {
    shift->SUPER::register
      ( { name    => "Frank & Ernest",
	  url     => "http://www.gocomics.com/frank-and-ernest/",
	} );
}

# Important: Return the package name!
__PACKAGE__;
