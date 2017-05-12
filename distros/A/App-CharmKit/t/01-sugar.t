#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Test::More;
use lib "$FindBin::Bin../lib";


diag('Testing import::into syntax sugar');
use_ok('charm');
ok(run("uname -a"));
file("/tmp/test", ensure => "directory");
ok(path('/tmp/test')->exists, 'directory created');
file("/tmp/test", ensure => "absent");
ok(!path('/tmp/test')->exists, 'directory removed');
done_testing();
