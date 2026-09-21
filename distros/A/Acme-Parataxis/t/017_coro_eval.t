use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield];
use Test2::V1 -ipP;
$|++;
#
subtest 'eval and cede inside two fibers' => sub {
    my @order;
    async {
        fiber {
            push @order, 'f1:start';
            my $t = eval '2';
            is $t, 2, 'eval 2 inside fiber 1';
            yield;
            push @order, 'f1:resumed';
            is eval '1/0', U(), '1/0 dies inside fiber 1';
        };
        fiber {
            push @order, 'f2:start';
            my $t = eval '3';
            is $t, 3, 'eval 3 inside fiber 2';
            yield;
            push @order, 'f2:resumed';
            is eval 'die', U(), 'die inside eval inside fiber 2';
        };
    };
    is join( q{ }, @order ), 'f1:start f2:start f1:resumed f2:resumed', 'fibers interleave at each yield';
};
subtest 'die propagates out of a spawned fiber (no eval)' => sub {
    like dies {
        fiber { die 'boom' }
    }, qr/boom/, 'uncaught die escapes spawn';
};
#
done_testing();
