use strict;
use lib qw(t/mock lib);
use Test::More tests => 3;

use Mock::Apache;

package Printer;
use base qw(Apache::Singleton);

package Printer::Device;
use base qw(Apache::Singleton);

package main;
my $printer_a = Printer->instance;
my $printer_b = Printer->instance;

my $printer_d1 = Printer::Device->instance;
my $printer_d2 = Printer::Device->instance;

is "$printer_a", "$printer_b", 'same printer';
isnt "$printer_a", "$printer_d1", 'not same printer';
is "$printer_d1", "$printer_d2", 'same printer';




