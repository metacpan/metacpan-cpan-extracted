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

$ENV{CATALYST_CONFIG} = 't/conf/myapp.yml';

use_ok( 'Catalyst::Test', 'MyApp' );

ok(my(undef, $c) = ctx_request('/'), 'The first request');

# After first request 'A' and 'Ax' modules are loaded (and their dependencies).

# check if Controller A is injected from modules/A/lib/MyApp/Controller/A.pm
ok( request('/a')->is_success, 'Request /a should succeed' );

# check if Controller Bx is injected from modules/Bx/lib/MyApp2/Controller/Bx.pm
ok( request('/bx')->is_success, 'Request /bx should succeed' );

# check if Catalyst plugin 'CatalystX::SimpleLogin' is lodeed from modules/Cx/config.yml
ok( request('/login')->is_success, 'Request /login should succeed' );
