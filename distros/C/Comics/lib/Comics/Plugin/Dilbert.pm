#! perl

use strict;
use warnings;

package Comics::Plugin::Dilbert;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Dilbert",
	  url     => "http://dilbert.com/",
	  pat	  =>
	    qr{ <img \s+
		class="img-responsive \s img-comic" \s+
		width="\d+" \s+
		height="\d+" \s+
		alt="(?<alt>[^"]+)" \s+
		src="(?<url>http://assets.amuniversal.com/
		       (?<image>.*?))"  \s+ />
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
