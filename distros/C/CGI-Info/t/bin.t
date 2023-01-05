#!perl -w

# This test fails with Test::Sript 1.19_[23], though is fine before then,
# and seems OK with 1.19.4
# See https://github.com/plicease/Test-Script/issues/23

use strict;

use Test::Most tests => 13;
use Test::Script 1.12;

script_compiles('bin/info.pl');
script_runs(['bin/info.pl', 'foo=bar']);

script_stdout_like('Is_mobile: 0', 'not mobile');
script_stdout_like('Is_robot: 0', 'not robot');
script_stdout_like('Is_search_engine: 0', 'not search engine');
script_stdout_like('foo => bar', 'correct args');
script_stderr_is('', 'no error output');

script_runs(['bin/info.pl'], { stdin => \"fred=wilma\n" });

script_stdout_like('Is_mobile: 0', 'not mobile');
script_stdout_like('Is_robot: 0', 'not robot');
script_stdout_like('Is_search_engine: 0', 'not search engine');
script_stdout_like('fred => wilma', 'correct args');
script_stderr_is('', 'no error output');
