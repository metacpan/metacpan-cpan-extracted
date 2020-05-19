#! perl

use strict;
use warnings;

package Comics::Plugin::Optipess;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Optipess";
our $url     = "https://www.optipess.com";

our $pattern =
  qr{ <div \s+ .*? id="comic"> \s*
      <img \s+
       src="(?<url>https?://www.optipess.com/wp-content/uploads/
	    \d+ / \d+ /
            (?<image>.+?\.\w+))" \s+
       (?:title|alt)="(?<title>.*?)"
    }sx;

# Important: Return the package name!
__PACKAGE__;
