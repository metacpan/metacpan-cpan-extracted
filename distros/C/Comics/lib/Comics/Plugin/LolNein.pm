#! perl

use strict;
use warnings;

package Comics::Plugin::LolNein;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "LolNein";
our $url     = "http://lolnein.com";

our @patterns =
  ( qr{ Last \s+ comic: \s+ <a \s+ href="(?<url>.*?)">
      }sx,
    qr{ <img \s+ property="og:image" \s+ class="center" \s+
         src="(?<url>/comics/
               (?<image>.+?\.\w+))" \s+
         (?:title|alt)="(?<title>.*?)"
      }sx,
  );

# Important: Return the package name!
__PACKAGE__;
