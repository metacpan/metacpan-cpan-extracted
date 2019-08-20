#!/usr/bin/env perl
use Test::Roo;
use experimental qw(signatures);

use List::Util qw(sum0);
use Test::Differences qw(eq_or_diff);
use Test::Fatal qw(exception);

use Box::Limited;

has class_name => (
    is      => 'ro',
    default => sub {'Box::Limited'},
);

has box => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_box',
);

sub _build_box ($self) {
    return $self->class_name->new(
        size            => 5,
        max_weight      => 10,
        weight_function => sub (@items) {
            return sum0(@items);
        },
    );
}

before each_test => sub ($self, @) {

    # Rebuild testing box before every test
    $self->box($self->_build_box);
};

test construction => sub ($self) {

    my $box = $self->box;
    ok($box, 'Box created');
    is($box->size,       5,  'Box size is as expected');
    is($box->max_weight, 10, 'Box max_weight is as expected');
    is(ref($box->weight_function), 'CODE',
        'Box weight_function is a coderef');
    ok($box->is_empty, 'Box is initially empty');
    is($box->items_count, 0, '...and contains 0 items');
};

test can_add => sub ($self) {
    my $box = $self->box;
    ok($box->can_add(9),
        'Element with weight smaller than max_weight can be added');
    ok($box->can_add(10),
        'Element with weight equal to max_weight can be added');
    ok(!$box->can_add(11),
        'Element with weight higher than max_weight cannot be added');
};

test add => sub ($self) {
    my $box = $self->box;
    ok(exception { $box->add(11) },
        'Attempt to add too big item raises an exception');
    ok($box->add(9), 'Smaller item was added though');
    is($box->items_count, 1, 'Items count was updated');
    ok(!$box->is_empty, 'Box is not empty anymore');
    ok( exception {
            $box->add(2);
        },
        'Attempt to add another big item raises an exception'
    );
    ok($box->add(1), '...but we can add smaller one');
    is($box->items_count, 2, 'Box now contains 2 items');
    ok($box->clear,    'Clear the box');
    ok($box->is_empty, 'Box is now empty');
    is($box->items_count, 0, '...and contains 0 items');

    # Prepare a box with maximum allowed count of items
    $box->add(1) for 1 .. 5;
    ok(!$box->can_add(1),
        'Cannot add item to the box with a maximum count of items');
    ok(exception { $box->add(1), }, '...trying to do so raises exception');
};

test split_to_boxes => sub ($self) {
    my $class                   = $self->class_name;
    my %default_constructor_arg = (
        size            => 10,
        max_weight      => 3,
        weight_function => sub (@items) {
            return sum0(@items);
        },
    );
    my @boxes = $class->split_to_boxes(\%default_constructor_arg, (1 .. 3));
    is(scalar @boxes, 2, 'Items were split to 2 boxes');
    eq_or_diff(
        [ $boxes[0]->items ],
        [ 1, 2 ],
        'First two items are in the first box'
    );
    eq_or_diff([ $boxes[1]->items ], [3],
        '...and third is in the second one');

    # 3 boxes, one item per box
    @boxes = $class->split_to_boxes({ %default_constructor_arg, size => 1 },
        (1 .. 3));
    is(scalar @boxes, 3, '3 items were split to 3 1-slot boxes');

    # 1 box with all the items in it
    @boxes
      = $class->split_to_boxes({ %default_constructor_arg, max_weight => 60 },
        (1 .. 10));
    is(scalar @boxes, 1, '10 items were placed into the same box');
    is($boxes[0]->items_count,
        10, '...which reports that it contains 10 items');
};

run_me;
done_testing;
