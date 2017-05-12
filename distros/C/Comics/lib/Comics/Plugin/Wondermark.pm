#! perl

use strict;
use warnings;

package Comics::Plugin::Wondermark;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    shift->SUPER::register
      ( { name    => "Wondermark",
	  url     => "http://wondermark.com/",
	  pat     =>
	    qr{ <div \s+ id="comic"> \s+
		<img \s+
		 src="(?<url>http://wondermark.com/c/
		        (?<image>.*?\.\w+))" \s+
		 alt="(?<alt>.*?)" \s+
		 title="(?<title>.*?)" \s+
		 />
	      }sx,
	} );
}

# Important: Return the package name!
__PACKAGE__;
