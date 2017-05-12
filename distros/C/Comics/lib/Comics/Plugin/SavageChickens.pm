#! perl

use strict;
use warnings;

package Comics::Plugin::SavageChickens;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    shift->SUPER::register
      ( { name    => "Savage Chickens",
	  url     => "http://www.savagechickens.com/",
	  pat     =>
	    qr{ <div \s+ class="entry_content"> \s+
		<p> \s*
		<img \s+
		 src="(?<url>http://www.savagechickens.com/
		        wp-content/uploads/
		       (?<image>.*?\.\w+))" \s+
		 alt="(?<alt>.*?)" \s+
		 width="\d+" \s+ height="\d+" \s*
		 /> \s* </p>
	      }sx,
	} );
}

# Important: Return the package name!
__PACKAGE__;
