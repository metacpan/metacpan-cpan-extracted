use strict;
use warnings;
use Test::More;

use DateTimeX::Factory;

my $instance = DateTimeX::Factory->new(
    time_zone => 'floating',
);
isa_ok($instance => 'DateTimeX::Factory', 'new method returns object');

done_testing;
