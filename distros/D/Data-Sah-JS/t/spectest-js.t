#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Data::Sah::JS qw(run_spectest_for_js);

use Nodejs::Util qw(get_nodejs_path);

my $node_path = get_nodejs_path();
unless ($node_path) {
    plan skip_all => 'node.js is not available';
}

run_spectest_for_js(node_path => $node_path);
done_testing;
