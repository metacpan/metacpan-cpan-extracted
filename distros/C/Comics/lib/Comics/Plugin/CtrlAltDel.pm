#! perl

use strict;
use warnings;

package Comics::Plugin::CtrlAltDel;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "CTRL+ALT+DEL";
our $url     = "http://www.cad-comic.com/";
our $pattern =
	    qr{ <img \s+
		 class="comic-display" \s+
		 src="(?<url>http://(?:.*\.)?cad-comic\.com/
		       wp-content/uploads/\d+/\d+/
		      (?<image>.*?\.\w+))" \s+
	      }xs;

# Important: Return the package name!
__PACKAGE__;
