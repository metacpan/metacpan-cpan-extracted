#! perl

use strict;
use warnings;

package Comics::Plugin::OffTheMark;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Off the mark",
	  url     => "https://www.gocomics.com/off_the_mark",
	} );
}

# Important: Return the package name!
__PACKAGE__;
