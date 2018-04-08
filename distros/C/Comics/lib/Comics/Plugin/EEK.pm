#! perl

use strict;
use warnings;

package Comics::Plugin::EEK;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.02";

our $name    = "EEK!";
our $url     = "http://www.gocomics.com/eek/";

# Important: Return the package name!
__PACKAGE__;
