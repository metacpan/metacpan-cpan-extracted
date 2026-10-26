use v5.40;
use blib;
use Acme::Parataxis qw[async fiber await_sleep];
use Acme::Parataxis::Monitor;
use Acme::Parataxis::Nursery;
use Acme::Parataxis::Actor;
use Test2::V1 -ipP;
$|++;
async {
    subtest 'monitor resolves undef on a clean target and leaves its lifecycle alone' => sub {
        my $f   = fiber { await_sleep(1); 'child-value' };
        my $mon = Acme::Parataxis::Monitor->new( target => $f );
        is $f->await, 'child-value', 'the target ran to its own result even though it is watched';
        ok $mon->is_ready, 'the monitor resolved once the target completed';
        is $mon->await,  undef, 'a clean end resolves to undef';
        is $mon->result, undef, 'result() agrees';
        is $mon->error,  undef, 'error() is undef for a clean end';
        is $f->fid,      -1,    'the target slot was released (the monitor did not keep it live)';
        ok $f->is_done, 'the target reports done while the monitor still watches it';
    };
    subtest 'monitor resolves with the death error on a crash' => sub {
        my $ef  = fiber { await_sleep(1); die "boom\n" };
        my $mon = Acme::Parataxis::Monitor->new( target => $ef );
        is $mon->await, "boom\n", 'the crash error is the monitor value';
        is $mon->error, "boom\n", 'error() reports the death error';
        ok $mon->is_ready, 'the crashed target resolved the monitor';
        $ef->is_done;    # reap the crashed slot
    };
    subtest 'an already-dead target fires immediately' => sub {
        my $f = fiber { await_sleep(1); 1 };
        $f->await;
        my $mon = Acme::Parataxis::Monitor->new( target => $f );
        ok $mon->is_ready, 'watching a finished fiber resolves right away';
        is $mon->await, undef, 'and resolves to undef';
    };
    subtest 'fires exactly once' => sub {
        my $f     = fiber { await_sleep(1); 1 };
        my $mon   = Acme::Parataxis::Monitor->new( target => $f );
        my $fires = 0;
        $mon->on_ready( sub { $fires++ } );
        $f->await;
        is $fires, 1, 'the ready hook ran exactly once';
        $mon->await;
        is $fires, 1, 'awaiting again does not re-fire';
    };
    subtest 'tracking by fiber id' => sub {
        my $f   = fiber { await_sleep(1); 1 };
        my $mon = Acme::Parataxis::Monitor->new( fid => $f->fid );
        is $mon->fid, $f->fid, 'the monitor reports the watched fid';
        $f->await;
        ok $mon->is_ready, 'a by-id monitor resolves too';
        is $mon->await, undef, 'with the same clean value';
    };
    subtest 'does not disturb a nursery child' => sub {
        my $n     = Acme::Parataxis::Nursery->new;
        my $child = $n->spawn( sub { await_sleep(1); 'nc' } );
        my $mon   = Acme::Parataxis::Monitor->new( target => $child );
        is $child->await, 'nc', 'the nursery child finished normally while watched';
        ok $mon->is_ready, 'the nursery-child observation resolved';
        is $mon->await, undef, 'cleanly';
    };
    subtest 'actors: graceful stop resolves undef, supervised crash resolves with the error' => sub {
        my $actor = Acme::Parataxis::Actor->spawn( sub { return 1 } );
        my $mon   = Acme::Parataxis::Monitor->new( target => $actor );
        is $mon->fid, $actor->fid, 'actor monitors report the actor fid';
        $actor->stop;
        is $mon->await, undef, 'a graceful stop resolves undef';
        ok $actor->is_alive == 0, 'the actor really stopped';
        my $crash_actor = Acme::Parataxis::Actor->spawn( sub { die "handler-boom\n" }, 16, supervised => 1 );
        my $cmon        = Acme::Parataxis::Monitor->new( target => $crash_actor );
        $crash_actor->send('go');
        is $cmon->await, "handler-boom\n", 'a supervised handler crash resolves with the death error';
    };
    subtest 'watching the run root fiber resolves when the run ends' => sub {
        my $root_mon;
        async {
            my $rf = Acme::Parataxis->by_id( Acme::Parataxis->current_fid );
            $root_mon = Acme::Parataxis::Monitor->new( target => $rf );
            ok !$root_mon->is_ready, 'the root monitor is pending while the run body is live';
        };
        ok $root_mon->is_ready, 'the root monitor resolves when the run body ends';
        is $root_mon->result, undef, 'the run ended cleanly';
    };
    subtest 'unwatchable or missing targets croak' => sub {
        like dies { Acme::Parataxis::Monitor->new() }, qr/requires a target to watch/, 'no target croaks';
        like dies { Acme::Parataxis::Monitor->new( target => {} ) },          qr/requires a blessed target/,         'unblessed targets croak';
        like dies { Acme::Parataxis::Monitor->new( fid    => 999_999_999 ) }, qr/couldn't find a fiber/,             'unknown fiber id croaks';
        like dies { Acme::Parataxis::Monitor->new( target => 1, fid => 2 ) }, qr/takes a target or a fid, not both/, 'target and fid together croak';
    };
};
done_testing;
