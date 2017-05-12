use utf8;
use strict;
use warnings;

package Check::OneTree;
use AnyEvent;
use Coro;
use Coro::AnyEvent;
use DR::Tarantool ':constant';

use constant ITERATIONS => cfg 'check.onetree.iterations';

sub start {

    my $done_time = 0;
    my $total = 0;
    my @fields;
    my $total_errors = 0;
    
    while(1) {

        my $started = now();
        my $errors = 0;

        for (my $i = 0; $i < ITERATIONS; $i++) {
            push @fields => tnt->insert(
                one_tree => [ uuid, uuid ], TNT_FLAG_RETURN);
        }


        for (@fields) {
            my $f = tnt->select(one_tree => [ $_->id ]);
            if ($f) {
                next if $f->id ~~ $_->id;
                next if $f->value ~~ $_->value;
            }
            error 1, 'select exists tuple';
            $errors++;
        }

        for (@fields) {
            my $f = tnt->delete(one_tree => [ $_->id ], TNT_FLAG_RETURN);
            if ($f) {
                next if $f->id ~~ $_->id;
                next if $f->value ~~ $_->value;
            }
            error 1, 'delete exists tuple';
            $errors++;
        }

        for (@fields) {
            next if !defined tnt->select(one_tree => [ $_->id ]);
            $errors++;
            error 1, 'select unexists tuple';
        }

        @fields = ();
        
        my $period = now() - $started;

        $done_time += $period;
        $total += ITERATIONS;
        $total_errors += $errors;

        df '%d iterations in %3.3f seconds (%d errors)',
            $total,
            $done_time,
            $total_errors
        ;
        
        df "%d r/s, %3.5f s/r, %3.5f err/s",
            $total / $done_time,
            $done_time / $total,
            $total_errors / $done_time
        ;
        
    }


}

1;
