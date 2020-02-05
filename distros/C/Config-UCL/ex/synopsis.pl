#!/usr/local/bin/perl

use rlib qw(../lib ../blib/lib ../blib/arch);
use feature ":5.10";
use Config::UCL;
use JSON::PP qw(encode_json);

my $hash = ucl_load("key1 : val1");
say encode_json $hash;

my $text = ucl_dump($hash);
say $text;

my $data1  = { foo => 1 };
my $data2  = { bar => 1 };
my $schema = {
    properties => {
        foo => {},
        bar => {},
    },
    required => [qw(foo)],
};
say ucl_validate($schema, $data1); # 1
say ucl_schema_error();            #
say ucl_validate($schema, $data2); #
say ucl_schema_error();            # object has missing property foo
