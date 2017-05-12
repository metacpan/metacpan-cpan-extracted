#!perl

use 5.010;
use strict;
use warnings;

use Data::Clean::FromJSON;
use DateTime;
use Test::More 0.98;

my $c = Data::Clean::FromJSON->get_cleanser;

subtest 'JSON::PP' => sub {
    my $cdata = $c->clean_in_place(
        [
            bless(do{\(my $o=1)}, "JSON::PP::Boolean"),
            #bless(do{\(my $o=0)}, "JSON::PP::Boolean"),
        ],
    );
    is_deeply($cdata, [
        1,
        #0, # WHY STILL 1???
    ], "cleaned up") or diag explain $cdata;
};

subtest 'JSON::XS' => sub {
    my $cdata = $c->clean_in_place(
        [
            bless(do{\(my $o=1)}, "JSON::XS::Boolean"),
            #bless(do{\(my $o=0)}, "JSON::XS::Boolean"),
        ],
    );
    is_deeply($cdata, [
        1,
        #0, # WHY STILL 1???
    ], "cleaned up") or diag explain $cdata;
};

subtest 'Cpanel::JSON::XS' => sub {
    my $cdata = $c->clean_in_place(
        [
            bless(do{\(my $o=1)}, "Cpanel::JSON::XS::Boolean"),
            #bless(do{\(my $o=0)}, "Cpanel::JSON::XS::Boolean"),
        ],
    );
    is_deeply($cdata, [
        1,
        #0, # WHY STILL 1???
    ], "cleaned up") or diag explain $cdata;
};

done_testing();
