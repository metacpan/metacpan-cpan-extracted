use Test::More;
use Test::Deep qw/cmp_bag/;
use Data::Perl;

use strict;

use Scalar::Util qw/refaddr/;

# thanks to Mojo::Collection for skeleton test
is ref(hash('a',1,'b',2)), 'Data::Perl::Collection::Hash', 'constructor shortcut works';

# hash
is hash('a', 1, 'b', 2)->{'b'}, 2, 'right result';
is_deeply {%{hash(a => 1, b => 2)}}, { a=>1, b=>2 }, 'right result';

# set
my $h = Data::Perl::Collection::Hash->new(a=>1);
$h->set(d=>5,e=>6);
is_deeply $h, {a=>1,d=>5,e=>6}, 'set many right result';
my ($obj) = $h->set(x=>5,y=>6);
is_deeply $obj, [5,6], 'set many right result in list context';

$h = hash(b=>3);
$h->set(d=>5);
is_deeply $h, {d=>5,b=>3}, 'set right result';

my ($results) = $h->set(d=>5, b => 3, e => 6);
is_deeply $results, [5,3,6], 'set list context works';
# get
is hash(a => 1, b => 2)->get('b'), 2, 'get right result';
is_deeply [hash(a => 1, b => 2)->get(qw/a b c/)->all], [1, 2, undef ], 'get many right result';

# delete
$h = hash(qw/b 3 a 1 c 2 d 3 e 4 y 5 u 7/);
is_deeply $h->delete(qw/b/)->all, 3, 'delete returned right result';
is_deeply $h, {qw/a 1 c 2 d 3 e 4 y 5 u 7/}, 'delete right result';

is_deeply [$h->delete(qw/4444/)->all], [undef], 'delete returned right result';

($results) = $h->delete(qw/a c d e y u/);
is_deeply $results, [qw/1 2 3 4 5 7/], 'delete right result';
is_deeply $h, {}, 'delete right result';

# keys
$h = hash(a=>1,b=>2,c=>3);
is_deeply [sort $h->keys->all], [qw/a b c/], 'keys works';

# exists
ok $h->exists('a'), 'exists ok';
ok !$h->exists('r'), 'exists fails ok';
$h->set('a'=>undef);
ok $h->exists('a'), 'exists on undef ok';

# defined
$h = hash(a=>1);
ok $h->defined('a'), 'defined ok';
ok !$h->defined('x'), 'defined not ok on undef';

# values
$h = hash(a=>1,b=>2);
is_deeply [sort $h->values->all], [1,2], 'values ok';

# kv
cmp_bag [$h->kv->all], [[qw/a 1/], [qw/b 2/]], 'kv works';

# elements
is_deeply [sort $h->all], [ qw/1 2 a b/], 'all elements works';

#  clear
$h = hash(a=>1,b=>2);
my $old_addr = refaddr($h);
$h->clear;
is_deeply {%{$h}}, {}, 'clear works';
is refaddr($h), $old_addr, 'refaddr matches on clear';

# count/is_empty
is $h->count, 0, 'empty count works';
is $h->is_empty, 1, 'is empty works';
$h = hash(a=>1,b=>2);
is $h->count, 2, 'count works';
is $h->is_empty, 0, 'is empty works';

# accessor
$h = hash(a=>1,b=>2);
is $h->accessor('a'), 1, 'accessor get works';
is $h->accessor('a', '4'), 4, 'accessor set works';

is $h->accessor('r'), undef, 'accessor get on undef works';
is $h->accessor('r', '5'), 5, 'accessor set on undef works';

is $h->accessor(), '', 'no arg accessor get returning undef works';

# shallow_clone
$h = hash(a=>1,b=>2);
my $foo = $h->shallow_clone;
cmp_bag [$h->kv->all], [[qw/a 1/], [qw/b 2/]], 'shallow clone is a clone';
isnt refaddr($h), refaddr($foo), 'refaddr doesnt match on clone';

# shallow_clone as a class method
$foo = Data::Perl::Collection::Hash::shallow_clone({1=>2,3=>4});
is_deeply($foo, {1,2,3,4}, 'shallow clone is a clone as a class method');

done_testing();
