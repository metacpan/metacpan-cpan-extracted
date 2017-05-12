
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Combust::Spontaneously';
use_ok('Combust::Spontaneously') or BAIL_OUT('cannot load Combust::Spontaneously');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
