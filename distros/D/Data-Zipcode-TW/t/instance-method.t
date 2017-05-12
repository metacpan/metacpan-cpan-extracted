#!/usr/bin/env perl
use strict;
use warnings;
use Data::Zipcode::TW;
use Test::More;

my $o = Data::Zipcode::TW->new;

is($o->get('瑞穗'),       '978',        "lookup");
is($o->get('花蓮縣瑞穗'), '978',        "long name lookup");
is($o->get('302'),        "新竹縣竹北", "reverse lookup");
is($o->get('沒這個地方'), undef,        "not found");


subtest "ambigious results" => sub {
    is($o->get('臺北市中正區'),     100);
    is($o->get('基隆市中正區'),     202);
    done_testing;
};


done_testing;
