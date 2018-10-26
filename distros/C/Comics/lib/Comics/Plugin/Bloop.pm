#! perl

use strict;
use warnings;

package Comics::Plugin::Bloop;

use parent qw(Comics::Plugin::JHall);

our $VERSION = "1.02";

our $name    = $Comics::Plugin::JHall::name . " Bloop";
our $url     = $Comics::Plugin::JHall::url . "bloop/";

our $pattern = $Comics::Plugin::JHall::pattern;

# Important: Return the package name!
__PACKAGE__;
