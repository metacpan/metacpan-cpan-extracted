#! perl

use strict;
use warnings;

package Comics::Plugin::JHall;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "JHall";
our $url     = "https://jhallcomics.com/";

our $pattern =
  qr{ <div \s+ .*? class="image-block-wrapper \s+ .*? > \s*
      <noscript>
      <img \s+
       src="(?<url>https?://static1.squarespace.com/static/
                   .*?/t/.*?/.*?/
		   (?<image>.+?\.\w+))"
    }sx;

# Important: Return the package name!
__PACKAGE__;
