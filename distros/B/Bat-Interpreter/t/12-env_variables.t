#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 1;
use English qw( -no_match_vars );
use Bat::Interpreter;

use Data::Dumper;

my $interpreter = Bat::Interpreter->new;

my $cmd_file = $PROGRAM_NAME;
$cmd_file =~ s/\.t/\.cmd/;

$interpreter->run($cmd_file);

is_deeply( $interpreter->executor->commands_executed,
           [ 'execute_madeup_command.pl --name some_name --date_format %Y%m%d%H%M  --some_parameter="ABC(%)" --substring name --another_date_format "%d/%m/%Y %H:%M" --identifier 3B --environment_variable_with_one_letter some_value'
           ],
);
