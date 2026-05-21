use strict;
use warnings;
use Test::More;
use Test::LeakTrace;
use Scalar::Util qw(weaken isweak);
use Data::Path::XS qw(
    path_get path_set path_delete path_exists
    patha_get patha_set
);

# Behaviour around interesting Perl reference shapes.

subtest 'cyclic references — get returns the cycle, no infinite loop' => sub {
    my $d = { name => 'root' };
    $d->{self} = $d;          # cycle
    is(path_get($d, '/self/name'),         'root', 'one hop through cycle');
    is(path_get($d, '/self/self/name'),    'root', 'two hops through cycle');
    is(path_get($d, '/self/self/self/name'), 'root', 'three hops through cycle');
    ok(path_exists($d, '/self/self/self/self'), 'exists through cycle');

    # Break the cycle to avoid leak warning at scope exit
    delete $d->{self};
};

subtest 'weak references propagate as the underlying ref' => sub {
    my $target = { val => 42 };
    my $d = { weak => $target };
    weaken $d->{weak};
    ok(isweak($d->{weak}), 'sanity: weak flag set');

    is(path_get($d, '/weak/val'), 42, 'path_get follows weak ref');
    # path_get must NOT strengthen the ref
    ok(isweak($d->{weak}), 'weak flag preserved after path_get');
};

subtest 'scalar refs as values are passthrough' => sub {
    my $scalar = 'hello';
    my $d = { ref => \$scalar };
    my $got = path_get($d, '/ref');
    is(ref $got, 'SCALAR', 'returned scalar-ref');
    is($$got, 'hello', 'dereferences to original value');

    # Scalar-ref intermediate cannot be navigated further
    is(path_get($d, '/ref/anything'), undef, 'scalar-ref intermediate stops navigation');
};

subtest 'code refs as values are passthrough' => sub {
    my $cb = sub { 7 };
    my $d = { fn => $cb };
    my $got = path_get($d, '/fn');
    is(ref $got, 'CODE', 'returned code-ref');
    is($got->(), 7, 'invokable');
};

subtest 'storing a ref shares it (not a copy)' => sub {
    my $payload = { id => 1 };
    my $d = {};
    path_set($d, '/owned', $payload);
    is($d->{owned}, $payload, 'same address — ref is shared, not deep-copied');
    $payload->{id} = 99;
    is($d->{owned}{id}, 99, 'mutation visible through stored ref');
};

subtest 'storing a non-ref scalar copies' => sub {
    my $s = 'before';
    my $d = {};
    path_set($d, '/x', $s);
    $s = 'after';
    is($d->{x}, 'before', 'scalar was copied at store time');
};

subtest 'no leaks on cycle traversal' => sub {
    no_leaks_ok {
        my $d = { name => 'r' };
        $d->{self} = $d;
        path_get($d, '/self/self/name');
        path_exists($d, '/self/self/self');
        delete $d->{self};
    } 'cycle traversal';
};

done_testing;
