#! perl

use strict;
use warnings;

package Comics::Plugin::GirlsWithSlingshots;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.02";

our $name    = "Girls With Slingshots";
our $url     = "https://girlswithslingshots.com/";

our $pattern =
  qr{ <div \s+ id="cc-comicbody" > \s*
      <img \s+
       title="(?<title>.*?)" \s+
       src="(?<url>(?:https?:)//girlswithslingshots.com/comics/(?<image>.+\.\w+))" \s+
    }x;

# Important: Return the package name!
__PACKAGE__;
