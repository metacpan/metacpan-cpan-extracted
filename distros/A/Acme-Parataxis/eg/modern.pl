use v5.40;
use blib;
use Acme::Parataxis qw[:all];
#
async {
    say 'Main fiber started';
    my $f1 = fiber {    # spawn a new OS fiber
        say '  Fiber 1: Sleeping...';
        await_sleep(1000);
        say '  Fiber 1: Woke up!';
        return 42;
    };
    my $res1 = await $f1;    # wait for results
    say 'Main: Fiber 1 returned ' . $res1;
    say 'Creating a manual fiber for bidirectional communication...';

    # Fibers made with ->new are driven by call()/transfer(); await() is for
    # fibers spawned into the scheduler (and for Future objects).
    my $f2 = Acme::Parataxis->new(
        code => sub {
            say '  Fiber 2: Yielding some data...';
            my $received = yield('Data from F2');
            say '  Fiber 2: Resumed with: ' . $received;
            return 'Final result from F2';
        }
    );

    # The manual call/yield pattern works alongside the scheduler
    my $yielded = $f2->call();
    say 'Main: Fiber 2 yielded: ' . $yielded;
    $f2->call('Data from Main');
    say 'Main: Fiber 2 is ' . ( $f2->is_done ? 'done' : 'still running' );
    say 'All done!';
};
