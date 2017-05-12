use strict;
use lib qw(t/mock t/lib lib);
use Test::More tests => 4;
use Mock::Apache;
use mod_perl;
use Printer::PerProcess;
use Printer::Device::PerProcess;

my $printer_a = Printer::PerProcess->instance;
my $printer_b = Printer::PerProcess->instance;

my $printer_d1 = Printer::Device::PerProcess->instance;
my $printer_d2 = Printer::Device::PerProcess->instance;

is "$printer_a", "$printer_b", 'same printer';
isnt "$printer_a", "$printer_d1", 'not same printer';
is "$printer_d1", "$printer_d2", 'same printer';

$printer_a->{foo} = 'bar';
is $printer_a->{foo}, $printer_b->{foo}, "attributes shared";



