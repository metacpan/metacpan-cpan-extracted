#! perl

use strict;
use warnings;

package Comics::Plugin::ASofterWorld;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    # Ceased

    shift->SUPER::register
      ( { name    => "A Softer World",
	  url     => "http://www.asofterworld.com/",
	  disabled => 1,
	} );
}

# Important: Return the package name!
__PACKAGE__;
