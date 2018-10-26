#! perl

use strict;
use warnings;

package Comics::Plugin::ToonHole;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "Toon Hole";
our $url     = "http://www.toonhole.com/";

our $pattern =
  qr{ <div \s+ id="comic"> \s*
      <img \s+
       src="(?<url>http://toonhole.com/wp-content/uploads/
            \d+/\d+/
            (?<image>.+\.\w+))" \s+
            (?:title|alt)="(?<title>.*?)"
    }x;

# Important: Return the package name!
__PACKAGE__;
