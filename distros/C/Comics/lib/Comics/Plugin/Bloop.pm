#! perl

use strict;
use warnings;

package Comics::Plugin::Bloop;

use parent qw(Comics::Plugin::JHall);

our $disabled = 1;		# disfunct

our $VERSION = "1.03";

our $name    = $Comics::Plugin::JHall::name . " Bloop";
our $url     = $Comics::Plugin::JHall::url . "bloop/";

our $pattern = $Comics::Plugin::JHall::pattern;

# Important: Return the package name!
__PACKAGE__;
