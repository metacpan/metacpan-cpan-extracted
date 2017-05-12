#! perl

use strict;
use warnings;

package Comics::Plugin::WorkingDaze;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Working Daze",
	  url     => "http://www.comics.com/working_daze",
	} );
}

# Important: Return the package name!
__PACKAGE__;
