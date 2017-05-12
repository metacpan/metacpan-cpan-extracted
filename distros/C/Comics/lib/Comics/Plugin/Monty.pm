#! perl

use strict;
use warnings;

package Comics::Plugin::Monty;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.01";

sub register {
    shift->SUPER::register
      ( { name    => "Monty",
	} );
}

# Important: Return the package name!
__PACKAGE__;
