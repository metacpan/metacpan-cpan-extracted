#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>4;

use_ok('Conductrics::Agent');

my $agent = Conductrics::Agent->new(apiKey=>'yourApiKey', ownerCode=>'yourOwnerCode', baseUrl=>'http://api.conductrics.com/', name=>"yourAgentName");

ok($agent, "Agent created");
isa_ok($agent, 'Conductrics::Agent');
can_ok($agent, qw/decide reward expire/);


exit;
