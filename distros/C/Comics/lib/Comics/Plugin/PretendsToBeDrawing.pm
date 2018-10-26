#! perl

use strict;
use warnings;

package Comics::Plugin::PretendsToBeDrawing;

#### NOTE: PtbD now uses individual panes for the comic. Hard to do.

our $disabled = 1;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.03";

our $name    = "Pretends To Be Drawing";
our $url     = "http://ptbd.jwels.berlin/";

our $pattern =
  qr{ <div \s+ class="mainpanel" > \s+
      <img \s+
       class="comic\s*" \s+
       alt="(?<alt>.*?)" \s+
       title="(?<title>.*?)" \s+
       itemprop="image" \s+
       src="(?<url>/comicfiles/full/(?<image>.+?\.\w+))"
    }sx;

# Important: Return the package name!
__PACKAGE__;
