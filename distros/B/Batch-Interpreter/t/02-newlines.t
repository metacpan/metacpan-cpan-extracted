#! /usr/bin/perl

use v5.10;
use warnings;
use strict;

use Test::More tests => 9;
use Test::Differences;

use Batch::Interpreter::TestSupport qw(read_file);

eq_or_diff read_file('t/lf.txt'), "a\nb\n", 'lf';
eq_or_diff read_file('t/cr.txt'), "a\rb\r", 'cr';
eq_or_diff read_file('t/crlf.txt'), "a\r\nb\r\n", 'crlf';

isnt read_file('t/lf.txt'), "a\rb\r", 'lf ne cr';
isnt read_file('t/lf.txt'), "a\r\nb\r\n", 'lf ne crlf';
isnt read_file('t/cr.txt'), "a\nb\n", 'cr ne lf';
isnt read_file('t/cr.txt'), "a\r\nb\r\n", 'cr ne crlf';
isnt read_file('t/crlf.txt'), "a\nb\n", 'crlf ne lf';
isnt read_file('t/crlf.txt'), "a\rb\r", 'crlf ne cr';
