#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 1;
use English qw( -no_match_vars );
use Bat::Interpreter;

my $interpreter = Bat::Interpreter->new;

my $cmd_file = $PROGRAM_NAME;
$cmd_file =~ s/\.t/\.cmd/;

$interpreter->run($cmd_file);

is_deeply( [ 'cp 14-if_exists.cmd 14-if_exists.cmd.bkp', 'touch another_file' ],
           $interpreter->executor->commands_executed );
