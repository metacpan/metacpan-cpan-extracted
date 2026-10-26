use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
$|++;

# This is the synopsis for Acme::Parataxis but verbose
Acme::Parataxis::run(
    sub {
        diag 'Main fiber started (FID: ' . Acme::Parataxis->current_fid . ')';

        # Spawn background workers
        diag 'Spawning Task 1 (Sleep)...';
        my $f1 = Acme::Parataxis->spawn(
            sub {
                diag 'Task 1 started (FID: ' . Acme::Parataxis->current_fid . ')';
                diag 'Task 1: Sleeping in a native thread pool (1000ms)...';
                Acme::Parataxis->await_sleep(1000);
                diag 'Task 1: Ah! What a nice nap...';
                return 42;
            }
        );
        diag 'Spawning Task 2 (I/O dummy)...';
        my $f2 = Acme::Parataxis->spawn(
            sub {
                diag 'Task 2 started (FID: ' . Acme::Parataxis->current_fid . ')';
                diag 'Task 2: Performing I/O simulation...';

                # await_read/write for non-blocking socket handling
                return 'I/O Done';
            }
        );

        # Block current fiber until results are ready (without blocking the thread)
        diag 'Main: Waiting for Task 1 result...';
        my $res1 = $f1->await();
        is $res1, 42, 'Task 1 returned expected value';
        diag "Main: Task 1 result: $res1";
        diag 'Main: Waiting for Task 2 result...';
        my $res2 = $f2->await();
        is $res2, 'I/O Done', 'Task 2 returned expected value';
        diag "Main: Task 2 result: $res2";
    }
);
done_testing();
