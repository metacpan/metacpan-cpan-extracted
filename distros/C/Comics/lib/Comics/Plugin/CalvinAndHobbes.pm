#! perl

use strict;
use warnings;

package Comics::Plugin::CalvinAndHobbes;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Calvin and Hobbes",
	  url     => "http://www.comics.com/calvinandhobbes",
	} );
}

# Important: Return the package name!
__PACKAGE__;
