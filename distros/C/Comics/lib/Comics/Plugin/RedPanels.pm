#! perl

use strict;
use warnings;

package Comics::Plugin::RedPanels;

use parent qw(Comics::Fetcher::Single);

our $VERSION = "1.01";

our $name    = "Red Panels";
our $url     = "http://www.redpanels.com/";

our $pattern =
  qr{ <img \s+
       (?: id='comicImg' \s+ )?
       src='(?<url>http://redpanels.com/comics/(?<image>.*?\.\w+))' \s+
       alt='(?<alt>.*?)' \s*
      >
    }six;

# Important: Return the package name!
__PACKAGE__;
