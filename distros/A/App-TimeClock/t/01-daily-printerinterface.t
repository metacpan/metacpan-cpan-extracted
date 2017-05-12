use warnings;
use strict;

use Test::More tests => 5;
use Time::Local;

use App::TimeClock::Daily::PrinterInterface;

BEGIN {
    use_ok('App::TimeClock::Daily::PrinterInterface');
}

ok(my $interface = App::TimeClock::Daily::PrinterInterface->new());

SKIP: {
    eval { use Test::Exception };
    skip "Test:Exception not installed", 3 if $@;

    # Methods that must be implemented
    dies_ok {$interface->print_header()};
    dies_ok {$interface->print_day()};
    dies_ok {$interface->print_footer()};
}
