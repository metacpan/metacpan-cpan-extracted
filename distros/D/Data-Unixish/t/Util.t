#!/perl

use 5.010;
use strict;
use warnings;

use Data::Unixish::Util qw(filter_args);
use Test::More 0.98;

is_deeply(filter_args({a=>1, -b=>2, -cmdline=>3, d=>4}), {a=>1, d=>4});

done_testing;
