#! perl

use strict;
use warnings;

package Comics::Plugin::Optipess;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Optipess";
our $url     = "http://www.optipess.com";

our $pattern =
  qr{ <div \s+ .*? class="comicpane">
      <img \s+
       src="(?<url>http://www.optipess.com/comics/
            (?<image>.+?\.\w+))" \s+
       (?:title|alt)="(?<title>.*?)"
    }sx;

# Important: Return the package name!
__PACKAGE__;
