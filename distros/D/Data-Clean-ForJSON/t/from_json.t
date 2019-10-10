#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Data::Clean::FromJSON;
use DateTime;

my $c = Data::Clean::FromJSON->get_cleanser;

subtest 'JSON::PP::Boolean object' => sub {
    my $cdata = $c->clean_in_place(
        [
            bless(do{\(my $o=1)}, "JSON::PP::Boolean"),
            bless(do{\(my $o=0)}, "JSON::PP::Boolean"),
        ],
    );
    is_deeply($cdata, [
        1,
        0,
    ], "cleaned up") or diag explain $cdata;
};

done_testing;
