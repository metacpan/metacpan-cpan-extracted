#! perl

use strict;
use warnings;

package Comics::Plugin::PoorlyDrawnLines;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.04";

our $name    = "Poorly Drawn Lines";
our $url     = "http://www.poorlydrawnlines.com/";

our $pattern =
  qr{ <div \s+ class="wp-block-image[^"]*"> \s*
      <figure \s+ class=".*?">
      <img \s+ (?: (?:loading|width|height) = "[^"]+" \s+ )*
       src="(?<url>https?://www.poorlydrawnlines.com/wp-content/uploads/
	      \d+/\d+/
	      (?<image>.+?\.\w+))"
    }x;

# Important: Return the package name!
__PACKAGE__;
