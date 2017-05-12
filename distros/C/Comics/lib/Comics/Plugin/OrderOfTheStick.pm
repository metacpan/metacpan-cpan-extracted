#! perl

use strict;
use warnings;

package Comics::Plugin::OrderOfTheStick;

use parent qw(Comics::Fetcher::Cascade);

our $VERSION = "0.01";

sub register {

    shift->SUPER::register
      ( { name    => "Order of the Stick",
	  url     => "http://www.giantitp.com/comics/oots.html",
	  pats    =>
	   [ qr{ <p \s+
		  class="ComicList"> .*?
		  <a \s+
		   href="(?<url>/comics/.*?\.html)">(?<title>.*?)
		  </a>
	       }six,
	     qr{ <td \s+
		  align="center"> \s*
		 <img \s+
		  src="(?<url>/comics/images/(?<image>.*?\.\w+))"> \s*
		 </td>
	      }six,
	   ],
	} );
}

# Important: Return the package name!
__PACKAGE__;
