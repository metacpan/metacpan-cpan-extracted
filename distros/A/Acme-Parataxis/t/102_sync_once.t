use v5.40;
use blib;
use Acme::Parataxis qw[async fiber await_sleep];
use Acme::Parataxis::Sync::Once;
use Test2::V1 -ipP;
$|++;
subtest 'the action runs exactly once and racing callers block till done' => sub {
    my $o    = Acme::Parataxis::Sync::Once->new;
    my $done = 0;
    my $runs = 0;
    my @waiter_res;
    async {
        my @fs;
        push @fs, fiber {
            my $v = $o->do(
                sub {
                    $runs++;
                    my $inner = fiber { await_sleep(15); 1 };
                    $inner->await;
                    $done = 'finished';
                    $runs;
                }
            );
            $v;
        }
        for 1 .. 5;
        @waiter_res = map { $_->await } @fs;
    };
    is $runs,          1,          'the init ran exactly once across five racing callers';
    is $done,          'finished', 'the waiters observed the init completing';
    is $waiter_res[0], 1,          'the executing fiber receives the init return value';
    ok !defined $waiter_res[1], 'a racing waiter receives no value';
    ok $o->done,                'Once reports done afterwards';
};
subtest 'late callers no-op immediately' => sub {
    my $o    = Acme::Parataxis::Sync::Once->new;
    my $runs = 0;
    async {
        $o->do( sub { $runs++ } );
        my $late = fiber {
            $o->do( sub { $runs++ } )
        };
        is $late->await, undef, 'a late do() returns nothing';
        is $runs,        1,     'and does not run the action again';
    };
};
subtest 'an init that dies still completes the Once' => sub {
    my $o   = Acme::Parataxis::Sync::Once->new;
    my $err = '';
    async {
        $err = dies {
            $o->do( sub { await_sleep(2); die 'boom' } );
        };
        my $late = fiber {
            $o->do( sub { die 'nope' } )
        };
        is $late->await, undef, 'a later caller is not re-entered';
    };
    like $err, qr/boom/, 'the executing fiber receives the init exception';
    ok $o->done, 'the Once is still marked done after the init died';
};
subtest 'do() is not reentrant and wants a CODE ref' => sub {
    my $o = Acme::Parataxis::Sync::Once->new;
    async {
        like dies { $o->do('not-code') }, qr/CODE reference/, 'a non-code argument croaks';
        my $err;
        $err = dies {
            $o->do(
                sub {
                    $o->do( sub {1} );
                }
            );
        };
        like $err, qr/not reentrant/, 'an init calling do() again on the same fiber croaks';
    };
};
subtest 'actions must run inside a scheduled fiber' => sub {
    my $o = Acme::Parataxis::Sync::Once->new;
    like dies {
        $o->do( sub {1} )
    }, qr/scheduled fiber/, 'do() croaks outside the scheduler';
};
#
done_testing;
