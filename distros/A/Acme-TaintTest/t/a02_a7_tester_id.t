#!/usr/bin/perl -T

use lib '.'; use lib 't';
use a02_a7_init; sa_t_init("a02_a7_tester_id");

use Test::More tests => 2;

ok(1, 'got past init');

$workdir = tempdir("$tname.XXXXXX", DIR => "log");
die "FATAL: failed to create workdir: $!" unless -d $workdir;
chmod (0755, $workdir); # sometimes tempdir() ignores umask

ok((-d $workdir), 'tempdir test');
