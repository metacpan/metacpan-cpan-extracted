use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

use Business::DPD;
my $dpd = Business::DPD->new;

my $label = $dpd->generate_label({
    zip             => '12555',
    country         => 'DE',
    depot           => '1090',
    serial          => '5012345678',
    service_code    => '101',
});

is($label->zip,'12555','zip');

# TODO: test invalid input

