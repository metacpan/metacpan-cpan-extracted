#! perl

use strict;
use warnings;

package Comics::Plugin::OverTheHedge;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.02";

our $name    = "Over the hedge";
our $url     = "https://www.gocomics.com/overthehedge";

# Important: Return the package name!
__PACKAGE__;
