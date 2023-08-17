#! perl

use strict;
use warnings;

package Comics::Plugin::CalvinAndHobbes;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.00";

our $name = "Calvin and Hobbes";
our $url  = "https://www.gocomics.com/calvinandhobbes";

# Important: Return the package name!
__PACKAGE__;
