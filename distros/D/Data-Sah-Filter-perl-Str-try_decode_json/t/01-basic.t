#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Filter qw(gen_filter);

subtest "basics" => sub {
    my $c = gen_filter(filter_names=>["Str::try_decode_json"], return_type=>"val");
    my $res;

    # unfiltered
    is_deeply($c->(undef), undef);

    # unquoted becomes as-is
    is_deeply($c->("foo"), "foo");

    # misquoted becomes as-is
    is_deeply($c->("[1,"), q([1,));

    # quoted string becomes string
    is_deeply($c->(q["foo"]), "foo");

    # quoted array becomes array
    is_deeply($c->('[1,2]'), [1,2]);

    # bare null keyword becomes undef
    is_deeply($c->('null'), undef);
};

done_testing;
