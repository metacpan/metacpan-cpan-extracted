#! perl

use strict;
use warnings;

package Comics::Plugin::APOKALIPS;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    # Ceased

    shift->SUPER::register
      ( { name    => "APOKALIPS",
	  url     => "http://myapokalips.com/",
	  disabled => 1,
	} );
}

# Important: Return the package name!
__PACKAGE__;
