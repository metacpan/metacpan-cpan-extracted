use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield];
use Acme::Parataxis::Actor;
use Acme::Parataxis::Supervisor;
use Acme::Parataxis::Error;
use Test2::V1 -ipP;
$|++;

# OTP-style supervisor trees. Children are supervised actors (or nested supervisors) that
# are restarted when they die, per restart strategy, until a restart budget runs out - at which
# point the tree stops and run() fails with an aggregate Acme::Parataxis::Error::Supervisor.
#
# Every assertion below is paired with a control: an untouched sibling, a second strategy, a budget
# nobody can exhaust, or the same crash loop under a window that does not expire.
# A factory that starts one supervised actor. The handler answers 'hi', dies on 'boom', and echoes
# anything else, so a restarted child is distinguishable from a dead one by asking it something.
sub make_child ( $name, $capacity = 4 ) {
    return sub {
        Acme::Parataxis::Actor->spawn(
            sub ( $self, $msg ) {
                return "hello from $name" if $msg eq 'hi';
                die "$name exploded"      if $msg eq 'boom';
                return "$name:$msg";
            },
            $capacity,
            supervised => 1
        );
    };
}

# A child that dies as soon as it handles anything, so a restart loop needs no driver at all.
sub make_suicide () {
    return sub {
        my $actor = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { die "kamikaze: $msg" }, 4, supervised => 1 );
        $actor->send('boom');
        return $actor;
    };
}

# Spin the scheduler until $cond holds. Bounded so a condition that can never become true fails the
# assertion instead of hanging the suite.
sub wait_for ($cond) {
    for ( 1 .. 5_000 ) { return 1 if $cond->(); yield }
    return $cond->() ? 1 : 0;
}

sub all_alive ( $sup, @names ) {
    for my $name (@names) {
        my $child;
        ok lives { $child = $sup->child($name) };
        return 0 unless $child && $child->is_alive;
    }
    return 1;
}

