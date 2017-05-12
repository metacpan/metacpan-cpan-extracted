use strict;
use warnings;
use Test::More;
use AnyEvent::ConnPool;

my $acc = 0;
my $global_counter = 0;

my $connpool = AnyEvent::ConnPool->new(
    constructor     =>  sub {
        return {value => $global_counter++};
    },
    size    =>  5,
    init    =>  1,
);



my $c1 = $connpool->get(1);
my $c2 = $connpool->get(0);
my $c3 = $connpool->get(4);

$c1->lock();
$c2->lock();
$c3->lock();
for (1 .. 30) {
    my $c = $connpool->get();
    my $val = $c->conn()->{value};
    $acc += $val;
    
}

ok ($acc == 75, 'Transactional balancing is ok');
done_testing();

