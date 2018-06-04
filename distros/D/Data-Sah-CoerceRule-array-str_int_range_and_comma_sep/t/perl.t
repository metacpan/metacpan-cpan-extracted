#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "coerce_to=array" => sub {
    my $c = gen_coercer(
        type=>"array",
        coerce_rules=>["str_int_range_and_comma_sep"],
        return_type => "status+err+val",
    );

    is_deeply($c->({}), [undef, undef, {}], "uncoerced");
    is_deeply($c->([[]]), [undef, undef, [[]]], "uncoerced");

    is_deeply($c->("a"), [1, "Invalid elem 'a': must be INT or INT1-INT2", undef]);

    is_deeply($c->("1"), [1, undef, [1]]);

    is_deeply($c->("1,3,2"), [1, undef, [1,3,2]]);
    is_deeply($c->("1, 3, -2"), [1, undef, [1,3,-2]]);

    is_deeply($c->("1-10"), [1, undef, [1..10]]);
    is_deeply($c->("1..10"), [1, undef, [1..10]]);
    is_deeply($c->("10-1"), [1, undef, []]);
    is_deeply($c->("10..1"), [1, undef, []]);
    is_deeply($c->("-3-3"), [1, undef, [-3..3]]);
    is_deeply($c->("-3..3"), [1, undef, [-3..3]]);
    is_deeply($c->("-3 - -1"), [1, undef, [-3..-1]]);
    is_deeply($c->("-3 .. -1"), [1, undef, [-3..-1]]);

    is_deeply($c->("1,2-5,7"), [1, undef, [1,2,3,4,5,7]]);
};

done_testing;
