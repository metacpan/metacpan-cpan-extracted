#! perl

use strict;
use warnings;

package Comics::Plugin::Rubes;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Rubes",
	  url     => "https://www.gocomics.com/rubes",
	} );
}

# Important: Return the package name!
__PACKAGE__;
