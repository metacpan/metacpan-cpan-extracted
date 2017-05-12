
use strict;
use warnings;

use Test::More tests => 76;
use Test::Exception;
use Test::NoWarnings;


use_ok( 'Data::ArrayList' );

ok my $dal = Data::ArrayList->new(), "object created";
$dal->addAll(qw( first second third fourth fifth sixth ));

ok my $dal_iter = $dal->listIterator(), "iterator received";

ok $dal_iter->hasNext, "hasNext()";
is $dal_iter->nextIndex, 0, "nextIndex()";

is $dal_iter->next, 'first', 'next()';

ok $dal_iter->hasPrevious, "hasPrevious()";
is $dal_iter->previousIndex, 0, "previousIndex()";

is $dal_iter->previous, 'first', 'previous()';

my $expected_next_index = 0;
while ( $dal_iter->hasNext ) {
    my $index = $dal_iter->nextIndex;
    is $index, $expected_next_index++, "nextIndex() returns expected $index";
    is $dal_iter->next, $dal->get($index),
        "next() returns correct element";
}
is $dal_iter->nextIndex, $dal->size,
    "nextIndex() returns size() when cursor at the end";

throws_ok {
    $dal_iter->next
} qr/NoSuchElement/, "next() reached the end";


my $expected_prev_index = 5;
while ( $dal_iter->hasPrevious ) {
    my $index = $dal_iter->previousIndex;
    is $index, $expected_prev_index--, "previousIndex() returns expected $index";
    is $dal_iter->previous, $dal->get($index),
        "previous() returns correct element";
}
is $dal_iter->previousIndex, -1,
    "previousIndex() returns -1 when cursor at the begining";

throws_ok {
    $dal_iter->previous
} qr/NoSuchElement/, "previous() already at begining";

$dal->add("seventh");

throws_ok {
    $dal_iter->next;
} qr/ConcurrentModification/, "next() won't work if list was modified";

ok my $dal_iter2 = $dal->listIterator(), "second iterator received";

throws_ok {
    $dal_iter2->add();
} qr/IllegalArgument/, "add() requires value";

throws_ok {
    $dal_iter2->remove();
} qr/IllegalState/, "remove() cannot be called before next()/previous()";

is $dal_iter2->nextIndex, 0, "nextIndex()";
is $dal_iter2->next, 'first', 'next()';

throws_ok {
    $dal_iter->next;
} qr/ConcurrentModification/, "next() still doesn't work for first iterator";

lives_ok {
    $dal_iter2->remove();
} "remove() removes the last element returned";

throws_ok {
    $dal_iter2->remove();
} qr/IllegalState/, "remove() cannot be called twice in a row";

$dal_iter2->add("added before second");
is $dal_iter2->next, 'second', 'next()';

is $dal_iter2->next, 'third', 'next()';
$dal_iter2->add("added after third");

$dal->add("eight");


throws_ok {
    $dal_iter2->previous;
} qr/ConcurrentModification/, "previous() won't work if list was modified";

ok my $dal_iter3 = $dal->listIterator(3), "listIterator(POSITION) received";

is $dal_iter3->previous, "third", "previous() moves to one position back";
is $dal_iter3->next, "third", "next() moves to initial position";

lives_ok {
    $dal_iter3->add("added at position 3");
} "add() works for positioned iterators";

is $dal->get(3), "added at position 3",
    "iterator's add() adds at correct position";


throws_ok {
    $dal->listIterator($dal->size)
} qr/IndexOutOfBounds/, 'listIterator() dies with index out of range';

my $dal_iter4 = $dal->listIterator;

my @expected_elements = ();
while ( $dal_iter4->hasNext ) {
    my $elem = $dal_iter4->next;

    unshift @expected_elements, $elem;

    ok $dal_iter4->set( "* $elem *" ), "set() sets";
}
while ( $dal_iter4->hasPrevious ) {
    my $elem = $dal_iter4->previous;

    my $expected = "* ". shift(@expected_elements) ." *";
    is $expected, $elem, "set() replaces elements";
}
