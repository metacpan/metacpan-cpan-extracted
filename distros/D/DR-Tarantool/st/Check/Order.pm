use utf8;
use strict;
use warnings;

package Check::Order;

use constant ITERATIONS => cfg 'check.order.iterations';
use DR::Tarantool ':constant';

sub start {

    my $done_time = 0;
    my $total = 0;
    my $errors = 0;

    while(1) {

        my $started = now();

        my $sid = uuid;
        my $pid = uuid;

        my @orders;
        for (my $i = 0; $i < ITERATIONS; $i++) {

            push @orders => tnt->call_lua(order_add => [
                uuid,
                $pid,
                uuid,
                now(),
                'request',
                $sid,
                uuid,
                '<driver xml>',
                '<order xml>'
            ] => 'orders');

        }

        for (@orders) {
            $_ = [
                $_,
                tnt->call_lua(order_add => [
                    $_->oid,
                    $_->pid,
                    $_->oid_in_pid,
                    now(),
                    ( ( int rand 100 < 50 ) ? 'request' : 'confirm' ),
                    $_->sid,
                    $_->did,
                    '<driver xml>',
                    '<order xml>'
                ] => 'orders')
            ];

            $errors++
                if error((
                        !$_->[1] or
                        !(@{ $_->[1]->raw } - 1 == @{ $_->[0]->raw })
                    ), 'update'
                );
        }


        for (@orders) {
            my $o = tnt->delete(orders => $_->[0]->oid, TNT_FLAG_RETURN);
            $errors++
                if error((
                        !$_->[-1] or
                        !$o or
                        !(@{ $_->[-1]->raw } ~~ @{ $o->raw })
                    ),
                    'delete'
                );
        }

        my $period = now() - $started;
        $done_time += $period;
        $total += ITERATIONS;


        df "done %d iterations in %3.2f seconds (%d errors)",
            $total,
            $done_time,
            $errors
        ;


        df "%d r/s, %3.5f s/r, %3.5f errors/s",
            $total / $done_time,
            $done_time / $total,
            $errors / $done_time
        ;

    }
}

1;
