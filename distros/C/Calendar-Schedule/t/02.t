#!/usr/bin/perl
use Test::More;
use lib '.';
require "t/test-lib.pl";

my $o = `perl -I. -- ./bin/cal2html --ColLabel='weekday_%w' t/02-calendar`;
is($o, getfile('t/02-calendar.html'), '02.t');

done_testing();
