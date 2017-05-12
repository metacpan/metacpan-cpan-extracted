#!/usr/bin/env perl

use strict;

use Test::More;
use IO::String;
use App::jt;

subtest "csv" => sub {
    my $in  = <<'IN';
[
  { "a" : 41,  "b" : 42 },
  { "a" : 43,  "b" : 44 }
]
IN
    my $out = "";

    App::jt->new(
        input_handle  => IO::String->new($in),
        output_handle => IO::String->new($out),
        csv => 1
    )->run;

    my $out1 = <<CSV;
a,b
41,42
43,44
CSV

    my $out2 = <<CSV;
b,a
42,41
44,43
CSV

    ok( ($out eq $out1) || ($out eq $out2) );
};

subtest "tsv" => sub {
    my $in  = <<'IN';
[
  { "a" : 41,  "b" : 42 },
  { "a" : 43,  "b" : 44 }
]
IN
    my $out = "";

    App::jt->new(
        input_handle  => IO::String->new($in),
        output_handle => IO::String->new($out),
        tsv => 1
    )->run;

    my $r = $out eq <<CSV;
b	a
42	41
44	43
CSV

    $r ||= $out eq <<CSV;
a	b
41	42
43	44
CSV

    ok $r
};

done_testing;
