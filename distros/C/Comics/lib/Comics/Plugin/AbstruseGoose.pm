#! perl

use strict;
use warnings;

package Comics::Plugin::AbstruseGoose;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    # Seems to be gone...

    shift->SUPER::register
      ( { name    => "Abstruse Goose",
	  url     => "http://abstrusegoose.com/",
	  disabled => 1,
	} );
}

# Important: Return the package name!
__PACKAGE__;
