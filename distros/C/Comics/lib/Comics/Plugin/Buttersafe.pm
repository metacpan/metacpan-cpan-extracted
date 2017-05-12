#! perl

use strict;
use warnings;

package Comics::Plugin::Buttersafe;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Buttersafe",
	  url     => "http://www.buttersafe.com/",
	  pat	  =>
	    qr{ <img \s+
		src="(?<url>http://buttersafe.com/comics/
		(?<image>\d+-\d+-\d+-[^./]+\.\w+))" \s+
	        alt="(?<alt>.*?)" \s+
		/>
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
