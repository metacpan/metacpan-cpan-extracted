#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce qw(gen_coercer);
use Test::More 0.98;
use Test::Needs;

subtest "coerce_to=float(secs)" => sub {
    test_needs 'Time::Duration::Parse::AsHash';

    my $c = gen_coercer(type=>"duration", coerce_to=>"float(secs)");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
    };
    subtest "from float" => sub {
        is($c->(3601), 3601);
    };
    subtest "from DateTime::Duration object" => sub {
        test_needs "DateTime::Duration";
        is($c->(DateTime::Duration->new(hours=>1, seconds=>1, nanoseconds=>800_000_000)), 3601.8);
    };
    subtest "from human string" => sub {
        test_needs "Time::Duration::Parse::AsHash";
        is($c->("1h 1s"), 3601);
    };
    subtest "from iso8601 string" => sub {
        is($c->("PT1H1S"), 3601);
    };
};

subtest "coerce_to=DateTime::Duration" => sub {
    test_needs "DateTime::Duration";
    test_needs 'Time::Duration::Parse::AsHash';

    my $c = gen_coercer(type=>"duration", coerce_to=>"DateTime::Duration");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
    };
    subtest "from float" => sub {
        my $d = $c->(3601.8);
        is(ref($d), "DateTime::Duration");
        # currently we store all in the seconds
        is($d->seconds, 3601.8);
        is($d->nanoseconds, 0);
    };
    subtest "from DateTime::Duration object" => sub {
        my $d0 = DateTime::Duration->new(hours=>1, seconds=>1);
        my $d = $c->($d0);
        is(ref($d), "DateTime::Duration");
        is($d->hours  , 1);
        is($d->minutes, 0);
        is($d->seconds, 1);
    };
    subtest "from human string" => sub {
        test_needs "Time::Duration::Parse::AsHash";
        my $d = $c->("1h 1s");
        is(ref($d), "DateTime::Duration");
        is($d->hours  , 1);
        is($d->minutes, 0);
        is($d->seconds, 1);
    };
    subtest "from iso8601 string" => sub {
        my $d = $c->("PT1H1S");
        is(ref($d), "DateTime::Duration");
        is($d->hours  , 1);
        is($d->minutes, 0);
        is($d->seconds, 1);
    };
};

done_testing;
