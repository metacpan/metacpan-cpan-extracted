#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use lib "t/lib";

$ENV{CATALYST_CONFIG} = 't/conf/install_fixtures.yml';

use_ok( 'Catalyst::Test', 'MyApp' );

ok(my(undef, $c) = ctx_request('/'), 'get catalyst context');

my $module_Fixture = $c->mi->get_module('Fixture');

is( -e $c->mi->_persist_file_name($module_Fixture), 1, 'persistent file exist');

my $schema = $c->model->schema;

is( $schema->resultset('User')->search, 2, 'install_fixture work, there are 2 users');
is( $schema->resultset('Role')->search, 2, '... and 2 roles');

ok($c->mi->uninstall_module($module_Fixture), 'UnInstall module Fixture');

is( $schema->resultset('User')->search, 0, 'uninstall work, there is no user');
is( $schema->resultset('Role')->search, 0, '... and no role');

is( ! -e $c->mi->_persist_file_name($module_Fixture), 1, 'persistent file is deleted');
