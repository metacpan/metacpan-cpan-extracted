package DBIx::Class::EasyFixture::Tutorial;
$DBIx::Class::EasyFixture::Tutorial::VERSION = '0.12';
# ABSTRACT: what it says on the tin

# this is not a .pod file because various repos replace the primary
# documentation with a .pod file.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::EasyFixture::Tutorial - what it says on the tin

=head1 VERSION

version 0.12

=head1 RATIONALE

Managing test data is hard enough without having a clean way of maintaining
fixtures. L<DBIx::Class::EasyFixture> makes it easy to define fixtures.
Different scenarios can be loaded on demand to test different facets of your
system. Fixtures can take a while to write, but once defined, there's less
cutting and pasting of code.

=head1 CREATING YOUR FIXTURE CLASS

To use C<DBIx::Class::EasyFixture>, you must first create a subclass of it.
It's required to define two methods: C<get_fixture> and C<all_fixture_names>.
You may implement those any way you wish and you're not locked into a
particular format. Here's one way to do it, using a big hash (there are plenty
of other ways to do this, but this is easy for a tutorial.

    package My::Fixtures;
    use Moose;
    extends 'DBIx::Class::EasyFixture';

    my %definition_for = (
        # keys are fixture names, values are the fixture definitions
    );

    sub get_definition {
        my ( $self, $name ) = @_;
        return $definition_for{$name};
    }

    sub all_fixture_names { return keys %definition_for }

    __PACKAGE__->meta->make_immutable;

    1;

=head2 A stand-alone fixture

Writing fixtures is easy, so let's start with something simple.

Imagine you have the following table:

    CREATE TABLE people (
        person_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name      VARCHAR(255) NOT NULL,
        email     VARCHAR(255)     NULL UNIQUE,
        birthday  DATETIME     NOT NULL
    );

