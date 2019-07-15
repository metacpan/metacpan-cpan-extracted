#! perl

use strict;
use warnings;

package Comics::Plugin::TheWarehouse;

use parent qw(Comics::Fetcher::Single);

our $disabled = 1;		# seems defunct

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "The Warehouse",
	  url     => "http://www.warehousecomic.com/",
	  pat	  =>
	    qr{ <img \s+
		src="(?<url>http://warehousecomic.com/wp-content/uploads/
		      (?<image>\d+/\d+/\d+-\d+-\d+-.*?\.\w+))" \s+
		alt="(?<alt>.*?)" \s+
		title="(?<title>.*?)" \s+
		/>
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
