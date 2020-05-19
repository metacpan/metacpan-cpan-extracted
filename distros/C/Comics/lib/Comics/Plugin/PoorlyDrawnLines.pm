#! perl

use strict;
use warnings;

package Comics::Plugin::PoorlyDrawnLines;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.02";

our $name    = "Poorly Drawn Lines";
our $url     = "http://www.poorlydrawnlines.com/";

our $pattern =
  qr{ <figure \s+ class="wp-block-image[^"]*"> \s*
      <img \s+
       src="(?<url>https?://www.poorlydrawnlines.com/wp-content/uploads/
	      \d+/\d+/
	      (?<image>.+?\.\w+))"
    }x;

# Important: Return the package name!
__PACKAGE__;
