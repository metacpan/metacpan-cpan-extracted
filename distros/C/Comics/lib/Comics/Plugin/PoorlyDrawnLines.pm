#! perl

use strict;
use warnings;

package Comics::Plugin::PoorlyDrawnLines;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Poorly Drawn Lines";
our $url     = "http://www.poorlydrawnlines.com/";

our $pattern =
  qr{ <div \s+ class="post"> \s*
      <p> \s*
      <img \s+ class=".*?" \s+
       src="(?<url>http://www.poorlydrawnlines.com/wp-content/uploads/
	      \d+/\d+/
	      (?<image>.+?\.\w+))"
    }x;

# Important: Return the package name!
__PACKAGE__;
