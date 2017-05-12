#! perl

use strict;
use warnings;

package Comics::Plugin::DominicDeegan;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    # Ceased

    shift->SUPER::register
      ( { name    => "Dominic Deegan",
	  url     => "http://www.dominic-deegan.com/",
	  disabled => 1,
	} );
}

# Important: Return the package name!
__PACKAGE__;
