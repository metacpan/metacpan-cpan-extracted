use v5.40;
use blib;
use Acme::Parataxis::Future;
use Acme::Parataxis qw[async fiber yield await_sleep wait_all wait_any];
use Test2::V1 -ipP;
$|++;

# wait_all/wait_any live in Acme::Parataxis (perlclass on Future forbids class-callable methods other than new, so
# they are plain exported subs). They are callable both as the exported functions wait_all(@f)/wait_any(@f) and as
# Acme::Parataxis->wait_all(@f)/Acme::Parataxis->wait_any(@f).
subtest 'wait_all: aggregates results in input order regardless of completion order' => sub {
    my @f   = map { Acme::Parataxis::Future->new } 1 .. 3;
    my $all = wait_all(@f);
    my $got;
    async {
        fiber { yield; $f[2]->set_result('three') };
        fiber { yield; $f[0]->set_result('one') };
        $f[1]->set_result('two');
        $got = $all->await;
    };
    is $got, [ 'one', 'two', 'three' ], 'arrayref of results in input order';
};
subtest 'wait_all: zero futures resolves immediately with []' => sub {
    my $all = wait_all();
    ok $all->is_ready, 'no inputs resolves inline';
    is $all->result, [], 'result is an empty arrayref';
};
subtest 'wait_all: rejects fast on the first failure' => sub {
    my ( $g, $h ) = map { Acme::Parataxis::Future->new } 1 .. 2;
    my $all = wait_all( $g, $h );
    async {
        fiber { yield; $g->set_error('kaput') };
        $h->set_result('late');
        like dies { $all->await }, qr/kaput/, 'the first failure surfaces through await';
    };
};
subtest 'wait_all: a pre-resolved failure settles the group inline, no fiber needed' => sub {
    my $g = Acme::Parataxis::Future->new;
    $g->set_error('doomed');
    my $all = wait_all($g);
    ok $all->is_ready, 'resolved inline';
    like dies { $all->result; 1 }, qr/doomed/, 'result() dies with the copied error';
};
subtest 'wait_all: already-resolved inputs need no fiber' => sub {
    my $f = Acme::Parataxis::Future->new;
    $f->set_result('x');
    my $g = Acme::Parataxis::Future->new;
    $g->set_result('y');
    my $all = wait_all( $f, $g );
    ok $all->is_ready, 'resolved inline';
    is $all->result, [ 'x', 'y' ], 'pre-resolved inputs appear in order';
};
subtest 'wait_all: mixes pre-resolved and pending inputs' => sub {
    my $f = Acme::Parataxis::Future->new;
    $f->set_result('first');
    my $g   = Acme::Parataxis::Future->new;
    my $all = wait_all( $f, $g );
    my $got;
    async {
        fiber { yield; $g->set_result('second') };
        $got = $all->await;
    };
    is $got, [ 'first', 'second' ], 'both inputs landed in order';
};
subtest 'wait_all: croaks on a non-future input' => sub {
    like dies { wait_all('nope') },                             qr/Future/, 'a plain string croaks';
    like dies { wait_all( Acme::Parataxis::Future->new, 42 ) }, qr/Future/, 'a mixed list croaks';
};
subtest 'wait_all: class-callable form Acme::Parataxis->wait_all' => sub {
    my ( $g, $h ) = map { Acme::Parataxis::Future->new } 1 .. 2;
    my $all = Acme::Parataxis->wait_all( $g, $h );
    async {
        fiber { yield; $g->set_result('a') };
        $h->set_result('b');
        is $all->await, [ 'a', 'b' ], 'class form aggregates in order';
    };
};
subtest 'wait_any: copies the first success wholesale' => sub {
    my @f   = map { Acme::Parataxis::Future->new } 1 .. 2;
    my $any = wait_any(@f);
    my $got;
    async {
        my $child = fiber { $f[0]->set_result('fast') };
        $child->await;
        $f[1]->set_result('slow');
        $got = $any->await;
    };
    is $got, 'fast', "the first winner's value was copied";
};
subtest 'wait_any: copies the first failure wholesale' => sub {
    my ( $g, $h ) = map { Acme::Parataxis::Future->new } 1 .. 2;
    my $any = wait_any( $g, $h );
    async {
        my $child = fiber { $g->set_error('boom') };
        $child->await;
        $h->set_result('irrelevant');
        like dies { $any->await }, qr/boom/, 'the loser future stays unresolved and untouched';
    };
};
subtest 'wait_any: an already-ready input wins immediately' => sub {
    my $f = Acme::Parataxis::Future->new;
    $f->set_result('now');
    my $g   = Acme::Parataxis::Future->new;
    my $any = wait_any( $f, $g );
    ok $any->is_ready, 'resolved inline';
    is $any->result, 'now', 'the ready input won';
};
subtest 'wait_any: requires at least one input and croaks on non-futures' => sub {
    like dies {wait_any},          qr/at least one/, 'an empty race croaks';
    like dies { wait_any(undef) }, qr/Future/,       'undef croaks';
};
subtest 'wait_any: a stray later settle does not disturb the copied winner' => sub {

    # A loser future that later succeeds must not disturb an already-copied winner.
    my $winner = Acme::Parataxis::Future->new;
    my $stray  = Acme::Parataxis::Future->new;
    my $any    = wait_any( $stray, $winner );
    $winner->set_result('won');
    is $any->result, 'won', 'winner copied before the stray resolved';
    $stray->set_result('noop');
    is $any->result, 'won', 'the loser future did not overwrite the winner';
};
subtest 'wait_any: class-callable form Acme::Parataxis->wait_any' => sub {
    my ( $g, $h ) = map { Acme::Parataxis::Future->new } 1 .. 2;
    my $any = Acme::Parataxis->wait_any( $g, $h );
    async {
        my $child = fiber { $g->set_error('halt') };
        $child->await;
        $h->set_result('late');
        like dies { $any->await }, qr/halt/, 'class form copies the first failure wholesale';
    };
};
#
done_testing();
