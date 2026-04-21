#!/usr/bin/env perl
# ABSTRACT: Basic load test

use strict;
use warnings;
use Test2::Bundle::More;

ok(eval { require App::Raider; 1 },            'load App::Raider')            or diag $@;
ok(eval { require App::Raider::FileTools; 1 }, 'load App::Raider::FileTools') or diag $@;

can_ok('App::Raider', qw( new run raid_f raider ));

my $server = App::Raider::FileTools::build_file_tools_server();
isa_ok($server, 'MCP::Server');

done_testing;
