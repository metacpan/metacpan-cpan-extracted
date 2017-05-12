#!/usr/bin/env perl -w

use 5.0101;
use Bat::Interpreter;

my $interpreter = Bat::Interpreter->new;

$interpreter->run('basic.cmd');

say join("\n", @{$interpreter->executor->commands_executed});

