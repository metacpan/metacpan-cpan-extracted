#!/usr/bin/env perl

use strict;

use Test::More;
use IO::String;
use App::jt;

subtest "default behaviour (prettify)" => sub {
    my $in  = q![1,3,5,7,9]!;
    my $out = "";

    App::jt->new(
        input_handle  => IO::String->new($in),
        output_handle => IO::String->new($out)
    )->run;

    is $out,<<OUT;
[
   1,
   3,
   5,
   7,
   9
]
OUT

};

subtest "uglify" => sub {
    my $in  = q![1, 3, 5, 7, 9]!;
    my $out = "";

    App::jt->new(
        input_handle  => IO::String->new($in),
        output_handle => IO::String->new($out),
        ugly => 1
    )->run;

    unlike $out, qr/ /, "no space in this output";
    is $out, qq![1,3,5,7,9]\n!;
};

subtest "silent" => sub {
    my $in  = q!{a:41,"b":42}!;
    my $out = "";

    App::jt->new(
        input_handle  => IO::String->new($in),
        output_handle => IO::String->new($out),
        silent => 1
    )->run;

    is $out, "";
};

done_testing;
