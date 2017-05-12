#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use Catalyst::Test 'TestApp';

is(TestApp->config->{name}, 'CatalystX::Declare TestApp', 'config setting via $CLASS');
is(TestApp->ctx_method(23), 23, 'calling context method');
is(TestApp->cx_declare_test_plugin_method, 'plugin', 'plugin is available');

done_testing;
