#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::Coerce qw(gen_coercer);

# some tests are "covered" by perl-date.t

subtest "coerce_to=float(epoch)" => sub {
    my $c = gen_coercer(type=>"datetime", coerce_to=>"float(epoch)");

    subtest "from iso8601 string" => sub {
        test_needs "Time::Local";
        like($c->("2016-01-01T00:00:00Z"), qr/\A\d+\z/); # coerced
        is($c->("2016-01-01"), "2016-01-01"); # uncoerced
        # test date before epoch 0
        is($c->("1968-01-01T00:00:00Z"), -63158400);
    };
};

subtest "coerce_to=DateTime" => sub {
    test_needs "DateTime";

    my $c = gen_coercer(type=>"datetime", coerce_to=>"DateTime");
    my $d;

    # test date before epoch 0
    $d = $c->("1938-02-14T01:02:03Z");
    is(ref($d), "DateTime");
    is($d->ymd, "1938-02-14");
    is($d->hms, "01:02:03");
};

subtest "coerce_to=Time::Moment" => sub {
    test_needs "Time::Moment";

    my $c = gen_coercer(type=>"datetime", coerce_to=>"Time::Moment");
    my $d;

    # test date before epoch 0
    $d = $c->("1938-02-14T01:02:03Z");
    is(ref($d), "Time::Moment");
    is($d->strftime("%Y-%m-%d %H:%M:%S"), "1938-02-14 01:02:03");
};

done_testing;
