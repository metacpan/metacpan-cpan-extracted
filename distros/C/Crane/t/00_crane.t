#!/usr/bin/env perl
# -*- coding: utf-8 -*-


use t::lib::Crane;

use Test::More;


plan('tests' => 5);

subtest('Base' => \&test_base);
subtest('Options' => \&test_options);
subtest('Config' => \&test_config);
subtest('Namespace' => \&test_namespace);
subtest('Daemon' => \&test_daemon);

done_testing();
