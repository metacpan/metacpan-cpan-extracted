#! perl

use strict;
use warnings;

package Comics::Plugin::PlayerVsPlayer;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "0.01";

sub register {
    shift->SUPER::register
      ( { name    => "Player vs Player",
	  url     => "http://www.pvponline.com/comic/",
	  pat     =>
	    qr{ <section \s+ class="comic-art"> \s+
		<img \s+
		 src="(?<url>http://.*?\.amazonaws\.com/pvponlinenew/img/
		       comic/\d+/\d+/
		       (?<image>.*?))" \s+
		 alt="(?<alt>.*?)" \s* /> \s+
		 </section>
              }sx,
	} );
}

# Important: Return the package name!
__PACKAGE__;
