#! perl

use strict;
use warnings;

package Comics::Plugin::Ben;

use parent qw(Comics::Fetcher::GoComics );

our $VERSION = "1.01";

our $name    = "Ben";
our $url     = "https://www.gocomics.com/ben/";

# Important: Return the package name!
__PACKAGE__;
