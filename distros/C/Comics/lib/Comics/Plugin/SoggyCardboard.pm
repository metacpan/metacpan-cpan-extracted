#! perl

use strict;
use warnings;

package Comics::Plugin::SoggyCardboard;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.00";

our $name    = "SoggyCardboard";
our $url     = "http://www.soggycardboard.com/";

our $pattern =
  qr{ <div \s+ class="comic-table"> \s*
      <div \s+ id="comic"> \s*
      <img \s+
       src="(?<url>https?://www.soggycardboard.com/wp-content/uploads/
                   \d+/\d+/(?<image>.+\.\w+))" \s+
                    alt="(?<alt>.+?)"
    }x;

# Important: Return the package name!
__PACKAGE__;
