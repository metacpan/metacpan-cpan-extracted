#! perl

use strict;
use warnings;

package Comics::Plugin::PearlsBeforeSwine;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.00";

our $name    = "Pearls Before Swine";
our $url     = "https://www.gocomics.com/pearlsbeforeswine";

# Important: Return the package name!
__PACKAGE__;
