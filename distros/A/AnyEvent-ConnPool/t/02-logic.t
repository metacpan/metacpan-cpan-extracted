use strict;
use warnings;
use AnyEvent::ConnPool;
use Test::More;

my $global_counter = 1;
my $connpool = AnyEvent::ConnPool->new(
    constructor     =>  sub {
        return {value => $global_counter++};
    },
    size    =>  10,
);

$connpool->init();
my $last_counter = -1;
for (1 .. 30) {
    my $conn = $connpool->get();
    if ($last_counter > -1) {
        ok($conn->conn()->{value} ne $last_counter, 'Round robin test');
    }
    $last_counter = $conn->conn()->{value};
    $conn->conn();
}

done_testing();

