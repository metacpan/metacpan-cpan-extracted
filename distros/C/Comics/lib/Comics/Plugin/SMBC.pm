#! perl

use strict;
use warnings;

package Comics::Plugin::SMBC;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Saturday Morning Breakfast Cereal",
	  url     => "http://www.smbc-comics.com/",
	  pat	  =>
	    qr{ <img \s+
	        title="(?<title>.*?)" \s+
		src="(?<url>http://www.smbc-comics.com/comics/
		  (?<image>[^./]+\.\w+))" \s+
	        id="cc-comic" \s+
		border="\d+" \s+
		/>
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
