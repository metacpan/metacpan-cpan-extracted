use strict;
use lib qw(t/mock lib);
use Test::More tests => 2;
use Mock::Apache;

package Printer;
use base qw(Apache::Singleton);

package main;
{
    my $printer_a = Printer->instance;
    my $printer_b = Printer->instance;

    is "$printer_a", "$printer_b", 'same printer';
}

{
    my $printer_a = Printer->instance;
    my $printer_b = Printer->instance;

    is "$printer_a", "$printer_b", 'same printer';
}
