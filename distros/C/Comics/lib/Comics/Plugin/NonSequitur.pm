#! perl

use strict;
use warnings;

package Comics::Plugin::NonSequitur;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.01";

sub register {
    shift->SUPER::register
      ( { name    => "Non Sequitur",
	  tag	  => "nonsequitur",
	} );
}

# Important: Return the package name!
__PACKAGE__;
