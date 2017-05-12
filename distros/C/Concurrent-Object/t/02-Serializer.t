#!/usr/bin/perl -s
##
## Concurrent::Object Test Suite
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 02-Serializer.t,v 1.2 2001/06/10 15:04:21 vipul Exp $

use lib '../lib', 'lib';
use Test;
BEGIN { plan tests => 10 };
use Concurrent::Data::Serializer;
use Data::Dumper;

my $serializer = new Concurrent::Data::Serializer;

my $toserialize = { "abc" => 123, 
                    "def" => { "ghi" => 456 },
                    "jki" => "\nsd\nsdf",
                    "fdjs" => "abcd"
                  };

my $dump = $serializer->serialize ($toserialize);
ok($dump);

my $ret = $serializer->deserialize ($dump);

ok($$ret{abc}, 123);
ok($$ret{def}{ghi}, 456);
ok($$ret{jki});
ok($$ret{fdjs},"abcd");

$serializer = new Concurrent::Data::Serializer Method => 'Dumper';

$dump = $serializer->serialize ($toserialize);
ok($dump);

$ret = $serializer->deserialize ($dump);

ok($$ret{abc}, 123);
ok($$ret{def}{ghi}, 456);
ok($$ret{jki});
ok($$ret{fdjs},"abcd");

