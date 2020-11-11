#! perl

use strict;
use warnings;

package Comics::Plugin::LolNein_Bonus;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "LolNein";
our $url     = "http://lolnein.com";

our @patterns =
  ( qr{ Last \s+ comic: \s+ <a \s+ href="(?<url>.*?)">
      }sx,
    qr{ <img \s+
         src="(?<url>/images/
               (?<image>.+?_bonus\.\w+))" \s+
         (?:title|alt)="(?<title>.*?Bonus.*?)"
      }sx,
  );

our $disabled = 1;		# movies now

# Important: Return the package name!
__PACKAGE__;
