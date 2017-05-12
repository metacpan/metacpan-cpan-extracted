package TestApache::Singleton::request;

use strict;
use warnings FATAL => 'all';
use constant MP2 => $mod_perl::VERSION >= 1.99;

use Apache::Singleton::Request;
use Printer::PerRequest;
use Printer::Device::PerRequest;

if (MP2) {
    require Apache2::RequestRec;
    require Apache2::RequestIO;
}

no strict 'refs';

use Test::More;
use Apache::Test '-withtestmore';

sub handler {
    my $r = shift;

    plan $r, tests => 4;

    my $printer_a = Printer::PerRequest->instance;
    my $printer_b = Printer::PerRequest->instance;

    my $printer_d1 = Printer::Device::PerRequest->instance;
    my $printer_d2 = Printer::Device::PerRequest->instance;

    is   "$printer_a",  "$printer_b",  'same printer';
    isnt "$printer_a",  "$printer_d2", 'not same printer';
    is   "$printer_d1", "$printer_d2", 'same printer device';

    $printer_a->{foo} = 'bar';
    is $printer_a->{foo}, $printer_b->{foo}, 'attributes are shared';

    0;
}

1;
