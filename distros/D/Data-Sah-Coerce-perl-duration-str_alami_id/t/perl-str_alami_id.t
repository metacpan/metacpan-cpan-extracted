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

    my $c = gen_coercer(type=>"duration", coerce_to=>"DateTime::Duration", coerce_rules=>["str_alami_id"]);

    # uncoerced
    is_deeply($c->({}), {}, "uncoerced");

    my $d = $c->("2jam, 3mnt");
    is(ref($d), 'DateTime::Duration');
    is($d->hours, 2);
    is($d->minutes, 3);
};

subtest "coerce_to=float(secs)" => sub {
    test_needs "DateTime::Format::Alami::ID";

    my $c = gen_coercer(type=>"duration", coerce_to=>"float(secs)", coerce_rules=>["str_alami_id"]);

    # uncoerced
    is_deeply($c->({}), {}, "uncoerced");

    my $d = $c->("2jam, 3mnt");
    ok(!ref($d));
    is($d, 7380);
};

done_testing;
