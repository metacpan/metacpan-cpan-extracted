#! perl

use strict;
use warnings;

package Comics::Plugin::DirkJan;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {
    shift->SUPER::register
      ( { name    => "DirkJan",
	  url     => "http://dirkjan.nl/",
	  pat	  =>
	    qr{ <meta \s+ property="og:image" \s*
		 content="(?<url>http://dirkjan.nl/wp-content/uploads/
		            \d+/\d+/(?<image>.*?\.\w+))" \s* />
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
