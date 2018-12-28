#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 3;

use ARGV::OrDATA;

while (<>) {
    is $_, "pipe $.\n", "read line $. from stdin";
}
ok eof *STDIN, 'end of stdin';

__DATA__
data 1
data 2

