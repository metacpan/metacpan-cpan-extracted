use strict;
use warnings;

use Test::More tests => 142;
use Test::Exception;
use Test::NoWarnings;

use lib qw( t/lib );

use Scalar::Util qw(refaddr);
use Test::Data::ArrayList::Class;

use_ok( 'Data::ArrayList' );

ok my $dal = Data::ArrayList->new(), "object created";
$dal->addAll(qw( first second third fourth fifth sixth ));

throws_ok {
    $dal->subList()
} qr/IllegalArgument/, "subList() requires 2 arguments";

throws_ok {
    $dal->subList(1)
} qr/IllegalArgument/, "subList() requires 2 arguments";

throws_ok {
    $dal->subList(0, $dal->size + 1)
} qr/IndexOutOfBounds/, "subList() fails for range out of bounds";

ok my $sl1 = $dal->subList( 1, 4 ), "subList() returns list view";

is $sl1->size, 3, "size() returns correct number of elements";


ok my $sl1_li = $sl1->listIterator(), "subList() supports listIterator()";


my $expected_next_index = 0;
my @expected_elem = qw(
    second third fourth
);
while ( $sl1_li->hasNext ) {
    my $index = $sl1_li->nextIndex;
    is $index, $expected_next_index++, "nextIndex() returns expected $index";
    is $sl1_li->next, $expected_elem[$expected_next_index-1],
        "next() returns correct element: ". $sl1->get($index);
}
is $sl1_li->nextIndex, $sl1->size,
    "nextIndex() returns size() when cursor at the end";

throws_ok {
    $sl1_li->next
} qr/NoSuchElement/, "next() reached the end";

my $expected_prev_index = 2;
while ( $sl1_li->hasPrevious ) {
    my $index = $sl1_li->previousIndex;
    is $index, $expected_prev_index--, "previousIndex() returns expected $index";
    is $sl1_li->previous, $expected_elem[$expected_prev_index+1],
        "previous() returns correct element: ". $sl1->get($index);
}
is $sl1_li->previousIndex, -1,
    "previousIndex() returns -1 when cursor at the begining";

throws_ok {
    $sl1_li->previous
} qr/NoSuchElement/, "previous() already at begining";

my $prev_al_size = $dal->size();
my $prev_sl1_size = $sl1->size();

$sl1->add("added in sublist");

is $sl1->get( $sl1->size - 1 ), "added in sublist",
    "add() adds at the end of sublist";

is $dal->size, $prev_al_size + 1, "size() increases for parent list";
is $sl1->size, $prev_sl1_size + 1, "size() increases for sub list";

my $sl11 = $sl1->subList(0, 2);


ok my $sl11_li = $sl11->listIterator(), "listIterator() available for sublists";

$expected_next_index = 0;
delete $expected_elem[2];
while ( $sl11_li->hasNext ) {
    my $index = $sl11_li->nextIndex;
    is $index, $expected_next_index++, "nextIndex() returns expected $index";
    is $sl11_li->next, $expected_elem[$expected_next_index-1],
        "next() returns correct element: ". $sl11->get($index);
}

is $sl11->indexOf(sub {/^third$/}), 1,
    "indexOf() returns index relative to the sublist";

$sl11->clear();

$dal->add("at the end");

throws_ok {
    $sl1->add("ConcurrentModification");
} qr/ConcurrentModification/, "add() in sublist checks if parent modified";

throws_ok {
    $sl1->addAt(0, "ConcurrentModification");
} qr/ConcurrentModification/, "addAt() in sublist checks if parent modified";

throws_ok {
    $sl1->get(0);
} qr/ConcurrentModification/, "get() in sublist checks if parent modified";

throws_ok {
    $sl1->clear();
} qr/ConcurrentModification/, "clear() in sublist checks if parent modified";

throws_ok {
    $sl1->toArray();
} qr/ConcurrentModification/, "toArray() in sublist checks if parent modified";

throws_ok {
    $sl1->ensureCapacity(100);
} qr/UnsupportedOperationException/, "ensureCapacity() fails for sublist";

throws_ok {
    $sl1->remove(0);
} qr/ConcurrentModification/, "remove() in sublist checks if parent modified";

throws_ok {
    $sl1->set(0, "dies");
} qr/ConcurrentModification/, "set() in sublist checks if parent modified";

