#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use CryptoExchange::Catalog;

my $cat = CryptoExchange::Catalog->new;

subtest "by_name" => sub {
    is_deeply($cat->by_name("BX Thailand"), {name=>"BX Thailand", safename=>"bx-thailand"});
    dies_ok { $cat->by_name("bx thailand") };
};

subtest "by_safename" => sub {
    is_deeply($cat->by_safename("bx-thailand"), {name=>"BX Thailand", safename=>"bx-thailand"});
    dies_ok { $cat->by_safename("foo") };
};

subtest "by_slug" => sub {
    is_deeply($cat->by_safename("BX-THAILAND"), {name=>"BX Thailand", safename=>"bx-thailand"});
};

subtest "all_names" => sub {
    my @names = $cat->all_names;
    ok(@names);
};

subtest "all_data" => sub {
    my @all_data = $cat->all_data;
    ok(@all_data);
};

DONE_TESTING:
done_testing;
