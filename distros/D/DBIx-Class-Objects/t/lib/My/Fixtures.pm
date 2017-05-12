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
    basic_customer => {
        new      => 'Customer',
        using    => { first_purchase => $purchase_date },
        requires => {
            person_with_customer => 'person_id',
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

    all_items => [qw/item_hammer item_screwdriver item_beer/],

    item_beer => {
        new => 'Item',
        using => { name => 'Beer', price => 1.5 },
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

    user => {
	new => 'User',
	using => { username => 'U1' },
	next => [qw/session/],
    },
    session => {
	new => 'Session',
	using => { session_id => 1 },
    },
);

sub get_definition {
    my ( $self, $name ) = @_;
    return $definition_for{$name};
}

sub all_fixture_names { return keys %definition_for }

__PACKAGE__->meta->make_immutable;

1;
