use strict;
use warnings;
use Test::More tests => 1;
use AnyEvent::ConnPool;

my $global_counter = 0;
my $connpool = AnyEvent::ConnPool->new(
    size        =>  5,
    init        =>  1,
    constructor =>  sub {
        return {value => $global_counter++};
    },
);

my $unit = $connpool->get();
my $value = $unit->conn()->{value};
$unit->reconnect();
ok ($unit->conn()->{value} > $value, "Reconnecting");

