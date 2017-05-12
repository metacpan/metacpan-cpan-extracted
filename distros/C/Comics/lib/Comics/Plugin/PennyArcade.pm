#! perl

use strict;
use warnings;

package Comics::Plugin::PennyArcade;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {

    shift->SUPER::register
      ( { name    => "Penny Arcade",
	  url     => "http://www.penny-arcade.com/comic/",
	  pat     =>
	    qr{ <div \s+
		 id="comicFrame"> \s*
		<img \s+
		 src="(?<url>https://photos.smugmug.com/Comics/Pa-comics/
		      .*?/
		      (?<image>.*?\.\w+))" \s+
	         alt="(?<alt>.*?)" \s+
		 width="\d+" \s* /> \s*
		</div>
   
            }six,
	} );
}

# Important: Return the package name!
__PACKAGE__;
