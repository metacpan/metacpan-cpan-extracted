#!/usr/bin/env perl
#

use strict;
use lib qw(t/mock lib);
use Test::More;
use Mock::Apache;

package Printer;
use base qw(Apache::Singleton);

package main;

my $printer_a = Printer->instance(foo => 'bar');
my $printer_b = Printer->instance;

isa_ok $printer_a, 'Printer';
isa_ok $printer_b, 'Printer';

# both should have foo => bar
is $printer_a->{foo}, 'bar';
is $printer_b->{foo}, 'bar';

done_testing;
