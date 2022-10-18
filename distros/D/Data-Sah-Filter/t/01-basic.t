#!perl

use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Filter qw(gen_filter);

subtest "sanity tests" => sub {
    subtest "single" => sub {

        subtest "might_fail=0" => sub {
            subtest "return_type=val" => sub {
                my $f = gen_filter(
                    filter_names => [ 'Str::remove_whitespace' ],
                );
                is($f->(" foo "), "foo");
            };
            subtest "return_type=str_errmsg+val" => sub {
                my $f = gen_filter(
                    filter_names => [ 'Str::remove_whitespace' ],
                    return_type => "str_errmsg+val",
                );
                is_deeply($f->(" foo "), [undef, "foo"]);
            };
        };

        subtest "might_fail=1" => sub {
            subtest "return_type=val" => sub {
                my $f = gen_filter(
                    filter_names => [ ['Str::try_center'=>{width=>5}] ],
                );
                is_deeply($f->("foo"), " foo ");
                is_deeply($f->("foob"), "foob ");
                is_deeply($f->("fooba"), "fooba");
                is_deeply($f->("foobar"), undef);
            };
            subtest "return_type=str_errmsg+val" => sub {
                my $f = gen_filter(
                    filter_names => [ ['Str::try_center'=>{width=>5}] ],
                    return_type => "str_errmsg+val",
                );
                is_deeply($f->("foo"), [undef, " foo "]);
                is_deeply($f->("foob"), [undef, "foob "]);
                is_deeply($f->("fooba"), [undef, "fooba"]);
                is_deeply($f->("foobar"), ["String is too wide for width", "foobar"]);
            };
        };

    };

    subtest "multiple" => sub {

        subtest "return_type=val" => sub {
            my $f = gen_filter(
                filter_names => [ 'Str::remove_whitespace', ['Str::try_center'=>{width=>5}] ],
            );
            is($f->(" f o o "), " foo ");
            is($f->(" f o o b a r "), undef);
        };
        subtest "return_type=str_errmsg+val" => sub {
            my $f = gen_filter(
                filter_names => [ 'Str::remove_whitespace', ['Str::try_center'=>{width=>5}] ],
                return_type => 'str_errmsg+val',
            );
            is_deeply($f->(" f o o "), [undef, " foo "]);
            is_deeply($f->(" f o o b a r "), ["String is too wide for width", "foobar"]);
        };

    };
};

done_testing;
