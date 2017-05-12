#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use lib "t/lib";

# Dependencies between modules
# (see all config.yml in paths defined in myapp.yml)
#
#          A
#         / \
#        v   v
#        D   B
#        ^  /\
#         \v  v
#          C->E

$ENV{CATALYST_CONFIG} = 't/conf/mergeconfig.yml';

use_ok( 'Catalyst::Test', 'MyApp' );

ok(my(undef, $c) = ctx_request('/'), 'The first request');

is( $c->config->{TestHash}->{A}->{B}, 1, "config is merged");
