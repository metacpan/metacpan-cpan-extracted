use v5.40;
use lib 'lib';
use blib;
use Acme::Parataxis qw[:all];
use Acme::Parataxis::Future;
$|++;
async {
    say 'Main: starting...';

    # A future produced by a background fiber...
    my $fetch = Acme::Parataxis::Future->new;

    # ...and registered for a side effect when it lands.
    $fetch->on_ready( sub ($f) { say '  on_ready: future resolved with ' . $f->result } );
    fiber {
        say '  Producer: doing slow work elsewhere...';
        await_sleep(200);
        $fetch->set_result('fresh data');
    };

    # Multiple consumers may await the same future at once.
    for my $me ( 1 .. 3 ) {
        fiber {
            my $data = $fetch->await;
            say "  Consumer $me: got '$data'";
        };
    }

    # Go do unrelated work while everyone else waits.
    say 'Main: doing something else meanwhile...';
    await_sleep(300);
    my $res = $fetch->await;
    say "Main: consumer result '$res'";

    # Futures can also carry failures.
    my $failing = Acme::Parataxis::Future->new;
    fiber { await_sleep(50); $failing->set_error('the disk is on fire') };
    my $err = '';
    eval { $failing->await };
    $err = $@ if $@;
    $err =~ s/\s*at .*? line \d+\.?\s*\z//;
    say 'Main: await failed with: ' . $err;
};
