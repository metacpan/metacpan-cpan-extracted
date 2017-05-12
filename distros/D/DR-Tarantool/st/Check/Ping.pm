use utf8;
use strict;
use warnings;

package Check::Ping;

use constant ITERATIONS => cfg 'check.ping.iterations';

sub start {

    my $done_time = 0;
    my $total = 0;

    while(1) {

        my $started = now();
        for (my $i = 0; $i < ITERATIONS; $i++) {
            die "Can't ping tarantool\n" unless tnt->ping;
        }

        my $period = now() - $started;
        $done_time += $period;
        $total += ITERATIONS;


        df "done %d pings in %3.2f seconds",
            $total,
            $done_time
        ;

            
        df "%d r/s, %3.5f s/r",
            $total / $done_time,
            $done_time / $total
        ;

    }
}

1;
