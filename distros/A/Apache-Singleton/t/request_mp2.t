#!perl
#
# tests for mod_perl2
#

use strict;
use lib qw(t/mock t/lib lib);
use Test::More tests => 4;
use Mock::Apache;
use mod_perl2;  # simulate MP2
use Printer::PerRequest;
use Printer::Device::PerRequest;

my $printer_a = Printer::PerRequest->instance;
my $printer_b = Printer::PerRequest->instance;

my $printer_d1 = Printer::Device::PerRequest->instance;
my $printer_d2 = Printer::Device::PerRequest->instance;

is "$printer_a", "$printer_b", 'same printer';
isnt "$printer_a", "$printer_d1", 'not same printer';
is "$printer_d1", "$printer_d2", 'same printer';

$printer_a->{foo} = 'bar';
is $printer_a->{foo}, $printer_b->{foo}, "attributes shared";
