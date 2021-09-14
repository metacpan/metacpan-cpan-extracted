#! perl

use strict;
use warnings;

package Comics::Plugin::PoorlyDrawnLines;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.06";

our $name    = "Poorly Drawn Lines";
our $url     = "https://www.poorlydrawnlines.com/";

our $pattern =
  qr{ <div \s+ class="wp-block-image[^"]*"> \s*
      <figure \s+ class=".*?">
      <a \s* href=".*?">
      <img \s+ (?: (?:loading|width|height) = "[^"]+" \s+ )*
       src="(?<url>https://secureservercdn.net/192.169.220.85/hk8.901.myftpupload.com/wp-content/uploads/
	      \d+/\d+/
	      (?<image>.+?\.\w+))"
    }x;

# Important: Return the package name!
__PACKAGE__;
