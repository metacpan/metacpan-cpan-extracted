#! perl

use strict;
use warnings;

package Comics::Plugin::WorkingDaze;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.02";

our $name    = "Working Daze";
our $url     = "https://www.gocomics.com/working-daze";

# Important: Return the package name!
__PACKAGE__;
