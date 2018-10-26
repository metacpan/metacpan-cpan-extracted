#! perl

use strict;
use warnings;

package Comics::Plugin::RudyPark;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.00";

our $name    = "Rudy Park";
our $url     = "http://www.gocomics.com/rudypark/";

# Important: Return the package name!
__PACKAGE__;