throws_ok {
    $sl1->subList(0,1);
} qr/ConcurrentModification/, "subList() in sublist checks if parent modified";





$dal->clear();
$dal->addAll(qw( first second third fourth fifth sixth ));

sub get_subList {
    my ($list, $rangeFrom, $rangeTo) = @_;

    return $list->subList($rangeFrom, $rangeTo);
}
my $_cur_list = $dal;
my $_cur_size = $_cur_list->size;
@expected_elem = qw( second third fourth fifth sixth );
while ( $_cur_list->size > 1 ) {
    my $sl = get_subList($_cur_list, 1, $_cur_list->size);
    is $sl->size, --$_cur_size, "recursive subList() size is correct: $_cur_size";
    my ($superclass) = $sl->meta->superclasses;
    is $superclass, "Data::ArrayList", "subList() extends Data::ArrayList";
    my $li = $sl->listIterator;
    my $expected_next_index = 0;
    while ( $li->hasNext ) {
        my $index = $li->nextIndex;
        is $index, $expected_next_index++, "nextIndex() returns expected $index";
        is $li->next, $expected_elem[$expected_next_index-1],
            "next() returns correct element: ". $sl->get($index);
    }
    $_cur_list = $sl;
    shift @expected_elem;
}

$dal->subList(1, 5)->subList(1, 4)->subList(1, 3)->add('added before last element');
is $dal->get( $dal->size - 2), "added before last element",
    "nested sublist added element at correct index";

{
    my $sl151413 = $dal->subList(1, 5)->subList(1, 4)->subList(1, 3);

    is $sl151413->size, 2, "nested sublist size is correct: 2";

    my $li = $sl151413->listIterator;
    my @expected_elem = qw( fourth fifth );
    my $expected_next_index = 0;

    while ( $li->hasNext ) {
        my $index = $li->nextIndex;
        is $index, $expected_next_index++, "nextIndex() returns expected $index";
        is $li->next, $expected_elem[$expected_next_index-1],
            "next() returns correct element: ". $sl151413->get($index);
    }

    my $dal_size_b_clear = $dal->size;

    $sl151413->clear();

    my @dal = $dal->toArray;

    is $dal->size, $dal_size_b_clear - 2,
        "parent size decreased by sublist size";

    throws_ok {
        $sl151413->addAt(0)
    } qr/IllegalArgument/, 'addAt(INDEX, VALUE) requires value';

    throws_ok {
        $sl151413->addAt($sl151413->size + 1, 'dies')
    } qr/IndexOutOfBounds/, 'addAt(INDEX, VALUE) dies with index out of range';

    throws_ok {
        $sl151413->addAt(-10, 'dies')
    } qr/IndexOutOfBounds/, 'addAt(INDEX, VALUE) dies with index out of range';

    $sl151413->addAll("fourth restored", "fifth restored");

    throws_ok {
        $sl151413->get($sl151413->size + 1)
    } qr/IndexOutOfBounds/, 'get() dies with index out of range';

    throws_ok {
        $sl151413->get(-10)
    } qr/IndexOutOfBounds/, 'get() dies with index out of range';

    throws_ok {
        $sl151413->remove($sl151413->size + 1)
    } qr/IndexOutOfBounds/, 'remove() dies with index out of range';

    throws_ok {
        $sl151413->remove()
    } qr/IllegalArgument/, 'remove() requires argument';


    $li = $sl151413->listIterator;
    @expected_elem = ("fourth restored", "fifth restored");
    $expected_next_index = 0;
    while ( $li->hasNext ) {
        my $index = $li->nextIndex;
        is $index, $expected_next_index++, "nextIndex() returns expected $index";
        is $li->next, $expected_elem[$expected_next_index-1],
            "next() returns correct element: ". $sl151413->get($index);
    }


    throws_ok {
        $sl151413->set($sl151413->size + 1, 'dies')
    } qr/IndexOutOfBounds/, 'set() dies with index out of range';

    throws_ok {
        $sl151413->set()
    } qr/IllegalArgument/, 'set() dies when no value passed';

    throws_ok {
        $sl151413->set(-10, 'dies')
    } qr/IndexOutOfBounds/, 'set() dies with index out of range';


    $sl151413->set(0, "fourth restored via set");
    $sl151413->set(1, "fifth restored via set");

    $li = $sl151413->listIterator;
    @expected_elem = ("fourth restored via set", "fifth restored via set");
    $expected_next_index = 0;
    while ( $li->hasNext ) {
        my $index = $li->nextIndex;
        is $index, 0, "nextIndex() returns expected $index";
        is $li->next, $expected_elem[$expected_next_index++],
            "next() returns correct element: ". $sl151413->get($index);

        ok $li->remove, "iterator removes last element correctly";
    }


    is_deeply [ $dal->toArray ], [ @dal ], "iterator removes sublists elements";
}

