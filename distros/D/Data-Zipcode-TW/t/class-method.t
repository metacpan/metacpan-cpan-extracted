#!/usr/bin/env perl
use strict;
use warnings;
use Data::Zipcode::TW;
use Test::More;

is(Data::Zipcode::TW->get('瑞穗'),       '978',        "lookup");
is(Data::Zipcode::TW->get('花蓮縣瑞穗'), '978',        "long name lookup");
is(Data::Zipcode::TW->get('302'),        "新竹縣竹北", "reverse lookup");
is(Data::Zipcode::TW->get('沒這個地方'), undef,        "not found");


subtest "ambigious results" => sub {
    is(Data::Zipcode::TW->get('臺北市中正區'),     100);
    is(Data::Zipcode::TW->get('基隆市中正區'),     202);
    done_testing;
};


done_testing;
