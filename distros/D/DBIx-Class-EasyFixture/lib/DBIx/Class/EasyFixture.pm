package DBIx::Class::EasyFixture;
$DBIx::Class::EasyFixture::VERSION = '0.12';
# ABSTRACT: Easy fixtures with DBIx::Class

use 5.008003;
use Moose;
use Carp;
use aliased 'DBIx::Class::EasyFixture::Definition';
use namespace::autoclean;

has 'schema' => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);
has '_in_transaction' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    writer  => '_set_in_transaction',
);
has '_cache' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        _set_fixture => 'set',
        _get_result  => 'get',
        _clear       => 'clear',
        is_loaded    => 'exists',
    },
);
has 'no_transactions' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub BUILD {
    my $self = shift;

    # Creating a definition object validates them, so this tells us at
    # construction time if all fixtures are valid.
    $self->_get_definition_object($_) foreach $self->all_fixture_names;
}

sub load {
    my ( $self, @fixtures ) = @_;
    if ( not $self->no_transactions and not $self->_in_transaction ) {
        $self->schema->txn_begin;
        $self->_set_in_transaction(1);
    }
    my @dbic_objects;
    foreach my $fixture (@fixtures) {
        my $definition = $self->_get_definition_object($fixture);
        if ( my $group = $definition->group ) {
            push @dbic_objects => $self->load(@$group);
        }
        else {
            push @dbic_objects => $self->_load($definition);
        }
    }
    return 1 if not defined wantarray or not @dbic_objects;
    return $dbic_objects[0] if not wantarray;
    return @dbic_objects;
}

sub _get_definition_object {
    my ( $self, $fixture ) = @_;
    return Definition->new(
        {   name       => $fixture,
            definition => $self->get_definition($fixture),
            fixtures   => { map { $_ => 1 } $self->all_fixture_names },
        }
    );
}

sub get_result {
    my ( $self, $fixture ) = @_;

    unless ( $self->is_loaded($fixture) ) {
        carp("Fixture '$fixture' was never loaded");
        return;
    }
    return $self->_get_result($fixture);
}

sub _get_object {
    my ( $self, $definition ) = @_;

    my $name   = $definition->name;
    my $object = $self->_get_result($name);
    unless ($object) {
        my $args = $definition->constructor_data;
        if ( my $requires = $definition->requires_pre ) {
            while ( my ( $parent, $methods ) = each %$requires ) {
                my $other = $self->_get_result($parent)
                  or croak("Panic: required object '$parent' not loaded");
                my ( $our, $their ) = @{$methods}{qw/our their/};
                $args->{$our} = $other->$their;
            }
        }
        $object = $self->schema->resultset( $definition->resultset_class )
          ->create( $definition->constructor_data );
        $self->_set_fixture( $name, $object );
    }
    return $object;
}

sub _load {
    my ( $self, $definition ) = @_;

    # XXX This is our guard against circular definitions.
    if ( $self->is_loaded( $definition->name ) ) {
        return $self->_get_result( $definition->name );
    }

    if ( my $requires = $definition->requires_pre ) {
        $self->_load_previous_fixtures($requires);
    }

    my $object = $self->_get_object($definition);

    if ( my $next = $definition->next ) {
        $self->_load_next_fixtures($next);
    }

    if ( my $deferred = $definition->requires_defer ) {
        $self->_load_deferred_fixtures( $object, $deferred );
    }
    return $object;
}

sub _load_previous_fixtures {
    my ( $self, $requires ) = @_;

    foreach my $parent ( keys %$requires ) {
        $self->_load( $self->_get_definition_object($parent) );
    }
}

sub _load_next_fixtures {
    my ( $self, $next ) = @_;

    foreach my $fixture (@$next) {
        my $definition = $self->_get_definition_object($fixture);

        # XXX This is done when _load calls _load_previous_fixtures,
        # so it is not necessary here
        #
        # # a fixture may say "load these other fixtures next", but if that
        # # happens, those "next" fixtures may have different parent fixtures
        # # that they require, so we load them here.
        # if ( my $requires = $definition->requires_pre ) {
        #     while ( my ( $parent, $methods ) = each %$requires ) {
        #         $self->_load( $self->_get_definition_object($parent) )
        #           || croak("Panic: related object '$parent' not loaded");
        #     }
        # }

        # ... and *now* we can load the fixture
        $self->_load($definition);
    }
}

sub _load_deferred_fixtures {
    my ( $self, $object, $deferred) = @_;

    my $update_args = {};
    while( my ($fixture, $methods) = each( %{$deferred} ) ) {
        my $other = $self->_load( $self->_get_definition_object($fixture) );
        my ( $our, $their ) = @{$methods}{qw/our their/};
        $update_args->{$our} = $other->$their;
    }

    $object->update( $update_args );
}

sub unload {
    my $self = shift;
    if ( not $self->no_transactions and $self->_in_transaction ) {
        $self->schema->txn_rollback;
        $self->_clear;
        $self->_set_in_transaction(0);
    }
    else {
        # XXX I don't think I really need this
        #carp("finish() called without load()");
    }
    return 1;
}

sub all_fixture_names {
    croak("You must override all_fixture_names() in a subclass");
}

sub get_definition {
    croak("You must override get_definition() in a subclass");
}

sub fixture_loaded { $_[0]->is_loaded( $_[1] ) }

