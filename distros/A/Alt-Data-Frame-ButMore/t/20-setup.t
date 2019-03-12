#!perl

use strict;
use warnings;

use Test2::V0;

use Data::Frame::Setup;

pass("Data::Frame::Setup successfully loaded");

like(
    dies { Data::Frame::Setup->import(":doesnotexist"); },
    qr/^":doesnotexist" is not exported by the Data::Frame::Setup module/,
    "dies on a wrong import parameter"
);

done_testing;
