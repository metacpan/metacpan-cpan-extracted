#! perl

use strict;
use warnings;

package Comics::Plugin::9ChickweedLane;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.02";

our $name    = "9 Chickweed Lane";
our $url     = "https://www.gocomics.com/9-chickweed-lane";

# Important: Return the package name!
__PACKAGE__;
