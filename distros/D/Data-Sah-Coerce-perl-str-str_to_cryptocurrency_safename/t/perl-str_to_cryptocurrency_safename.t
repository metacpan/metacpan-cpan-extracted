#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type=>"str",
        coerce_rules=>["str_to_cryptocurrency_safename"],
        return_type => "status+err+val",
    );

    is_deeply($c->({}), [undef, undef, {}], "hashref uncoerced");
    is_deeply($c->("Bitcoin"), [1, undef, "bitcoin"]);
    is_deeply($c->("Btc"), [1, undef, "bitcoin"]);
    is_deeply($c->("ethereum classic"), [1, undef, "ethereum-classic"]);
    is_deeply($c->("foo"), [1, "Unknown cryptocurrency code/name/safename: foo", undef]);

};

done_testing;
