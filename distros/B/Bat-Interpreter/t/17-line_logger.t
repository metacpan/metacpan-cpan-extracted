#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 1;
use English qw( -no_match_vars );
use Bat::Interpreter;
use Bat::Interpreter::Delegate::LineLogger::SilentSaveLines;

my $silent_line_logger = Bat::Interpreter::Delegate::LineLogger::SilentSaveLines->new;

my $interpreter = Bat::Interpreter->new( linelogger => $silent_line_logger );

my $cmd_file = $PROGRAM_NAME;
$cmd_file =~ s/\.t/\.cmd/;

$interpreter->run($cmd_file);

my $expected_lines = [
                   'ECHO off',
                   '::  Comment1',
                   'ECHO Testing line logger',
                   ':: Comment2',
                   'CALL t/10-call_command_subcall.cmd',
                   'ECHO off',
                   'cp file1 file2',
                   'SET VALUE=6',
                   'SET GOTOLABEL=NO',
                   'SET VALUE=123456',
                   'ECHO 56',
                   'SET VALUEFORKEY=something',
                   "FOR %%m in (1,3,6) do \n\tIF 1 GEQ 123456 \n\tIF 3 GEQ 123456 \n\tIF 6 GEQ 123456 ",
                   'FOR /F "delims="J in \'perl -E "my %hash=qw/key something/; print @hash{key};"\' SET KEY=something',
                   'IF NO EQU YES ',
                   'dir',
                   ':anotherlabel',
                   'GOTO anotherone',
                   ':anotherone',
                   'IF 130 GTR 14 GOTO label',
                   ':label',
                   'cp file1 file2'
];

use Data::Dumper;
print Dumper( $silent_line_logger->lines );
is_deeply( $silent_line_logger->lines, $expected_lines );

