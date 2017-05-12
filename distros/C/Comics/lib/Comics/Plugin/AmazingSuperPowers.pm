#! perl

use strict;
use warnings;

package Comics::Plugin::AmazingSuperPowers;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    # Ceased

    shift->SUPER::register
      ( { name    => "Amazing Super Powers",
	  url     => "http://www.amazingsuperpowers.com/",
	  disabled => 1,
	} );
}

# Important: Return the package name!
__PACKAGE__;
