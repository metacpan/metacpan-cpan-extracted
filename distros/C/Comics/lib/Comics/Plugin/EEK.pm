#! perl

use strict;
use warnings;

package Comics::Plugin::EEK;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.03";

our $name    = "EEK!";
our $url     = "https://www.gocomics.com/eek";

# Important: Return the package name!
__PACKAGE__;