sub DEMOLISH {
    my $self = shift;
    $self->unload;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::EasyFixture - Easy fixtures with DBIx::Class

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    package My::Fixtures;
    use Moose;
    extends 'DBIx::Class::EasyFixture';

    sub get_fixture       { ... }
    sub all_fixture_names { ... }

And in your test code:

    my $fixtures    = My::Fixtures->new( { schema => $schema } );
    my $dbic_object = $fixtures->load('some_fixture');

    # run your tests

    $fixtures->unload;

Note that C<unload> will be called for you if your fixture object falls out of
scope.

=head1 DESCRIPTION

The latest version of this is always at
L<https://github.com/Ovid/dbix-class-easyfixture>.

This is C<ALPHA> code. Documentation is on its way, including a tutorial. For
now, you'll have to read the tests. You can read F<t/lib/My/Fixtures.pm> to
see how fixtures are defined.

I wanted an easier way to load fixtures for L<DBIx::Class> code. I looked at
L<DBIx::Class::Fixtures> and it made a lot of assumptions that, while
appropriate for some, is not what I wanted (such as the necessity of storing
fixtures in JSON files), and had a reliance on knowing the values of primary
keys, I wrote this to make it easier to define and load L<DBIx::Class>
fixtures for tests.

=head1 METHODS

=head2 C<new>

    my $fixtures = Subclass::Of::DBIx::Class::EasyFixture->new({
        schema => $dbix_class_schema_instance,
    });

This creates and returns a new instance of your C<DBIx::Class::EasyFixture>
subclass. All fixture definitions are validated at this time and the
constructor will C<croak()> with a useful error message upon validation
failure.

=head2 C<all_fixture_names>

    my @fixture_names = $fixtures->all_fixture_names;

Must overridden in your subclass. Should return a list (not an array ref!) of
all fixture names available. This is used internally to generate error
messages if a fixture attempts to reference a non-existent fixture in its
C<next> or C<requires> section.

=head2 C<get_definition>

    my $definition = $fixtures->get_definition($fixture_name);

Must be overridden in a subclass. Should return the fixture definition for the
fixture name passed in. Should return C<undef> if the fixture is not found.

=head2 C<get_result>

    my $dbic_result_object = $fixtures->get_result($fixture_name);

Returns the C<DBIx::Class::Result> object for the given fixture name. Will
C<carp> if the fixture wasn't loaded (this may become a fatal error in future
versions).

=head2 C<load>

    my @dbic_objects = $fixtures->load(@list_of_fixture_names);

Attempts to load all fixtures passed to it. If a transaction has not already
been started, it will be started now. This method may be called multiple
times and it returns the fixtures loaded. If called in scalar context, only
returns the first fixture loaded.

=head2 C<unload>

    $fixtures->unload;

Rolls back the transaction started with C<load>

=head2 C<is_loaded>

    if ( $fixtures->is_loaded($fixture_name) ) {
        ...
    }

Returns a boolean value indicating whether or not the given fixture was
loaded.

*Note*: Originally this method was called C<fixture_loaded>. That was a bad
name. However, C<fixture_loaded> still works as an alias to C<is_loaded>.

=head1 TRANSACTIONS

If you attempt to load a fixture, a transaction is started and it will be
rolled back when you call C<unload()> or when the fixture object falls out of
scope. If, for some reason, you do not want transactions (for example, if you
need to controll them manually), you can use a true value with the
C<no_transactions> argument.

    my $fixtures = My::Fixtures->new(
        schema          => $schema,
        no_transactions => 1,
    );

=head1 FIXTURES

If the following is unclear, see L<DBIx::Class::EasyFixture::Tutorial>.

The C<get_definition($fixture_name)> method must always return a fixture
definition. The definition must be either a fixture group or a fixture
builder.

A fixture group is an array reference containing a list of fixture names. For
example, C<< $fixture->get_definition('all_people') >> might return:

    [qw/ person_1 person_2 person_2 /]

A fixture builder must return a hash reference with the one or more of the
following keys:

=over 4

=item * C<new> (required)

A C<DBIx::Class> result source name.

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

=item * C<using> (required)

A hashref of key/value pairs that will be used to create the C<DBIx::Class>
result source referred to by the C<new> key.

    {
        new   => 'Person',
        using => {
            name  => 'Bob',
            email => 'bob@example.com',
        }
    }

=item * C<next> (optional)

If present, this must point to an array reference of fixture names (in other
words, a fixture group). These fixtures will then be built I<after> the
current fixture is built.

    {
        new   => 'Person',
        using => {
            name  => 'Bob',
            email => 'bob@example.com',
        },
        next => [@list_of_fixture_names],
    }

=item * C<requires> (optional)

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

Assuming we already have a C<Person> fixture defined and it's named
C<some_person> and its ID is named C<id>, we can do this:

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

If you prefer, you can I<inline> the C<requires> into the C<using> key. You
may find this syntax cleaner:

    {
        new      => 'Customer',
        using    => {
            first_purchase => $datetime_object,
            person_id      => { some_person => 'id' },
        },
    }

The C<our> key refers to the attribute for the C<Customer> fixture and the
C<their> key refers to the attribute of the C<Person> fixture. As a
convenience, if both attributes have the same name, you can omit that hashref
and just use the attribute name:

    {
        new      => 'Customer',
        using    => { first_purchase => $datetime_object },
        requires => {
            some_person => 'person_id',
        },
    }

And multiple C<requires> can be specified:

    {
        new      => 'Customer',
        using    => { first_purchase => $datetime_object },
        requires => {
            some_person     => 'person_id',
            primary_contact => 'contact_id',
        },
    }

Or you can skip the C<requires> block entirely and write the above like this
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

=back

When writing a fixture builder, remember that C<requires> are always built
before the current fixture and C<next> is also built after the current
fixture.

=head1 TUTORIAL

See L<DBIx::Class::EasyFixture::Tutorial>.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 TODO

=over 4

=item * Prevent circular fixtures

Currently it's very easy to define circular dependencies. We'll worry about
that later when it becomes more clear how to best handle them.

=item * Better load information

Track what fixtures are requested and what fixtures are loaded (and in which
order).  This makes for better error reporting.

=back

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
