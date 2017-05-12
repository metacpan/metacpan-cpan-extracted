#! perl

use strict;
use warnings;

package Comics::Plugin::HeinDeKort;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    # Ceased

    shift->SUPER::register
      ( { name    => "Hein de Kort",
	  url     => "http://www.heindekort.nl/",
	  disabled => 1,
	} );
}

# Important: Return the package name!
__PACKAGE__;
