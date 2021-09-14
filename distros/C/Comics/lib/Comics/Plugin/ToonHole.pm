#! perl

use strict;
use warnings;

package Comics::Plugin::ToonHole;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.02";

our $name    = "Toon Hole";
our $url     = "https://www.toonhole.com/";

our $pattern =
  qr{ <noscript>
      <img \s+
       width="\d+" \s+
       height="\d+" \s+
       src="(?<url>https://toonhole.com/wp-content/uploads/
            \d+/\d+/
            (?<image>\d\d\d_.+\.\w+))" \s+
    }x;

# Important: Return the package name!
__PACKAGE__;
