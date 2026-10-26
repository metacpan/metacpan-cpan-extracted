use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
$|++;
#
subtest 'Direct transfer dance' => sub {
    my ( $p1, $p2 );
    my $log = '';
    $p1 = Acme::Parataxis->new(
        code => sub {
            $log .= '1';
            diag 'Fiber 1: Transferring to 2...';
            $p2->transfer();
            $log .= '3';
            diag 'Fiber 1: Transferring to 2 again...';
            $p2->transfer();
            $log .= '5';
            diag 'Fiber 1: Returning...';
            return 'Final 1';
        }
    );
    $p2 = Acme::Parataxis->new(
        code => sub {
            $log .= '2';
            diag 'Fiber 2: Transferring back to 1...';
            $p1->transfer();
            $log .= '4';
            diag 'Fiber 2: Transferring back to 1 again...';
            $p1->transfer();

            # In a symmetric model, we should transfer back to exit cleanly if we want someone to continue
            diag 'Fiber 2: Final transfer back to 1...';
            $p1->transfer();
        }
    );
    diag 'Starting the dance...';
    $p1->call();

    # Ensure both are recognized as done
    $p1->is_done;
    $p2->is_done;
    is $log, '12345', 'Control flowed symmetrically between fibers';
    ok $p1->is_done, 'Fiber 1 finished';
    ok $p2->is_done, 'Fiber 2 finished';
};
subtest 'Transfer with arguments' => sub {
    my ( $p1, $p2 );
    my @received;
    $p1 = Acme::Parataxis->new(
        code => sub {
            my $val = Acme::Parataxis->yield();
            push @received, $val;
            diag "Fiber 1: Received $val, transferring 'Apple' to 2...";
            $p2->transfer('Apple');
            diag 'Fiber 1: Resumed after p2 finished, returning...';
            return 'Finished 1';
        }
    );
    $p2 = Acme::Parataxis->new(
        code => sub {
            my $val = Acme::Parataxis->yield();
            push @received, $val;
            diag "Fiber 2: Received $val, transferring back to 1...";
            $p1->transfer('Orange');
            return 'Finished 2';
        }
    );

    # Prime them
    $p1->call();
    $p2->call();
    diag 'Sending initial trigger via transfer...';
    $p1->transfer('Start');
    is \@received, [ 'Start', 'Apple' ], 'Arguments passed correctly via transfer';

    # Manually check completion
    $p1->is_done;
    $p2->is_done;
    ok $p1->is_done, 'Fiber 1 finished';
    ok $p2->is_done, 'Fiber 2 finished';
};
done_testing();
