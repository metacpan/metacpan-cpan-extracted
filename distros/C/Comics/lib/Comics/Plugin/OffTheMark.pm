#! perl

use strict;
use warnings;

package Comics::Plugin::OffTheMark;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.02";

our $name    = "Off the mark";
our $url     = "https://www.gocomics.com/offthemark";

# Important: Return the package name!
__PACKAGE__;
