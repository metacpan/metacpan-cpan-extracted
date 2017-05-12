package TestInstrument::basic;

use strict;
use warnings FATAL => 'all';

use Apache::Test qw(-withtestmore);

use Apache2::Const -compile => 'OK';

sub handler {
    my $r = shift;

    plan $r, tests => 1;
    use_ok("Apache2::Instrument");

    Apache2::Const::OK;
}

1;
