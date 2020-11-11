#! perl

use strict;
use warnings;

package Comics::Plugin::ThatsLife;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.01";

our $name    = "That's Life";
our $url     = "http://www.gocomics.com/thats-life/";

our $disabled = 1;		# ceased?

# Important: Return the package name!
__PACKAGE__;
