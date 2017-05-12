#! perl

use strict;
use warnings;

package Comics::Plugin::LittleGamers;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    # Ceased

    shift->SUPER::register
      ( { name    => "Little Gamers",
	  url     => "http://www.little-gamers.com/",
	  pat     =>
	    qr{ <meta \s+
		 property="og:image" \s+
		 content="(?<url>http://little-gamers.com/comics/
		           (?<image>.*?\.\w+))" \s* />
	      }six,
	} );
}

# Important: Return the package name!
__PACKAGE__;