Its C<DBIx::Class> definition might look like this:

    package Sample::Schema::Result::Person;
    use strict;
    use warnings;
    use base 'DBIx::Class::Core';
    __PACKAGE__->load_components("InflateColumn::DateTime");

    __PACKAGE__->table("people");

    __PACKAGE__->add_columns(
        "person_id",
        { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
        "name",
        { data_type => "varchar", is_nullable => 0, size => 255 },
        "email",
        { data_type => "varchar", is_nullable => 1, size => 255 },
        "birthday",
        { data_type => "datetime", is_nullable => 0 },
    );

    __PACKAGE__->set_primary_key("person_id");
    __PACKAGE__->add_unique_constraint( "email_unique", ["email"] );

    1;

(After this, we won't show much of the C<DBIx::Class> code).

To define a fixture with a birthday, the email C<not@home.com> and the name
C<bob>, you might have this:

    basic_person => {
        new   => 'Person',
        using => {
            name     => 'Bob',
            email    => 'not@home.com',
            birthday => $datetime_object,
        },
    }

The format of simple fixture is:

    $fixture_name => {
        new   => $dbix_class_resultsource_name,
        using => $arguments_to_constructor,
    }

Putting the above together, we get this:

    package My::Fixtures;
    use Moose;
    use DateTime;
    extends 'DBIx::Class::EasyFixture';
    use namespace::autoclean;

    my %definition_for = (
        basic_person => {
            new   => 'Person',
            using => {
                name     => 'Bob',
                email    => 'not@home.com',
                birthday => DateTime->new(
                    year  => 1983,
                    month => 12,
                    day   => 25,
                ),
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

To use that in your test code:

    use Test::More;
    use My::Schema;
    my $schema = My::Schema->new;

    use My::Fixtures;
    my $fixtures = My::Fixtures->new( { schema => $schema } );
    $fixtures->load('basic_person');

    my $person = $schema->resultset('Person')->find( { email => 'not@home.com' } );
    is $person->name 'bob', 'Everything is OK. We found bob';

    $fixtures->unload; # fixtures removed (transaction is rolled back)

    done_testing;

As a convenience, you can also get "bob" by doing this:

    $fixtures->load('basic_person');
    my $person = $fixtures->get_result('basic_person');

Or by doing this:

    my $person = $fixtures->load('basic_person');

=head2 One-to-one relationships

OK, that was easy, but what about this?

    CREATE TABLE customers (
        customer_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id      INTEGER  NOT NULL UNIQUE,
        first_purchase DATETIME NOT NULL,
        FOREIGN KEY(person_id) REFERENCES people(person_id)
    );

The C<customers> table has a unique constraint against C<person_id>. That
means each person might be a customer in a one-to-one relation (to be fair,
one-to-one relationships are merely a special case of one-to-many
relationships and works the same way in this module). We can turn 'bob' into a
customer by adding a new fixture, but for this example, 'bob' won't be a
customer. Instead, we'll create a separate person, 'sally', and make them a
customer:

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
        using    => {
            first_purchase => $datetime_object,
            person_id      => { person_with_customer => 'person_id' },
        },
    },

=head3 C<next>

If you have a C<next> key in your fixture definition, it takes an array
reference of fixture names and tells us to load those fixtures I<after> the
current one.

=head3 C<requires>

If you have a C<requires> key, it takes a hash refence. They keys are fixtures
to be loaded I<before> the current fixture. The values are hash references of
attribute mappings. The C<our> key is our attribute name and the C<their> key
is the required fixture's method name. The required fixture(s) is loaded and
the C<their> method is called. The resulting value is passed to the C<using>
attribute of the fixture you're loading.

For example, for the C<basic_customer>, we have to have a C<person_id>. The
C<requires> section says "load the C<person_with_customer> fixture". Then, if
the C<person_with_customer.person_id> is 3, the C<basic_customer>'s C<using>
block effectively becomes this:

    using => {
        first_purchase => $datetime_object,
        person_id      => 3,
    }

That allows you to create your fixture correctly since the
C<customer.person_id> is required.

As a short-cut, if C<our> attribute name is the same as C<their> attribute
name, you can just do this:

    requires => {
        person_with_customer => 'person_id',
    }

The reason the C<our> and C<their> are separate is because many people just
use a primary key name of C<id>. This let's you do this:

    requires => {
        person_with_customer => {
            our   => 'person_id',
            their => 'id',
        }
    }

Naturally, you can supply multiple "required" objects.

If the "required" objects don't have attribute values that need to be passed
to the current object, they should probably be passed in the C<next> parameter
instead.

If all of that for the C<requires> section seems complicated, just forget
about it. We also let you do this:

    {
        new      => 'Customer',
        using    => {
            first_purchase => $datetime_object,
            person_id      => { some_person => 'id' },
        },
    }

In other words, if the value of a C<using> attribute is a hashref, we assume
that the single key is the name of another fixture and we using that fixture's
attribute to populate the current fixture's attribute. Internally, it's
converted to a C<requires> block, but you don't need to know about that.

If both the current fixture and the other fixture it requires have the same
name for the attribute, a reference to the other fixture name (scalar
reference) will suffice:

    an_order_item => {
        new => 'OrderItem',
        using => {
            price    => $some_price,
            order_id => \'basic_order',
            item_id  => \'item_screwdriver',
        },
    }

In the above example, we have a fixture named C<an_order_item> that will
create a new C<OrderItem> object and its C<order_id> will be the C<order_id>
from the C<basic_order> fixture and the C<item_id> will be the C<item_id> from
the C<item_screwdriver> fixture.

=head3 Loading your one-to-one relationships.

This is the same as loading a standalone object:

    my $fixtures = My::Fixtures->new( { schema => $schema } );
    $fixtures->load('basic_customer');

    # this is equivalent since these two fixtures require each other
    $fixtures->load('person_with_customer');

    # of course, you can still use $schema->resultset(...)->find to get these
    my $person   = $fixtures->get_fixture('person_with_customer');
    my $customer = $fixtures->get_fixture('basic_customer');

    is $person->id, $customer->person_id, 'One-to-one relationships work';

The main difference between those two C<load> calls is that the first returns
a the C<basic_customer> fixture and the second returns the
C<person_with_customer> fixture, though both load the same data:

    my $customer = $fixtures->load('basic_customer');
    my $person   = $fixtures->load('person_with_customer');

=head2 One-to-many relationships

You actually know everything there is to know about defining fixtures, but
we'll give some more concrete examples.

Let's look at an orders table. A customer might have many orders.

    CREATE TABLE orders (
        order_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER  NOT NULL,
        order_date  DATETIME NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
    );

Let's add two orders for our C<basic_customer>.

    order_without_items => {
        new      => 'Order',
        using    => {
            order_date  => $purchase_date,
            customer_id => { basic_customer => 'customer_id' },
        },
    },
    second_order_without_items => {
        new      => 'Order',
        using    => {
            order_date  => $purchase_date,
            customer_id => { basic_customer => 'customer_id' },
        },
    },

And if you want to load both in your test code:

    my @orders = $fixtures->load(qw/
        order_without_items
        second_order_without_items
    /);

That will properly load the C<basic_customer> (and, of course, the
C<person_with_customer>). However, because C<basic_customer> did not have a
C<next> key, loading the C<basic_customer> by itself does not load orders:

    $fixtures->load('basic_person'); # doesn't load orders

If you want to force the customer to have these two orders, add the C<next>
key:

    basic_customer => {
        new      => 'Customer',
        using    => {
            first_purchase => $datetime_object,
            person_id      => { person_with_customer => 'person_id' },
        },
        next => [qw/order_without_items second_order_without_items/],
    },

=head2 Many-to-many relationhips.

Orders aren't useful without items on them, so let's add two more tables:

    CREATE TABLE items (
        item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name    VARCHAR(255) NOT NULL,
        price   REAL         NOT NULL
    );

    CREATE TABLE order_item (
        order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id       INTEGER NOT NULL,
        order_id      INTEGER NOT NULL,
        price         REAL    NOT NULL,
        FOREIGN KEY(item_id)  REFERENCES items(item_id),
        FOREIGN KEY(order_id) REFERENCES orders(order_id)
    );

(Side note about database normalization: the C<order_item> table also has a
C<price> column because the the price of the item might change over time, or
might be on sale. Fetching the price of orders should rely on the price the
time the order was placed, not on the current item price)

So let's create hammer and screwdriver items, create an order for them and
two order items.

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
        using    => {
            price    => 1.2,
            item_id  => \'item_hammer',
            order_id => \'order_with_items',
        },
    },
    order_item_screwdriver => {
        new      => 'OrderItem',
        using    => {
            price    => .7,
            item_id  => \'item_screwdriver',
            order_id => \'order_with_items',
        },
    },
    order_with_items => {
        new      => 'Order',
        using    => {
            order_date  => $purchase_date,
            customer_id => \'basic_customer',
        },
        next => [qw/order_item_hammer order_item_screwdriver/],
    },

Note that the C<order_with_items> also uses the basic customer. You can reuse
fixtures like this because internally we cache created fixtures.

=head2 Bi-directional relationships (deferred requires).

Occasionally you might need two entities that relate to each other,
signifying different relationships:

    CREATE TABLE people (
        person_id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name              VARCHAR(255) NOT NULL,
        favorite_album_id INTEGER,
        FOREIGN KEY(favorite_album_id) REFERENCES album(album_id)
    );

    CREATE TABLE album (
        album_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        name        VARCHAR(255) NOT NULL,
        producer_id INTEGER,
        FOREIGN KEY(producer_id) REFERENCES people(person_id)
    );

Say producer Rick Rubin produced ZZ Top's album "La Futura", and that it is his
favorite album. You would specify that relationship in this way:

    person_rick_rubin => {
        new => 'Person',
        using => { name => 'Rick Rubin' },
        requires => {
            album_la_futura => {
                our      => 'favorite_album_id'
                their    => 'album_id',
                deferred => 1,
            },
        },
    },
    album_la_futura => {
        new => 'Album',
        using => { name => 'La Futura' },
        requires => {
            person_rick_rubin => {
                our      => 'producer_id',
                their    => 'person_id',
                deferred => 1,
            },
        },
    },

This has the net effect of creating both results, then backfilling the
appropriate values on each result. Note that both sides of the relationship
are marked as C<deferred>.

If the foreign key on one of the two tables was defined as C<NOT NULL>:

    CREATE TABLE album (
        album_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        name        VARCHAR(255) NOT NULL,
        producer_id INTEGER NOT NULL,
        FOREIGN KEY(producer_id) REFERENCES people(person_id)
    );

Then that side of the relationship would not be deferrable, and should be
defined thusly:

    person_rick_rubin => {
        # same as above
    },
    album_la_futura => {
        new => 'Album',
        using => { name => 'La Futura' },
        requires => {
            person_rick_rubin => {
                our      => 'producer_id',
                their    => 'person_id',
                # Nope!
                # deferred => 1,
            },
        },
    },

This would have the net effect of creating the C<person_rick_rubin> result,
then creating the C<album_la_futura> result including the foreign key to it's
producer, and finally backfilling the C<favorite_album_id> foreign key on the
C<producer_rick_rubin> result.

=head2 Groups

Sometimes you want to load multiple fixtures at once. One way to do this is
like this:

    $fixtures->load(@list_of_fixtures_to_load);

However, if you do this a lot, just create a group in your fixtures
definition:

    people => [qw/basic_person person_with_customer/]

Instead of a hashref for the key, have an array reference with all fixtures
listed.

=head1 NOTES

As a general rule, when you call C<< $fixtures->load(@fixture_names) >>, any
fixtures loaded will be cached. If a subsequent fixture attempts to load a
fixture already loaded, it won't be reloaded.

Calling C<< $fixtures->unload >> (or letting the C<$fixtures> object drop out
of scope) will clear the cache and allow you to start fresh,

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