# Await a future the way a caller sees a failure: returns the error, or undef if it answered.
sub ask_err ($future) {
    return undef if eval { $future->await };
    return "$@";
}
subtest 'configuration and registration are validated' => sub {
    my $sup = Acme::Parataxis::Supervisor->new;
    is $sup->strategy,     'OneForOne', 'default strategy';
    is $sup->max_restarts, 5,           'default restart budget';
    is $sup->within,       60,          'default window in seconds';
    ok !$sup->running,  'a fresh supervisor is not running';
    ok !$sup->stopping, 'and has not been stopped';
    ok dies { Acme::Parataxis::Supervisor->new( strategy     => 'Whatever' ) }, 'an unknown strategy is rejected';
    ok dies { Acme::Parataxis::Supervisor->new( max_restarts => -1 ) },         'a negative budget is rejected';
    ok dies { Acme::Parataxis::Supervisor->new( within       => -5 ) },         'a negative window is rejected';
    ok dies { Acme::Parataxis::Supervisor->new( within       => 'soon' ) },     'a non-numeric window is rejected';
    ok dies { Acme::Parataxis::Supervisor->new( within       => '1e3' ) },      'so is an exponent, not a number of seconds';
    ok dies { Acme::Parataxis::Supervisor->new( within       => undef ) },      'and so is no window at all';
    ok lives { Acme::Parataxis::Supervisor->new( within   => 0.5 ) },                                          'a fractional window is accepted';
    ok lives { Acme::Parataxis::Supervisor->new( strategy => 'RestForOne', max_restarts => 0, within => 0 ) }, 'a valid configuration is accepted';
    my $reg = Acme::Parataxis::Supervisor->new;
    ok dies { $reg->supervise('not a child') },                   'supervise() rejects something that is not a child';
    ok lives { $reg->supervise( make_child('a'), name => 'a' ) }, 'and accepts a factory';
    ok dies { $reg->supervise( make_child('b'), name => 'a' ) }, 'a duplicate child name is rejected';
    ok dies { $reg->supervise( make_child('b'), name => 'b', bogus => 1 ) }, 'an unknown option is rejected';
    is [ $reg->children ], ['a'], 'the accepted child is the only one registered';
    my $off_loop = dies { $sup->run };    # dies localises $@, so the reason has to be taken from its return
    ok $off_loop, 'run() outside a scheduled fiber is rejected';
    like "$off_loop", qr[scheduled fiber], 'and says why';
    async {
        my $childless = Acme::Parataxis::Supervisor->new;
        my $no_kids   = dies { $childless->run };
        ok $no_kids, 'run() with nothing to supervise is rejected';
        like "$no_kids", qr[at least one supervised child], 'instead of blocking forever';
        my $again = Acme::Parataxis::Supervisor->new;
        $again->supervise( make_child('a'), name => 'a' );
        fiber {
            wait_for( sub { all_alive( $again, 'a' ) } );
            my $mid_run = dies { $again->supervise( make_child('b'), name => 'b' ) };
            ok $mid_run, 'a child cannot be added mid-run';
            like "$mid_run", qr[once run], 'and says why';
            $again->stop;
        };
        my $returned;
        ok lives { $returned = $again->run };    # lives sets $@, so the diag below still has the reason
        ok defined $returned, 'run() returns after a stop' or diag $@;
        my $twice = dies { $again->run };        # dies localises $@, so the reason has to be taken from its return
        ok $twice, 'but only once';
        like "$twice", qr[only be called once], 'with the reason';
    };
};
subtest 'OneForOne restarts the child that died and never touches its siblings' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    async {
        my $sup = Acme::Parataxis::Supervisor->new( strategy => 'OneForOne' );
        $sup->supervise( make_child($_), name => $_ ) for qw[a b c];
        fiber {
            ok wait_for( sub { all_alive( $sup, qw[a b c] ) } ), 'all three children came up';
            my %original = map { $_ => $sup->child($_) } qw[a b c];
            my $err      = ask_err( $sup->child('b')->ask('boom') );
            like $err, qr[b exploded], 'the dying child failed its own ask';
            ok wait_for( sub { $sup->restarts('b') >= 1 } ), 'and was restarted';
            is $sup->restarts('b'), 1, 'exactly once';
            is $sup->restarts('a'), 0, 'sibling a was not restarted (control)';
            is $sup->restarts('c'), 0, 'sibling c was not restarted (control)';
            ok $sup->child('a') == $original{a}, 'sibling a is still the very same actor';
            ok $sup->child('c') == $original{c}, 'so is sibling c';
            ok $sup->child('b') != $original{b}, 'the dead child was replaced by a new actor';
            is $sup->child('b')->ask('hi')->await, 'hello from b', 'and the replacement answers';
            $sup->stop;
        };
        $sup->run;
        ok !$sup->running, 'the tree stopped';
    };
    is Acme::Parataxis::get_live_fiber_count(), $base, 'and left no fiber behind';
};
subtest 'OneForAll restarts the whole set, because the children share the broken state' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    async {
        my $sup = Acme::Parataxis::Supervisor->new( strategy => 'OneForAll' );
        $sup->supervise( make_child($_), name => $_ ) for qw[a b c];
        fiber {
            ok wait_for( sub { all_alive( $sup, qw[a b c] ) } ), 'all three children came up';
            my %original = map { $_ => $sup->child($_) } qw[a b c];
            is $sup->restarts, 0, 'and none of them had been restarted yet (control)';
            ask_err( $sup->child('b')->ask('boom') );
            ok wait_for( sub { $sup->restarts('a') >= 1 && $sup->restarts('b') >= 1 && $sup->restarts('c') >= 1 } ),
                'one death restarted every child';
            is $sup->restarts('a'), 1, 'a restarted once';
            is $sup->restarts('b'), 1, 'b restarted once';
            is $sup->restarts('c'), 1, 'c restarted once';
            ok $sup->child('a') != $original{a}, 'a is a new actor, not the old one';
            ok $sup->child('c') != $original{c}, 'c was replaced too';
            is $sup->child('a')->ask('hi')->await, 'hello from a', 'the rebuilt set still works';
            $sup->stop;
        };
        $sup->run;
    };
    is Acme::Parataxis::get_live_fiber_count(), $base, 'and left no fiber behind';
};
subtest 'RestForOne restarts the dying child and everything started after it' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    async {
        my $sup = Acme::Parataxis::Supervisor->new( strategy => 'RestForOne' );
        $sup->supervise( make_child($_), name => $_ ) for qw[a b c];
        fiber {
            ok wait_for( sub { all_alive( $sup, qw[a b c] ) } ), 'all three children came up';
            my %original = map { $_ => $sup->child($_) } qw[a b c];

            # Control first: the last child has no suffix, so killing it restarts only itself.
            ask_err( $sup->child('c')->ask('boom') );
            ok wait_for( sub { $sup->restarts('c') >= 1 } ), 'c was restarted';
            is $sup->restarts('a'), 0, 'killing the last child left a alone (control)';
            is $sup->restarts('b'), 0, 'and left b alone (control)';
            ok $sup->child('a') == $original{a}, 'a is still the original actor';

            # Then the real case: b's suffix is b and c, and a started before it.
            ask_err( $sup->child('b')->ask('boom') );
            ok wait_for( sub { $sup->restarts('b') >= 1 && $sup->restarts('c') >= 2 } ), 'b and c were restarted';
            is $sup->restarts('a'), 0, 'a, which started earlier, was not touched';
            ok $sup->child('a') == $original{a}, 'a is still the very same actor object';
            ok $sup->child('b') != $original{b}, 'b was replaced';
            ok $sup->child('c') != $original{c}, 'and c was replaced again';
            $sup->stop;
        };
        $sup->run;
    };
    is Acme::Parataxis::get_live_fiber_count(), $base, 'and left no fiber behind';
};
subtest 'an already-spawned actor is adopted, a factory builds one when the tree starts' => sub {
    async {
        my $adopted
            = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { $msg eq 'boom' ? die 'adopted exploded' : "adopted:$msg" }, 4, supervised => 1 );
        my $sup = Acme::Parataxis::Supervisor->new;
        $sup->supervise( $adopted,           name => 'adopted' );
        $sup->supervise( make_child('made'), name => 'made' );
        fiber {
            ok wait_for( sub { all_alive( $sup, qw[adopted made] ) } ), 'both children are up';
            is $sup->child('adopted'), $adopted, 'the adopted child is the actor that was passed in';
            ask_err( $adopted->ask('boom') );
            ok wait_for( sub { $sup->restarts('adopted') >= 1 } ), 'the adopted child was restarted';
            ok !$adopted->is_alive,                                'the actor handed to supervise() is the one that died';
            ok $sup->child('adopted') != $adopted,                 'and its replacement was spawned fresh';
            is $sup->restarts('made'), 0, 'the factory-built sibling was left alone (control)';
            $sup->stop;
        };
        $sup->run;
    };
};
subtest 'restart budget exhaustion fails the tree with an aggregate error' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    my $sup1;
    my $survived = lives {
        async {
            $sup1 = Acme::Parataxis::Supervisor->new( max_restarts => 2, within => 60 );
            $sup1->supervise( make_suicide(), name => 'kamikaze' );
            $sup1->run;
        };
    };
    my $e = $@;
    ok !$survived, 'run() died once the budget ran out' or diag $e;
    isa_ok $e, 'Acme::Parataxis::Error::Supervisor';
    is $e->child, 'kamikaze',   'naming the child that blew the budget';
    is $e->kind,  'supervisor', 'kind is supervisor';
    like "$e", qr[restart budget], 'the message says what happened';
    my @failures = $e->failures;
    is scalar @failures, 3, 'two permitted restarts plus the death that exceeded them';
    ok defined $e->primary, 'primary names the death that exhausted the budget';
    like "$e->primary", qr[kamikaze], 'and it is the child crash, not a cancellation';
    ok !$sup1->running,                     'the tree is not running after the failure';
    ok !$sup1->child('kamikaze')->is_alive, 'and its last instance died with it';
    is Acme::Parataxis::get_live_fiber_count(), $base, 'every fiber of the tree was reaped';

    # Control: the identical crash loop under a budget nobody can exhaust never fails.
    my $sup;
    my $ok = lives {
        async {
            $sup = Acme::Parataxis::Supervisor->new( max_restarts => 50, within => 60 );
            $sup->supervise( make_suicide(), name => 'kamikaze' );
            fiber {
                ok wait_for( sub { $sup->restarts >= 3 } ), 'the control tree restarted three times over';
                $sup->stop;
            };
            $sup->run;
        };
    };
    ok $ok, 'the control run returned normally instead of failing' or diag $@;
    cmp_ok $sup->restarts, '>=', 3, 'with the restarts to prove it was really crashing';
    is Acme::Parataxis::get_live_fiber_count(), $base, 'and it left no fiber behind either';
};
subtest 'within => 0 keeps nothing in the window, so the same budget never trips' => sub {
    my $sup;
    my $ok = lives {
        async {
            $sup = Acme::Parataxis::Supervisor->new( max_restarts => 2, within => 0 );
            $sup->supervise( make_suicide(), name => 'kamikaze' );
            fiber {
                ok wait_for( sub { $sup->restarts >= 4 } ), 'restarted four times on a budget of two';
                $sup->stop;
            };
            $sup->run;
        };
    };
    ok $ok, 'run() returned instead of failing, because the window expired every restart' or diag $@;
    cmp_ok $sup->restarts, '>=', 4, 'it really did restart past the budget';
};
subtest 'a child factory that dies counts as a death of that child' => sub {
    my $survived = lives {
        async {
            my $sup = Acme::Parataxis::Supervisor->new( max_restarts => 1, within => 60 );
            $sup->supervise( sub { die 'the factory itself exploded' }, name => 'bad' );
            $sup->run;
        };
    };
    my $e = $@;
    ok !$survived, 'the tree gave up on a child that cannot even be started' or diag $e;
    isa_ok $e, 'Acme::Parataxis::Error::Supervisor';
    is $e->child, 'bad', 'naming the child';
    my @failures = $e->failures;
    is scalar @failures, 2, 'the first factory death restarted it, the second exhausted the budget';
    like "$failures[0]", qr[the factory itself exploded], 'carrying the factory error';
};
subtest 'nested supervisors restart their own children, and are restarted in turn' => sub {
    async {
        my $inner = Acme::Parataxis::Supervisor->new( max_restarts => 1, within => 60 );
        $inner->supervise( make_child('x'), name => 'x' );
        $inner->supervise( make_child('y'), name => 'y' );
        my $outer = Acme::Parataxis::Supervisor->new;
        $outer->supervise( $inner, name => 'inner' );
        fiber {
            ok wait_for( sub { all_alive( $inner, qw[x y] ) } ), 'the inner tree came up under the outer one';
            my $y_before = $inner->child('y');
            ask_err( $inner->child('x')->ask('boom') );
            ok wait_for( sub { $inner->restarts('x') >= 1 } ), 'the inner supervisor restarted its own child';
            is $outer->restarts('inner'), 0, 'the outer tree was not disturbed (control)';
            ok $inner->child('y') == $y_before, 'and the inner sibling was left alone (control)';

            # max_restarts => 1, so the second inner death exhausts the inner budget.
            ask_err( $inner->child('x')->ask('boom') );
            ok wait_for( sub { $outer->restarts('inner') >= 1 } ), 'the exhausted inner tree was restarted from above';
            ok $outer->child('inner') != $inner,                   'by a fresh supervisor object';
            ok wait_for(
                sub {
                    my $new_inner = $outer->child('inner');
                    $new_inner && all_alive( $new_inner, qw[x y] );
                }
                ),
                'and a rebuilt subtree underneath it';
            is $outer->child('inner')->restarts('x'),                0,              'the rebuilt subtree starts from scratch';
            is $outer->child('inner')->child('x')->ask('hi')->await, 'hello from x', 'and answers';
            $outer->stop;
        };
        $outer->run;
    };
};
subtest 'asks in flight at the moment of death are failed, never hung or silently dropped' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    my $check;
    async {
        my $sup = Acme::Parataxis::Supervisor->new;
        $sup->supervise( make_child( 'w', 4 ), name => 'w' );    # capacity 4: two asks queue without parking
        fiber {
            ok wait_for( sub { all_alive( $sup, 'w' ) } ), 'the child came up';
            my $dying = $sup->child('w');
            my $f1    = $dying->ask('boom');      # handled first, and it dies
            my $f2    = $dying->ask('second');    # queued behind it
            my $f3    = $dying->ask('third');     # and behind that
            my ( $e1, $e2, $e3 ) = ( ask_err($f1), ask_err($f2), ask_err($f3) );
            ok wait_for( sub { $sup->restarts('w') >= 1 } ), 'the child was restarted';
            my $fresh = $sup->child('w');
            ok $fresh != $dying, 'the replacement is a different actor';
            my $answer;
            ok lives { $answer = $fresh->ask('hi')->await };
            my $ask_err = $@;
            $check = [ defined $e1 ? "$e1" : 'NO ERROR', defined $e2 ? "$e2" : 'NO ERROR', defined $e3 ? "$e3" : 'NO ERROR' ];
            push @$check, defined $answer ? $answer : 'ASK FAILED: ' . ( $ask_err || 'unknown' );
            $sup->stop;
        };
        $sup->run;
    };
    like $check->[0], qr[w exploded], 'the ask being handled failed with the handler error';
    like $check->[1], qr[w exploded], 'the ask queued behind it failed too, it did not hang';
    like $check->[2], qr[w exploded], 'and so did the one behind that';
    is $check->[3],                             'hello from w', 'while the restarted actor answers on its own fresh mailbox';
    is Acme::Parataxis::get_live_fiber_count(), $base,          'and nothing outlived the tree';
};
subtest 'a sender parked on a full mailbox is woken and failed, not stranded' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    my $check;
    async {
        my $sup = Acme::Parataxis::Supervisor->new;
        $sup->supervise( make_child( 'w', 1 ), name => 'w' );    # capacity 1: the second ask parks in put()
        fiber {
            ok wait_for( sub { all_alive( $sup, 'w' ) } ), 'the child came up';
            my $dying = $sup->child('w');
            my $f1    = $dying->ask('boom');
            my $f2    = $dying->ask('parked');                   # the mailbox is full, so this one parks mid-send
            my ( $e1, $e2 ) = ( ask_err($f1), ask_err($f2) );
            ok wait_for( sub { $sup->restarts('w') >= 1 } ), 'the child was restarted';
            my $answer;
            ok lives { $answer = $sup->child('w')->ask('hi')->await };
            $check = [ defined $e1 ? "$e1" : 'NO ERROR', defined $e2 ? "$e2" : 'NO ERROR', defined $answer ? $answer : 'ASK FAILED' ];
            $sup->stop;
        };
        $sup->run;
    };
    like $check->[0], qr[w exploded], 'the handled ask failed with the handler error';
    like $check->[1], qr[w exploded], 'the parked sender was released and failed instead of waiting forever';
    is $check->[2],                             'hello from w', 'and the replacement answers';
    is Acme::Parataxis::get_live_fiber_count(), $base,          'nothing outlived the tree';
};
subtest 'stop() takes the whole tree down and leaves no fiber behind' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    my $sup;
    async {
        $sup = Acme::Parataxis::Supervisor->new;
        $sup->supervise( make_child($_), name => $_ ) for qw[a b c];
        my $names;
        fiber {
            ok wait_for( sub { all_alive( $sup, qw[a b c] ) } ), 'all three children came up';
            is join( ',', $sup->children ), 'a,b,c', 'children() reports them in start order';
            $names = join ',', $sup->children;
            $sup->stop;
        };
        $sup->run;
        ok $sup->stopping, 'run() returned because the tree was stopped';
        ok !$sup->running, 'and it is no longer running';
        is $names, 'a,b,c', 'the driver saw the same three children';
    };
    ok !$sup->running, 'the supervisor stayed stopped';
    is Acme::Parataxis::get_live_fiber_count(), $base, 'every fiber of the tree was reaped';
    for my $name (qw[a b c]) {
        ok !$sup->child($name)->is_alive, "child $name is gone";
    }
    my $croak = dies { $sup->child('a')->ask('hi') };    # dies localises $@, so the reason comes from its return
    ok $croak, 'and asking a stopped child croaks';
    like "$croak", qr[no longer running], 'instead of parking forever';
};
#
done_testing;
