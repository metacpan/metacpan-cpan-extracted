use strict; use warnings;
use Test::More;
use Acme::Fork::Lazy ':all';

# SCALAR CALC
my $foo = forked { 2+3 };
is ($foo, 5, 'Simple deferred calculation');

PARALLEL: {
    my @list = map forked { sleep $_; $_*3 }, 1..4;

    sleep 2; # gives time for half of list to be processed
    my $t = time;
    is_deeply( \@list, [3,6,9,12], 'List was correct' );
    my $delta = time-$t;
    # we'd expect to have been at least another 2 seconds
    ok( ($delta >= 2) && ($delta <= 3), 'Waited ca another 2 seconds to process rest of list');
}

# COMPLEX CALC
my $complex = forked { [1,2] };
TODO: {
    local $TODO = 1;
    is_deeply( $complex, [1,2], "Complex value is forced correctly" );
}
is_deeply( [@$complex], [1,2], "Complex value is correct, if manually forced" );

wait_kids; # in case of zombies

done_testing;