my $dalO = Data::ArrayList->new();
for ( 1 .. 5 ) {
    $dalO->add( Test::Data::ArrayList::Class->new( idx => $_ - 1 ) );
}


my $sldalO = $dalO->subList(2,5);

is $sldalO->size, 3, "sublist() has correct size";

my @sldalOcl = $sldalO->toArray;
my $i = 0;
for (@sldalOcl) {
    isnt refaddr $_, refaddr $dalO->get($_->idx),
        "blessed object cloned for parent";
    isnt refaddr $_, refaddr $sldalO->get($i),
        "blessed object cloned for sublist";

    isnt refaddr $_->store, refaddr $dalO->get($_->idx)->store,
        "blessed object cloned with attributes for parent";
    isnt refaddr $_->store, refaddr $sldalO->get($i)->store,
        "blessed object cloned with attributes for sublist";

    $i++;
}

throws_ok {
    $sldalO->subList(0,10)
} qr/IndexOutOfBounds/, 'nested subList() dies with index out of range';


my $sl1dalO = $sldalO->subList(0,2);

ok $sldalO->add("simple mod"), "subList modified";

throws_ok {
    $sl1dalO->add("ConcurrentModification");
} qr/ConcurrentModification/, "add() in nested sublist checks if parent modified";

throws_ok {
    $sl1dalO->addAt(0, "ConcurrentModification");
} qr/ConcurrentModification/, "addAt() in nested sublist checks if parent modified";

throws_ok {
    $sl1dalO->get(0);
} qr/ConcurrentModification/, "get() in nested sublist checks if parent modified";

throws_ok {
    $sl1dalO->clear();
} qr/ConcurrentModification/, "clear() in nested sublist checks if parent modified";

throws_ok {
    $sl1dalO->toArray();
} qr/ConcurrentModification/, "toArray() in nested sublist checks if parent modified";

throws_ok {
    $sl1dalO->ensureCapacity(100);
} qr/UnsupportedOperationException/, "ensureCapacity() fails for nested sublist";

throws_ok {
    $sl1dalO->remove(0);
} qr/ConcurrentModification/, "remove() in nested sublist checks if parent modified";

throws_ok {
    $sl1dalO->set(0, "dies");
} qr/ConcurrentModification/, "set() in nested sublist checks if parent modified";

throws_ok {
    $sl1dalO->subList(0,1);
} qr/ConcurrentModification/, "subList() in nested sublist checks if parent modified";

throws_ok {
    $sl1dalO->remove()
} qr/IllegalArgument/, 'remove() in nested sublist requires argument';


ok $dalO->clear(), "parent list cleared";

throws_ok {
    $sldalO->clear;
} qr/ConcurrentModification/, "subList() in sublist checks if parent modified";


$dal->clear();

{
    $dal->addAll(qw( first second third fourth fifth sixth ));

    my $sl = $dal->subList(1,4);

    ok my $slli = $sl->listIterator(), "listIterator() available for sublist";
    while ( $slli->hasNext() ) {
        $slli->add( $slli->next . " via iterator" );
    }

    for my $i (1,3,5) {
        is $dal->get($i) . " via iterator", $dal->get($i+1),
            "elements added by iterator are next to original ones";
    }

    $sl->add("added in sublist");

    throws_ok {
        $slli->previous
    } qr/ConcurrentModification/, "iterator's previous() checks if parent modified";

    throws_ok {
        $slli->next
    } qr/ConcurrentModification/, "iterator's next() checks if parent modified";

    throws_ok {
        $slli->remove
    } qr/ConcurrentModification/, "iterator's remove() checks if parent modified";

    throws_ok {
        $slli->add("dies")
    } qr/ConcurrentModification/, "iterator's add() checks if parent modified";

}
