#!/usr/bin/env perl

use Modern::Perl;

use Test2::V0;

use Data::JavaScript;

ok length $Data::JavaScript::VERSION > 0, 'Module loads';

done_testing;
