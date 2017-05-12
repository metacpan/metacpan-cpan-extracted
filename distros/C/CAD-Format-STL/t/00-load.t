
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'CAD::Format::STL';
use_ok('CAD::Format::STL') or BAIL_OUT('cannot load CAD::Format::STL');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
