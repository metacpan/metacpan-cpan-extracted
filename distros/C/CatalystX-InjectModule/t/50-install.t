#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use lib "t/lib";

$ENV{CATALYST_CONFIG} = 't/conf/install.yml';

use_ok( 'Catalyst::Test', 'MyApp' );

ok(my(undef, $c) = ctx_request('/'), 'get catalyst context');

my $module_Install = $c->mi->get_module('Install');

is($module_Install->{installed}, 1, 'module Install is installed');

is( -e $c->mi->_persist_file_name($module_Install), 1, 'persistent file exist');

ok($c->mi->uninstall_module($module_Install), 'UnInstall module Install');

is( ! -e $c->mi->_persist_file_name($module_Install), 1, 'persistent file is deleted');

is($module_Install->{installed}, 0, 'module Install is uninstalled');

unlink 't/share/myapp-schema.db';
