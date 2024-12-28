#! perl

use strict;
use warnings;

package Comics::Plugin::MrLovenstein;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Mr. Lovenstein";
our $url     = "https://mrlovenstein.com/";
our $disabled = 1;		# out of reach

our $pattern =
  qr{ <img \s+
       id="comic_main_image" \s+
       src="?(?<url>/images/comics/(?<image>.+\.\w+))"? \s+
    }x;

# Important: Return the package name!
__PACKAGE__;
