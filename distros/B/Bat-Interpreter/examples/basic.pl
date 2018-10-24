#!/usr/bin/env perl -w

use 5.014;
use Bat::Interpreter;

my $interpreter = Bat::Interpreter->new;

$interpreter->run('basic.cmd');

say join("\n", @{$interpreter->executor->commands_executed});

