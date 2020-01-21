#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

use Config::Registry;

is(
    Config::Registry->merge(
        { a=>1, b=>1, c=>{d=>1,e=>1} },
        { b=>2, c=>{d=>2} },
    ),
    { a=>1, b=>2, c=>{d=>2,e=>1} },
    'merge',
);

done_testing;
