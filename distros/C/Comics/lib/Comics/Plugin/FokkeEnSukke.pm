#! perl

use strict;
use warnings;

package Comics::Plugin::FokkeEnSukke;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.02";

sub register {
    shift->SUPER::register
      ( { name    => "Fokke en Sukke",
	  url     => "http://www.foksuk.nl/",
	  pat	  =>
	    qr{ <img \s+
		src="(?<url>content/formfield_files/
		  (?<image>formcartoon_[^./]+\.\w+))" \s+
		width="\d+" \s+
		height="\d+" \s+
	        alt="(?<alt>.*?)" \s+
		/>
	      }x,
	} );
}

# Important: Return the package name!
__PACKAGE__;
