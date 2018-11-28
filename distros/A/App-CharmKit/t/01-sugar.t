#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Test::More;
use lib "$FindBin::Bin../lib";


diag('Testing import::into syntax sugar');
use_ok('charm');
ok(sh("uname -a"), 'can run sh uname -a');
file("/tmp/test", ensure => "directory");
ok(path('/tmp/test')->exists, 'directory created');
file("/tmp/test", ensure => "absent");
ok(!path('/tmp/test')->exists, 'directory removed');
can_ok(__PACKAGE__, 'sh');
can_ok(__PACKAGE__, 'plugin');
done_testing();
