#! perl

use strict;
use warnings;

package Comics::Plugin::Lectrr;

use parent qw(Comics::Fetcher::Cascade);

our $VERSION = "0.01";

sub register {
    shift->SUPER::register
      ( { name    => "Lectrr",
	  url     => "http://www.lectrr.be/nl/",
	  pats    =>
	   [
	    qr{ <ul \s+
		 class="toonlink"> \s*
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
