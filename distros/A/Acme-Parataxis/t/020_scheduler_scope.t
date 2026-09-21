use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield await];
use Test2::V1 -ipP;
$|++;
#
subtest 'A created-but-never-run fiber does not block scheduler exit' => sub {
    ok eval {
        async {
            my $f = Acme::Parataxis->new( code => sub { return 'idle' } );
            pass 'created a fiber object, never spawned it';
        };
        1;
    }, 'async with an idle ->new fiber returns';
};
subtest 'Nested async shares the scheduler and returns the block result' => sub {
    my @order;
    my $inner_result;
    async {
        push @order, 'outer:start';
        $inner_result = async {
            push @order, 'inner';
            return 42;
        };
        push @order, 'outer:end';
    };
    is join( q{,}, @order ), 'outer:start,inner,outer:end', 'inner async ran between outer steps';
    is $inner_result,        42,                            'nested async returned the block value';
};
subtest 'async inside a spawned fiber' => sub {
    my @out;
    async {
        fiber {
            my $v = async {
                push @out, 'nested-worker';
                return 7;
            };
            push @out, "worker-got-$v";
        };
    };
    is join( q{,}, @out ), 'nested-worker,worker-got-7', 'fiber awaited a nested async';
};
subtest 'Deep nesting (three levels)' => sub {
    my @out;
    async {
        push @out, 'L1';
        async {
            push @out, 'L2';
            async { push @out, 'L3' };
            push @out, 'L2e';
        };
        push @out, 'L1e';
    };
    is join( q{,}, @out ), 'L1,L2,L3,L2e,L1e', 'order preserved through nesting';
};
subtest 'Parked fiber woken by a callback (rouse pattern)' => sub {
    my $got;
    async {
        my $fut = Acme::Parataxis->new( code => sub { die 'never run' } );
        my $cb  = sub { $fut->set_result(@_) };
        fiber {
            $got = $fut->await;
            yield;
            return 'done';
        };
        yield;
        $cb->(77);
    };
    is $got, 77, 'callback resumed the parked fiber';
};
#
done_testing();
