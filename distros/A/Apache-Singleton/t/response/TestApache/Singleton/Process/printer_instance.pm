package TestApache::Singleton::Process::printer_instance;

use strict;
use warnings FATAL => 'all';
use constant MP2 => $mod_perl::VERSION >= 1.99;

use Printer::PerProcess;

if (MP2) {
    require Apache2::RequestRec;
    require Apache2::RequestIO;
}

sub handler {
    my $r = shift;

    $r->content_type('text/plain');
    if (!MP2) {
        $r->send_http_header;
    }

    my $printer = Printer::PerProcess->instance;

    $r->write("$printer");

    0;
}

1;
