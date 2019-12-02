#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::CoerceJS qw(gen_coercer);
use Nodejs::Util qw(get_nodejs_path);
use Test::More 0.98;

plan skip_all => "node.js not available" unless get_nodejs_path();

subtest "coerce_to=float(secs)" => sub {
    my $c = gen_coercer(type=>"duration");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
    };
    subtest "from float" => sub {
        is($c->(3601), 3601);
    };
    # XXX from Date object
    subtest "from iso8601 string" => sub {
        is($c->("PT1H1S"), 3601);
    };
};

done_testing;
