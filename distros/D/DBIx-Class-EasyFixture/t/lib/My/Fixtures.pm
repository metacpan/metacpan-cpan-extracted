package My::Fixtures;
use Moose;
use DateTime;
use namespace::autoclean;
extends 'DBIx::Class::EasyFixture';

my $birthday = DateTime->new(
    year  => 1983,
    month => 2,
    day   => 12,
);
my $purchase_date = DateTime->new(
    year  => 2011,
    month => 12,
    day   => 23,
);

my %definition_for = (
    all_people => [qw/person_without_customer person_with_customer/],
    person_without_customer => {
        new   => 'Person',
        using => {
            name     => 'Bob',
            email    => 'not@home.com',
            birthday => $birthday,
        },
    },

    # these next three are related (person_with_customer, basic_customer,
    # order_without_items)
    person_with_customer => {
        new   => 'Person',
        using => {
            name     => "sally",
            email    => 'person@customer.com',
            birthday => $birthday,
        },
        next => [qw/basic_customer/],
    },
    person_with_customer_2 => {
        new   => 'Person',
        using => {
            name     => "sally",
            email    => 'person2@customer.com',
            birthday => $birthday,
        },
        next => [qw/basic_customer/],
    },
    person_with_customer_3 => {
        new   => 'Person',
        using => {
            name     => "sally",
            email    => 'person3@customer.com',
            birthday => $birthday,
        },
        next => [qw/basic_customer/],
    },
    person_with_customer_4 => {
        new   => 'Person',
        using => {
            name     => "sally",
            email    => 'person4@customer.com',
            birthday => $birthday,
        },
        next => [qw/basic_customer/],
    },
    basic_customer => {
        new      => 'Customer',
        using    => { first_purchase => $purchase_date },
        requires => {
            person_with_customer => 'person_id',
        },
    },
    customer_inline_require_hashref => {
        new   => 'Customer',
        using => {
            first_purchase => $purchase_date,
            person_id      => { person_with_customer_2 => 'person_id' },
        },
    },
    customer_inline_require_arrayref => {
        new   => 'Customer',
        using => {
            first_purchase => $purchase_date,
            person_id      => [ person_with_customer_3 => 'person_id' ],
        },
    },
    customer_inline_require_scalar => {
        new   => 'Customer',
        using => {
            first_purchase => $purchase_date,
            person_id      => \'person_with_customer_4',
        },
    },
    order_without_items => {
        new      => 'Order',
        using    => { order_date => $purchase_date },
        requires => {

            # this is the same as
            # basic_customer => 'customer_id'
            basic_customer => {
                our   => 'customer_id',
                their => 'customer_id',
            }
        },
    },
    second_order_without_items => {
        new      => 'Order',
        using    => { order_date => $purchase_date },
        requires => {
            basic_customer => 'customer_id',
        },
    },

    # create an order with two items on it
    item_hammer => {
        new   => 'Item',
        using => { name => "Hammer", price => 1.2 },
    },
    item_screwdriver => {
        new   => 'Item',
        using => { name => "Screwdriver", price => 1.4 },
    },

    order_item_hammer => {
        new      => 'OrderItem',
        using    => { price => 1.2 },
        requires => {
            item_hammer      => 'item_id',
            order_with_items => 'order_id',
        },
    },
    order_item_screwdriver => {
        new      => 'OrderItem',
        using    => { price => .7 },
        requires => {
            item_screwdriver => 'item_id',
            order_with_items => 'order_id',
        },
    },
    order_with_items => {
        new      => 'Order',
        using    => { order_date => $purchase_date },
        requires => {

            # showing expanded version because we use this for testing.
            basic_customer => {
                our   => 'customer_id',
                their => 'customer_id',
            },
        },
        next => [qw/order_item_hammer order_item_screwdriver/],
    },

    # these next four items are designed to uncover a bug whereby one
    # can't chain multiple fixtures via next.
    item_1 => {
        new   => 'Item',
        using => { name => "Chain 1", price => 1 },
        next  => [qw/item_2/],
    },
    item_2 => {
        new   => 'Item',
        using => { name => "Chain 2", price => 2 },
        next  => [qw/item_3/],
    },
    item_3 => {
        new   => 'Item',
        using => { name => "Chain 3", price => 3 },
        next  => [qw/item_4/],
    },
    item_4 => {
        new   => 'Item',
        using => { name => "Chain 4", price => 4 },
        next  => [qw/item_1/], # deliberate circular definition
    },

    # these next two items are related, and designed to cover
    # a scenario wherein two entities have a bi-directional relationship
    producer => {
        new => 'Person',
        using => { name => 'Rick Rubin', birthday => $birthday },
        requires => {
            album => {
                our => 'favorite_album_id',
                their => 'album_id',
                deferred => 1,
            },
        },
    },
    album => {
        new => 'Album',
        using => { name => 'La Futura' },
        requires => {
            producer => {
                our => 'producer_id',
                their => 'person_id',
                deferred => 1,
            },
        },
    },
);

sub get_definition {
    my ( $self, $name ) = @_;
    return $definition_for{$name};
}

sub all_fixture_names { return keys %definition_for }

__PACKAGE__->meta->make_immutable;

1;
