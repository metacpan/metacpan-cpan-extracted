#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';

my $file = 't/conf/file1.yml';

use_ok('Config::From::Backend::File');

ok( my $backend = Config::From::Backend::File->new( file => $file ),
    'new backend File');

is($backend->file, $file, "backend file : $file");

isa_ok($backend->datas, 'HASH', 'backend');
