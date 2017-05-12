#! perl

use strict;
use warnings;

package Comics::Plugin::Soopah;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Soopah",
	  url     => "http://soopahcomics.com/",
	  pat     =>
	    qr{ <div \s+ id="comic"> \s+
		<img \s+
		 src="(?<url>http://soopahcomics.com/wp-content/
		      uploads/\d+/\d+/
		      (?<image>.*?\.\w+))" \s+
		 alt="(?<alt>.*?)" \s+
		 title="(?<title>.*?)" \s* /> \s+
		</div>
              }sx,
	} );
}

# Important: Return the package name!
__PACKAGE__;
