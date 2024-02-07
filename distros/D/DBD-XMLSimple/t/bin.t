#!perl -w

use strict;

use Test::Most tests => 10;
use Test::Script 1.12;

script_compiles('bin/xml');
script_runs(['bin/xml']);

ok(script_stdout_like('Nigel Horne', 'test 1'));
ok(script_stdout_like('njh@concert-bands.co.uk', 'test 2'));
ok(script_stdout_like('"A N Other,Fred Flintsone"', 'test 3'));
ok(script_stderr_is('', 'no error output'));	# Not until driver is registered
