
use strict;
use warnings;

use Test::More tests => 50;                      # last test to print
use Test::Exception;
use Test::NoWarnings;


use_ok( 'Data::ArrayList' );

ok my $dal = Data::ArrayList->new(), "object created";
ok my $dalic = Data::ArrayList->new(10), "new(INITIAL_CAPACITY)";

ok $dal->add('first'), "add(VALUE)";
is $dal->get(0), 'first', "get() returns added value";

throws_ok {
    $dal->get($dal->size)
} qr/IndexOutOfBounds/, 'get() dies with index out of range';

throws_ok {
    $dal->get($dal->size+1)
} qr/IndexOutOfBounds/, 'get() dies with index out of range';

throws_ok {
    $dal->get(-10)
} qr/IndexOutOfBounds/, 'get() dies with index out of range';

throws_ok {
    $dal->add()
} qr/IllegalArgument/, 'add() requires value';

lives_ok {
    $dal->addAt(0, 'second');
} "addAt(INDEX, VALUE)";
is $dal->get(0), 'second', "get() returns added value";
is $dal->get(1), 'first', "addAt(INDEX, VALUE) shifts to right";

throws_ok {
    $dal->addAt(0)
} qr/IllegalArgument/, 'addAt(INDEX, VALUE) requires value';

throws_ok {
    $dal->addAt($dal->size + 1, 'dies')
} qr/IndexOutOfBounds/, 'addAt(INDEX, VALUE) dies with index out of range';

throws_ok {
    $dal->addAt(-10, 'dies')
} qr/IndexOutOfBounds/, 'addAt(INDEX, VALUE) dies with index out of range';

ok $dal->addAll('third', 'fourth'), "addAll(COLLECTION)";
is $dal->get(2), 'third', "addAll(COLLECTION)";

lives_ok {
    $dal->addAllAt(0, 'fifth', 'sixth');
} "addAllAt(INDEX, COLLECTION)";
is $dal->get(0), 'fifth', "get() returns added value";
is $dal->get(1), 'sixth', "get() returns added value";
is $dal->get(2), 'second', "addAllAt(INDEX, COLLECTION) shifts to right";
is $dal->get(3), 'first', "addAllAt(INDEX, COLLECTION) shifts to right";
is $dal->get(4), 'third', "addAllAt(INDEX, COLLECTION) shifts to right";
is $dal->get(5), 'fourth', "addAllAt(INDEX, COLLECTION) shifts to right";

is $dal->size, 6, "size returns true number of elements";

lives_ok {
    $dal->clear();
} "clear()";
ok $dal->isEmpty, "isEmpty()";

$dal->addAll(qw( first second third fourth fifth sixth third ));

ok $dal->contains(sub {/^third$/ }), "third exists in array";
is $dal->indexOf(sub { /^third$/ }), 2, "indexOf()";
is $dal->lastIndexOf(sub { /^third$/ }), 6, "lastIndexOf()";

ok ! $dal->contains(sub { /^seventh$/ }), "seventh does not exist in array";
is $dal->indexOf(sub { /^seventh$/ }), -1, "lastIndexOf() for non-existent";
is $dal->lastIndexOf(sub { /^seventh$/ }), -1, "lastIndexOf() for non-existent";

my $dal2 = $dal->clone();

is_deeply [ $dal->toArray() ],
    [qw( first second third fourth fifth sixth third )],
    "toArray() returns elements from first to last";

is $dal->set(2, 'third again'), 'third', "set()";
is $dal->get(2), 'third again', "get() returns new value";

throws_ok {
    $dal->set($dal->size + 1, 'dies')
} qr/IndexOutOfBounds/, 'set() dies with index out of range';

throws_ok {
    $dal->set()
} qr/IllegalArgument/, 'set() dies when no value passed';

throws_ok {
    $dal->set(-10, 'dies')
} qr/IndexOutOfBounds/, 'set() dies with index out of range';


throws_ok {
    $dal->ensureCapacity()
} qr/IllegalArgument/, 'ensureCapacity() requires argument';

ok $dal->ensureCapacity(20), "ensureCapacity() - expands";

ok ! $dal->ensureCapacity(2), "ensureCapacity() - within size";

is $dal->remove(4), 'fifth', "remove()";
is $dal->get(4), 'sixth', "remove() shifts to left";

throws_ok {
    $dal->remove($dal->size + 1)
} qr/IndexOutOfBounds/, 'remove(INDEX) dies with index out of range';
throws_ok {
    $dal->remove(-10)
} qr/IndexOutOfBounds/, 'remove(INDEX) dies with index out of range';
throws_ok {
    $dal->remove()
} qr/IllegalArgument/, 'remove() requires argument';



ok $dal->clear(), "clear()";
is $dal->size, 0, "clear() resets size";

