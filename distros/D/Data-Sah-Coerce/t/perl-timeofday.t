#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::Coerce qw(gen_coercer);

subtest "coerce_to=float" => sub {
    my $c = gen_coercer(type=>"timeofday", coerce_to=>"float");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is($c->(1), 1);
    };

    subtest "from hms string" => sub {
        is_deeply($c->("23:59:59"), 86399);
        is_deeply($c->("23:59:59.025"), 86399.025);
        is_deeply($c->("24:00:00"), undef); # invalid
    };

    subtest "from Date::TimeOfDay obect" => sub {
        test_needs "Date::TimeOfDay";
        my $tod = Date::TimeOfDay->new(hour=>23, minute=>59, second=>59);
        is_deeply($c->($tod), 86399);
    };
};

subtest "coerce_to=str_hms" => sub {
    my $c = gen_coercer(type=>"timeofday", coerce_to=>"str_hms");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is($c->(1), 1);
    };

    subtest "from hms string" => sub {
        is_deeply($c->("23:59:59"), "23:59:59");
        is_deeply($c->("23:59:59.025"), "23:59:59.025");
        is_deeply($c->("24:00:00"), undef); # invalid
    };

    subtest "from Date::TimeOfDay obect" => sub {
        test_needs "Date::TimeOfDay";
        my $tod = Date::TimeOfDay->new(hour=>23, minute=>59, second=>59);
        is_deeply($c->($tod), "23:59:59");
    };
};

subtest "coerce_to=Date::TimeOfDay" => sub {
    test_needs "Date::TimeOfDay";

    my $c = gen_coercer(type=>"timeofday", coerce_to=>"Date::TimeOfDay");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is($c->(1), 1);
    };

    subtest "from hms string" => sub {
        my $d = $c->("23:59:59");
        is(ref $d, "Date::TimeOfDay");
        is($d->hms, "23:59:59");

        #like($c->("24:00:00"), "24:00:00"); # invalid
    };

    subtest "from Date::TimeOfDay obect" => sub {
        test_needs "Date::TimeOfDay";
        my $tod = Date::TimeOfDay->new(hour=>23, minute=>59, second=>59);
        my $d = $c->($tod);

        is(ref $d, "Date::TimeOfDay");
        is($d->hms, "23:59:59");
    };
};

done_testing;
