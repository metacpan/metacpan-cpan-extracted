#! perl

use strict;
use warnings;

package Comics::Plugin::SoopahBonus;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.03";

sub register {
    shift->SUPER::register
      ( { name    => "Soopah Bonus Strip",
	  url     => "http://soopahcomics.com/",
	  pat     =>
	    qr{ <h3 \s+ style=".*?">Bonus \s+ Comic</h3> \s+
		<p \s+ style=".*?"> \s*
		<img \s+ class=".*?" \s+
		 src="(?<url>http://soopahcomics.com/wp-content/
		      uploads/\d+/\d+/
		      (?<image>.*?\.\w+))" \s+
		 alt="(?<alt>.*?)" \s+
              }sx,
	  optional => 1,
	} );
}

our $disabled = 1;

# Important: Return the package name!
__PACKAGE__;
