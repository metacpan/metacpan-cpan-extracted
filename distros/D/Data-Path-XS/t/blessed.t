use strict;
use warnings;
use Test::More;
use Test::LeakTrace;
use Scalar::Util qw(blessed);
use Data::Path::XS qw(
    path_get path_set path_delete path_exists
    patha_get patha_set
    path_compile pathc_get pathc_set
);
use Data::Path::XS ':keywords';

# Blessed hash- and array-refs should be navigable as ordinary HV/AV.
# This pins behaviour: the module dispatches on SvTYPE only and does NOT
# go through overload.

package Container::Hash {
    sub new { my ($c, $h) = @_; bless { %$h }, $c }
}
package Container::Array {
    sub new { my ($c, $a) = @_; bless [ @$a ], $c }
}

subtest 'blessed hash navigates as hash' => sub {
    my $obj = Container::Hash->new({ name => 'alice', age => 30 });
    is(blessed $obj, 'Container::Hash', 'sanity: still blessed');

    is(path_get($obj, '/name'),  'alice', 'path_get');
    is(patha_get($obj, ['age']), 30,      'patha_get');
    is(pathc_get($obj, path_compile('/name')), 'alice', 'pathc_get');
    is((pathget $obj, "/age"),   30,      'kw pathget');

    ok(path_exists($obj, '/name'),  'path_exists');
    ok(!path_exists($obj, '/missing'), 'path_exists missing');

    path_set($obj, '/email', 'alice@example.com');
    is($obj->{email}, 'alice@example.com', 'path_set on blessed hash');
    is(blessed $obj, 'Container::Hash', 'remains blessed after set');
};

subtest 'blessed array navigates as array' => sub {
    my $obj = Container::Array->new([10, 20, 30]);
    is(blessed $obj, 'Container::Array', 'sanity: still blessed');

    is(path_get($obj, '/0'),  10, 'path_get [0]');
    is(path_get($obj, '/-1'), 30, 'path_get [-1]');
    is(patha_get($obj, [1]),  20, 'patha_get [1]');

    path_set($obj, '/3', 40);
    is($obj->[3], 40, 'path_set extends array');
    is(blessed $obj, 'Container::Array', 'remains blessed after set');
};

subtest 'nested blessed objects' => sub {
    my $root = Container::Hash->new({
        items  => Container::Array->new([
            Container::Hash->new({ id => 1, name => 'a' }),
            Container::Hash->new({ id => 2, name => 'b' }),
        ]),
    });
    is(path_get($root, '/items/0/name'), 'a', 'deep path through blessed objects');
    is(path_get($root, '/items/1/id'),    2,   'deep path numeric value');
    path_set($root, '/items/0/email', 'a@x');
    is($root->{items}[0]{email}, 'a@x', 'set through blessed chain');
    ok(blessed($root->{items}),    'inner array still blessed');
    ok(blessed($root->{items}[0]), 'inner hash still blessed');
};

subtest 'autovivified intermediate is plain (not blessed)' => sub {
    my $obj = Container::Hash->new({});
    path_set($obj, '/a/b/c', 1);
    is(blessed $obj,            'Container::Hash', 'root stays blessed');
    is(blessed $obj->{a},        undef,            'autoviv intermediate is plain hash');
    is(blessed $obj->{a}{b},     undef,            'deeper autoviv intermediate is plain hash');
    is($obj->{a}{b}{c}, 1, 'value stored');
};

subtest 'no leaks on blessed access' => sub {
    no_leaks_ok {
        my $obj = Container::Hash->new({ k => 'v' });
        path_get($obj, '/k');
        path_set($obj, '/x', 1);
        path_delete($obj, '/x');
    } 'blessed hash get/set/delete';

    no_leaks_ok {
        my $obj = Container::Array->new([1,2,3]);
        path_get($obj, '/0');
        path_set($obj, '/3', 4);
        path_delete($obj, '/3');
    } 'blessed array get/set/delete';
};

done_testing;
