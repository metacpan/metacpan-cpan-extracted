#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce qw(gen_coercer);
use Test::More 0.98;
use Test::Needs;

subtest "coerce_to=DateTime::Duration" => sub {
    test_needs "DateTime::Duration";
    test_needs "DateTime::Format::Alami::ID";

    my $c = gen_coercer(
        type=>"duration",
        coerce_to=>"DateTime::Duration",
        coerce_rules=>["str_alami_id"], return_type=>"status+err+val",
    );

    my $res;

    # uncoerced
    $res = $c->({});
    ok(!$res->[0]);
    ok(!$res->[1]);
    is_deeply($res->[2], {});

    # fail
    $res = $c->("foo");
    ok($res->[0]);
    ok($res->[1]);
    is_deeply($res->[2], undef);
};

subtest "coerce_to=float(secs)" => sub {
    test_needs "DateTime::Format::Alami::ID";

    my $c = gen_coercer(type=>"duration", coerce_to=>"float(secs)", coerce_rules=>["str_alami_id"]);

    my $d = $c->("2j, 3mnt");
    ok(!ref($d));
    is($d, 7380);
};

done_testing;
