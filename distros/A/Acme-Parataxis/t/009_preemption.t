use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
$|++;
#
my $log = '';

# Set threshold to 5, once via the documented function form and once via the
# class-method form (both must route to the same C setter).
Acme::Parataxis::set_preempt_threshold(5);
Acme::Parataxis->set_preempt_threshold(5);
my $c1 = Acme::Parataxis->new(
    code => sub {
        for ( 1 .. 10 ) {
            $log .= 'A';
            Acme::Parataxis->maybe_yield();
        }
    }
);
my $c2 = Acme::Parataxis->new(
    code => sub {
        for ( 1 .. 10 ) {
            $log .= 'B';
            Acme::Parataxis->maybe_yield();
        }
    }
);

# Call C1. It should run 5 times and then maybe_yield will switch back to main
# because the threshold is hit.
# WAIT: who is the parent? Main.
diag 'Calling C1...';
my $res1 = $c1->call();
is $log, 'AAAAA', 'C1 yielded after 5 iterations';
diag 'Calling C2...';
my $res2 = $c2->call();
is $log, 'AAAAABBBBB', 'C2 yielded after 5 iterations';
diag 'Resuming C1...';
$c1->call();
is $log, 'AAAAABBBBBAAAAA', 'C1 finished its remaining iterations';
diag 'Resuming C2...';
$c2->call();
is $log, 'AAAAABBBBBAAAAABBBBB', 'C2 finished its remaining iterations';
#
done_testing();
