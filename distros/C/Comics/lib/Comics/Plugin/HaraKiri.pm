#! perl

use strict;
use warnings;

package Comics::Plugin::HaraKiri;

use parent qw(Comics::Fetcher::Cascade);

our $VERSION = "0.01";

sub register {
    shift->SUPER::register
      ( { name    => "Hara Kiri",
	  url     => "http://www.lectrr.be/nl/",
	  pats    =>
	   [
	    qr{ <h2>Recentste \s Hara \s Kiwi-toon</h2> \s*
		<ul \s+ class="toonlink"> \s*
		<li> \s*
		<a \s+
		 href="(?<url>/nl/cartoon/.*?)">
		(?<title>.*?)</a> \s*
		</li>
	      }six,
	    qr{ <article \s+
		 id="cartoon" \s+
		 class="bigcartoon"> \s*
		<img \s+
		 src="(?<url>/files/attachments/.*?/(?<image>.*?\.\w+))" \s+
		 title="(?<title>.*?)"
	      }six,
	   ],
	} );
}

# Important: Return the package name!
__PACKAGE__;
