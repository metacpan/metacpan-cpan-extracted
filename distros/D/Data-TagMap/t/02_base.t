#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 3;

use_ok('Data::TagMap');

my $map = Data::TagMap->new;
isa_ok($map, 'Data::TagMap');

$map->add_one(1 => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31');

is($map->get(sid => 1), 2, 'add and get');

exit 0;
