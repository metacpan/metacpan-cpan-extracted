
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Date::Piece';
use_ok('Date::Piece') or BAIL_OUT("cannot load Date::Piece $@");

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
