#!perl -w

use strict;

use Test::Most tests => 23;
use Test::Script;

script_compiles('bin/info.pl');
script_runs(['bin/info.pl', 'foo=bar']);

ok(script_stdout_like('Is_mobile: 0', 'not mobile'));
ok(script_stdout_like('Is_robot: 0', 'not robot'));
ok(script_stdout_like('Is_search_engine: 0', 'not search engine'));
ok(script_stdout_like('foo => bar', 'correct args'));
ok(script_stderr_is('', 'no error output'));

script_runs(['bin/info.pl'], { stdin => \"fred=wilma\n" });

ok(script_stdout_like('Is_mobile: 0', 'not mobile'));
ok(script_stdout_like('Is_robot: 0', 'not robot'));
ok(script_stdout_like('Is_search_engine: 0', 'not search engine'));
ok(script_stdout_like('fred => wilma', 'correct args'));
ok(script_stderr_is('', 'no error output'));
