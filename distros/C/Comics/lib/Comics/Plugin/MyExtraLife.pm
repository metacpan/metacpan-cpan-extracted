#! perl

use strict;
use warnings;

package Comics::Plugin::MyExtraLife;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Extralife",
	  url     => "http://www.myextralife.com/",
	  pat	  =>
	    qr{ <img \s+
		class="comic" \s+
		src="(?<url>http://www.myextralife.com/wp-content/uploads/
		\d+/\d+/
		(?<image>[^./]+\.\w+))" \s+
	        alt="(?<alt>.*?)" \s+
	        title="(?<title>.*?)" \s+
		/>
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
