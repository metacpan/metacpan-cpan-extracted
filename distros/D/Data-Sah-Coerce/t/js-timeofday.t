#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::CoerceJS qw(gen_coercer);
use Nodejs::Util qw(get_nodejs_path);

plan skip_all => 'node.js is not available' unless get_nodejs_path();

subtest "coerce_to=float" => sub {
    my $c = gen_coercer(type=>"timeofday");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is($c->(1), 1);
    };
    subtest "from hms string" => sub {
        is($c->("23:59:59"), 86399);
    };
};

done_testing;
