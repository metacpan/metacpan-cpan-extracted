#! perl

use strict;
use warnings;

package Comics::Plugin::EvertKwok;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    # Seems to rely on JavaScript...

    shift->SUPER::register
      ( { name    => "Evert Kwok",
	  url     => "http://www.evertkwok.nl/",
	  disabled => 1,
	} );
}

# Important: Return the package name!
__PACKAGE__;
