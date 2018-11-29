# NAME

DBIx::Class::EasyFixture - Easy fixtures with DBIx::Class

# VERSION

version 0.13

# SYNOPSIS

    package My::Fixtures;
    use Moo;    # (Moose is also fine)
    extends 'DBIx::Class::EasyFixture';

    sub get_definition    { ... }
    sub all_fixture_names { ... }

And in your test code:

    my $fixtures    = My::Fixtures->new( { schema => $schema } );
    my $dbic_object = $fixtures->load('some_fixture');

    # run your tests

    $fixtures->unload;

Note that `unload` will be called for you if your fixture object falls out of
scope.

# DESCRIPTION

The latest version of this is always at
[https://github.com/Ovid/dbix-class-easyfixture](https://github.com/Ovid/dbix-class-easyfixture).

This is `ALPHA` code. Documentation is on its way, including a tutorial. For
now, you'll have to read the tests. You can read `t/lib/My/Fixtures.pm` to
see how fixtures are defined.

I wanted an easier way to load fixtures for [DBIx::Class](https://metacpan.org/pod/DBIx::Class) code. I looked at
[DBIx::Class::Fixtures](https://metacpan.org/pod/DBIx::Class::Fixtures) and it made a lot of assumptions that, while
appropriate for some, is not what I wanted (such as the necessity of storing
fixtures in JSON files), and had a reliance on knowing the values of primary
keys, I wrote this to make it easier to define and load [DBIx::Class](https://metacpan.org/pod/DBIx::Class)
fixtures for tests.

# METHODS

## `new`

    my $fixtures = Subclass::Of::DBIx::Class::EasyFixture->new({
        schema => $dbix_class_schema_instance,
    });

This creates and returns a new instance of your `DBIx::Class::EasyFixture`
subclass. All fixture definitions are validated at this time and the
constructor will `croak()` with a useful error message upon validation
failure.

## `all_fixture_names`

    my @fixture_names = $fixtures->all_fixture_names;

Must overridden in your subclass. Should return a list (not an array ref!) of
all fixture names available. This is used internally to generate error
messages if a fixture attempts to reference a non-existent fixture in its
`next` or `requires` section.

## `get_definition`

    my $definition = $fixtures->get_definition($fixture_name);

Must be overridden in a subclass. Should return the fixture definition for the
fixture name passed in. Should return `undef` if the fixture is not found.

## `get_result`

    my $dbic_result_object = $fixtures->get_result($fixture_name);

Returns the `DBIx::Class::Result` object for the given fixture name. Will
`carp` if the fixture wasn't loaded (this may become a fatal error in future
versions).

## `load`

    my @dbic_objects = $fixtures->load(@list_of_fixture_names);

Attempts to load all fixtures passed to it. If a transaction has not already
been started, it will be started now. This method may be called multiple
times and it returns the fixtures loaded. If called in scalar context, only
returns the first fixture loaded.

## `unload`

    $fixtures->unload;

Rolls back the transaction started with `load`

## `is_loaded`

    if ( $fixtures->is_loaded($fixture_name) ) {
        ...
    }

Returns a boolean value indicating whether or not the given fixture was
loaded.

\*Note\*: Originally this method was called `fixture_loaded`. That was a bad
name. However, `fixture_loaded` still works as an alias to `is_loaded`.

# TRANSACTIONS

If you attempt to load a fixture, a transaction is started and it will be
rolled back when you call `unload()` or when the fixture object falls out of
scope. If, for some reason, you do not want transactions (for example, if you
need to control them manually), you can use a true value with the
`no_transactions` argument.

    my $fixtures = My::Fixtures->new(
        schema          => $schema,
        no_transactions => 1,
    );

# FIXTURES

If the following is unclear, see [DBIx::Class::EasyFixture::Tutorial](https://metacpan.org/pod/DBIx::Class::EasyFixture::Tutorial).

The `get_definition($fixture_name)` method must always return a fixture
definition. The definition must be either a fixture group or a fixture
builder.

A fixture group is an array reference containing a list of fixture names. For
example, `$fixture->get_definition('all_people')` might return:

    [qw/ person_1 person_2 person_2 /]

A fixture builder must return a hash reference with the one or more of the
following keys:

- `new` (required)

    A `DBIx::Class` result source name.

        {
            new   => 'Person',
            using => {
                name  => 'Bob',
                email => 'bob@example.com',
            }
        }

    Internally, the above will do something similar to this:

        $schema->resultset($definition->{name})
               ->create($definition->{using});

- `using` (required)

    A hashref of key/value pairs that will be used to create the `DBIx::Class`
    result source referred to by the `new` key.

        {
            new   => 'Person',
            using => {
                name  => 'Bob',
                email => 'bob@example.com',
            }
        }

- `next` (optional)

    If present, this must point to an array reference of fixture names (in other
    words, a fixture group). These fixtures will then be built _after_ the
    current fixture is built.

        {
            new   => 'Person',
            using => {
                name  => 'Bob',
                email => 'bob@example.com',
            },
            next => [@list_of_fixture_names],
        }

- `requires` (optional)

    Must point to either a scalar of an attribute name or a hash mapping of
    attribute names.

    Many fixtures require data from another fixture. For example, a customer might
    require a person object being built and the following won't work:

        {
            new   => 'Customer',
            using => {
                first_purchase => $datetime_object,
                person_id      => 'some_person.person_id',
            }
        }

    Assuming we already have a `Person` fixture defined and it's named
    `some_person` and its ID is named `id`, we can do this:

        {
            new      => 'Customer',
            using    => { first_purchase => $datetime_object },
            requires => {
                some_person => {
                    our   => 'person_id',
                    their => 'id',
                },
            },
        }

    If you prefer, you can _inline_ the `requires` into the `using` key. You
    may find this syntax cleaner:

        {
            new      => 'Customer',
            using    => {
                first_purchase => $datetime_object,
                person_id      => { some_person => 'id' },
            },
        }

    The `our` key refers to the attribute for the `Customer` fixture and the
    `their` key refers to the attribute of the `Person` fixture. As a
    convenience, if both attributes have the same name, you can omit that hashref
    and just use the attribute name:

        {
            new      => 'Customer',
            using    => { first_purchase => $datetime_object },
            requires => {
                some_person => 'person_id',
            },
        }

    And multiple `requires` can be specified:

        {
            new      => 'Customer',
            using    => { first_purchase => $datetime_object },
            requires => {
                some_person     => 'person_id',
                primary_contact => 'contact_id',
            },
        }

    Or you can skip the `requires` block entirely and write the above like this
    (which is now the preferred syntax, but whatever floats your boat):

        {
            new      => 'Customer',
            using    => {
                first_purchase => $datetime_object,
                person_id      => { some_person     => 'person_id' },
                contact_id     => { primary_contact => 'contact_id' },
            },
        }

    If both the current fixture and the other fixture it requires have the same
    name for the attribute, a reference to the other fixture name (scalar
    reference) will suffice:

        {
            new      => 'Customer',
            using    => {
                first_purchase => $datetime_object,
                person_id      => \'some_person',
                contact_id     => \'primary_contact',
            },
        }
    The above will construct the fixture like this:

        $schema->resultset('Customer')->create({
            first_purchase  => $datetime_object,
            person_id       => $person->person_id,
            primary_contact => $contact->contact_id,
        });

When writing a fixture builder, remember that `requires` are always built
before the current fixture and `next` is also built after the current
fixture.

# TUTORIAL

See [DBIx::Class::EasyFixture::Tutorial](https://metacpan.org/pod/DBIx::Class::EasyFixture::Tutorial).

# AUTHOR

Curtis "Ovid" Poe, `<ovid at cpan.org>`

# TODO

- Prevent circular fixtures

    Currently it's very easy to define circular dependencies. We'll worry about
    that later when it becomes more clear how to best handle them.

- Better load information

    Track what fixtures are requested and what fixtures are loaded (and in which
    order).  This makes for better error reporting.

# AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
