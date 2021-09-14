#! perl

use strict;
use warnings;

package Comics::Plugin::Speedbump;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.02";

our $name    = "Speedbump";
our $url     = "https://www.speedbump.com/";

our $pattern =
  qr{ <h1 \s+ class="logo" >
      <a \s+ href="/" >
      <img \s+
       src="?
           (?<url>//images.squarespace-cdn.com/content/v1/
            .*?/.*?/(?<image>.*?)\?format=\d+w)
           "?
    }x;

# Important: Return the package name!
__PACKAGE__;
