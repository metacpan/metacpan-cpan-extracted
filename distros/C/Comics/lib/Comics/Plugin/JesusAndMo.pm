#! perl

use strict;
use warnings;

package Comics::Plugin::JesusAndMo;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Jesus and Mo",
	  url     => "http://www.jesusandmo.net/",
	  pat	  =>
	    qr{ <img \s+
		src="(?<url>http://www.jesusandmo.net/wp-content/uploads/
		  (?<image>[^./]+\.\w+))" \s+
	        alt="(?<alt>.*?)" \s+
	        title="(?<title>.*?)" \s+
		/>
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
