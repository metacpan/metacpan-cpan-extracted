package DBIx::Class::Objects;
$DBIx::Class::Objects::VERSION = '0.05';
use Moose;
use Carp;
use Moose::Util qw( apply_all_roles );

# using this because it will be applied to result classes, not because we want
# to import this behavior
use DBIx::Class::Objects::Role::Result ();

use Class::Load 'try_load_class';
use namespace::autoclean;


has 'schema' => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'base_class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'DBIx::Class::Objects::Base',
);

has 'result_role' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'DBIx::Class::Objects::Role::Result',
);

has roles => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 0,
    default => sub { [] },
);

has 'object_base' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,  # XXX Fix this later
    writer   => '_set_object_base',
);

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $self = shift;
    my %args = ref $_[0] ? %{$_[0]} : @_;
    $args{object_base} =~ s/::$//;
    $self->$orig(\%args);
};

sub _get_object_class_name {
    my ( $self, $source_name ) = @_;
    return $self->object_base . '::' . $source_name;
}

sub objectset {
    my ( $self, $source_name ) = @_;

    return $self->_create_object_set(
        $self->schema->resultset($source_name) );
}

sub _create_object_set {

    # this method allows the user to ensure that resultsets contain instances
    # of DBIx::Class::Objects instead of DBIx::Class::Result
    my ( $self, $resultset ) = @_;

    my %methods;
    foreach my $method (qw/next create single/) {

        # Haven't debugged this, but simply declaring a single subroutine and
        # assigning it to the keys doesn't work. You get errors like this:
        #
        # DBIx::Class::ResultSet::find(): find() expects either a column/value
        # hashref, or a list of values corresponding to the columns of the
        # specified unique constraint 'primary' at t/resultset.t line 30
        #
        # Doing it this way results in a fresh copy of the subref for every
        # method at a slight performance cost. Caching bug?
        $methods{$method} = sub {
            my $this         = shift;
            my $result       = $this->next::method(@_) or return;
            my $source_name  = $result->result_source->source_name;
            unless ($source_name) {
                my $type = ref $result;
                croak("Panic: Couldn't determine source name in '$method' for '$type'");
            }
            my $object_class = $self->_get_object_class_name($source_name)
              or croak(
                "Panic: Couldn't determine object class in '$method' for '$source_name'");
            return $object_class->new( { result_source => $result, object_source => $self, } );
        };
    }

    # we do it this way because they might have created a custom
    # resultset class and thus, we don't know *which* class we're inheriting
    # from.
    my $meta = Moose::Meta::Class->create_anon_class(
        superclasses => [ ref $resultset ],
        cache        => 1,
        methods      => {
            %methods,
            all => sub {
                my $this = shift;
                my @all  = $this->next::method(@_);
                return unless @all;
                my $object_class = $self->_get_object_class_name(
                    $all[0]->result_source->source_name );
                return
                  map { $object_class->new( { result_source => $_, object_source => $self, } ) } @all;
            },
        },
    );
    $meta->rebless_instance($resultset);
    return $resultset;
}

sub load_objects {
    my $self   = shift;
    my $schema = $self->schema;

    apply_all_roles( $self->base_class, @{ $self->roles } ) if scalar(@{ $self->roles });

    foreach my $source_name ($schema->sources) {
        my $object_class = $self->_get_object_class_name($source_name);

        $self->_debug("Trying to load $object_class");

        my ($result, $error) = try_load_class( $object_class );

        if ( $result ) {
            $self->_debug("\t$object_class found.");
        }
        else {

            if ( $error =~ /Compilation failed in require/ ) {
                die $error;
            }

            $self->_debug("\t$object_class not found. Building.");
            Moose::Meta::Class->create(
                $object_class,
                superclasses => [ $self->base_class ],
            );
            unless ( Class::Load::is_class_loaded($object_class) ) {
                die "$object_class didn't load";
            }
        }

        # XXX Not sure about this. If they forget to inherit from
        # DBIx::Class::Objects::Base, we do it for them. It works around an
        # issue the programmer might forget, but is this too much magic, given
        # that we're already doing a lot of it?
        my $meta = $object_class->meta;
        my $was_immutable = $meta->is_immutable;
        $meta->make_mutable if $was_immutable;
        unless ( $object_class->isa( $self->base_class ) ) {
            $meta->superclasses( $meta->superclasses, $self->base_class );
        }
        $self->_add_methods( $object_class, $source_name );

        $meta->make_immutable if $was_immutable;
    }
}

sub _add_methods {
    my ( $self, $class, $source_name ) = @_;
    my $schema = $self->schema;
    my $meta   = $class->meta;

    my $source = $schema->resultset($source_name)->result_source;

    $self->result_role->meta->apply(
        $meta,
        handles             => [ $source->columns ],
        result_source_class => $source->result_class,
        source              => $class,
    );

    my @relationships = $source->relationships;
    foreach my $relationship (@relationships) {
        my $info = $source->relationship_info($relationship);

        # if the accessor is a "multi" access, it returns a resultset, not a
        # result.
        my $is_multi = 'multi' eq $info->{attrs}{accessor};
        my $source
          = $schema->resultset( $info->{source} )->result_source->source_name;
        my $other_class = $self->_get_object_class_name($source);

        # XXX Bless me father for I have sinned ...
        $info->{_result_class_to_object_class} = $other_class;

        if ($is_multi) {

            # all resultsets get blessed into our resultset class
            $meta->add_method(
                $relationship => sub {
                    my $this      = shift;
                    my $resultset = $this->result_source->$relationship(@_)
                      or return;
                    return $self->_create_object_set($resultset);
                },
            );
        }
        else {
            # all results are our objects, not results
            $meta->add_method(
                $relationship => sub {
                    my $this     = shift;
                    my $response = $this->result_source->$relationship
                      or return;
                    return $other_class->new(
                        { result_source => $response, object_source => $self, } );
                }
            );
        }
    }
}

sub _debug {
    my ( $self, $message ) = @_;
    return unless $self->debug;
    warn sprintf("%s :: %s\n", scalar localtime, $message);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

DBIx::Class::Objects - Rewrite your DBIC objects via inheritance

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    my $schema = My::DBIx::Class::Schema->connect(@args);

    my $objects = DBIx::Class::Objects->new({
        schema      => $schema,
        object_base => 'My::Object',
        roles       => [qw( My::Role::Thing )],
    });
    $objects->load_objects;

    my $person = $objects->objectset('Person')
                         ->find( { email => 'not@home.com' } );

    # If found, $person is a My::Object::Person object, not a
    # My::DBIx::Class::Schema::Result::Person

=head1 WARNING

The C<DBIx::Class::Objects> module is an experiment to "fix" (for some values
of "fix") some issues we traditionally have with ORMs by allowing the
programmer to use easily use objects as they wish to rather than the hierarchy
forced on them by C<DBIx::Class>.

This is B<ALPHA> code and may be a very bad idea. Use at your own risk.

=head1 DESCRIPTION

Consider a database where you have people and each person might be a customer.
The following two tables might demonstrate that relationship.

    CREATE TABLE people (
        person_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name      VARCHAR(255) NOT NULL,
        email     VARCHAR(255)     NULL UNIQUE,
        birthday  DATETIME     NOT NULL
    );

    CREATE TABLE customers (
        customer_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id      INTEGER  NOT NULL UNIQUE,
        first_purchase DATETIME NOT NULL,
        FOREIGN KEY(person_id) REFERENCES people(person_id)
    );

If your schema starts with C<Sample::Schema::>, in C<DBIx::Class> terms you'll
find that C<Sample::Schema::Result::Person> I<might_have> a
C<Sample::Schema::Result::Customer>:

    __PACKAGE__->might_have(
        "customer",
        "Sample::Schema::Result::Customer",
        { "foreign.person_id" => "self.person_id" },
    );

As a programmer, you might find that frustrating. From your viewpoint, you
might think that C<Customer> I<isa> C<Person>. Or perhaps you also have
C<Employee>s in your database and a person can be both a customer and an
employee, how do you model that? For C<DBIx::Class>, you have delegation:

    my $customer = $person->customer;
    my $employee = $person->employee;

Whereas for OO code, you might want to have a C<Person> class and C<Employee>
and C<Customer> roles. Or maybe you're a fan of multiple inheritance (I hope
not) and you create a C<CustomerEmployee> class which tries to inherit from
both C<Customer> and C<Employee>.

Not having full control over your object hierarchy is merely one of the
problems with the L<Object-Relational Impedence Mismatch|http://en.wikipedia.org/wiki/Object-relational_impedance_mismatch>.

Or maybe you're dismayed to instantiate a C<Sample::Schema::Result::Person>
object and discover that you have 157 methods because you were forced to
inherit from C<DBIx::Class::Core>, when all you wanted was the name, email and
birthday. This experiment tries to minimize that.

=head1 METHODS

=head2 C<new>

    my $objects = DBIx::Class::Objects->new({
        schema      => $schema,
        object_base => 'My::Object',
    });

The C<new> constructor takes two required arguments and one optional argument:

=over 4

=item * C<schema> (required)

A C<DBIx::Class::Schema> object.

=item * C<object_base> (required)

The package prefix of your name objects. If your schema classes resemble
something like C<Sample::Schema::Result::Person>, your returned objects will
have names like C<My::Object::Person> (assuming you used C<My::Object> for the
C<object_base> parameter).

=item * C<debug> (optional)

At the present time, this will print to STDERR a list of objects you're trying
to build and whether or not a concrete implementation was found or it's being
built on the fly.

    Trying to load My::Object::Person
        My::Object::Person found.
    Trying to load My::Object::Order
        My::Object::Order not found. Building.
    Trying to load My::Object::Customer
        My::Object::Customer found.
    Trying to load My::Object::Item
        My::Object::Item not found. Building.
    Trying to load My::Object::OrderItem
        My::Object::OrderItem not found. Building.

=item * C<roles> (optional)

This will apply the optional Moose role(s) to your My::Object classes.  Useful
for if you have some utility functions you would like applied to each table
without having to create files for every table.

=back

=head2 C<load_objects>

    $objects->load_objects;

Similar to L<DBIx::Class::Schema>'s C<load_namespaces>, but it's an instane
method instead of a class method. It will load all of your objects for you. It
will ensure that your objects inherit from L<DBIx::Class::Objects::Base> and
will apply the parameterized role L<DBIx::Class::Objects::Role::Result>.

The base class is what allows things like C<update> to be called directly on
the object. Is is the parameterized role which sets up the delegation to the
C<DBIx::Class> objects.

=head2 C<objectset>

    my $person = $objects->objectset('Person')
                         ->find( { email => 'not@home.com' } );

This method is similar to C<< $schema->resultset >>, but it returns sets of
C<DBIx::Class::Objects> objects instead of results. The interface is the same
as C<DBIx::Class::ResultSet>, but calling methods like C<find>, C<next>,
C<first>, C<all> and so on should I<do the right thing> (famous last words).

=head1 LET'S DELEGATE TO DBIx::Class RESULTS

C<DBIx::Class::Objects> is an attempt to allow you to recompose your
C<DBIx::Class> objects as you would like. Instead of C<DBIx::Class> returning
resultsets and results, C<DBIx::Class::Objects> returns objectsets and
objects. You can do anything you want with the latter.

=head2 Basic Usage

Using this module is as simple as this:

    my $schema = Sample::Schema->connect(@args);

    my $objects = DBIx::Class::Objects->new({
        schema      => $schema,
        object_base => 'My::Object',
    });
    $objects->load_objects;

    my $person = $objects->objectset('Person')
                         ->find( { email => 'not@home.com' } );

And you'll discover that you get back a C<My::Object::Person> object instead
of a C<Sample::Schema::Result::Person> object. In C<DBIx::Class>, if you don't
explicitly create resultset classes, a default resultset class will be created
for you. In C<DBIx::Class::Objects>, if you don't explicitly create object
classes, a default one is created for you. For example, if you don't have a
C<My::Object::Person> class written (or if C<DBIx::Class::Objects> can't find
it), you will have a basic C<My::Object::Person> instance with the following
methods (according to the debugger):

    DB<2> m $person
    BUILD
    _my_object_person
    birthday
    customer
    email
    meta
    name
    object_source
    person_id
    result_source
    update
    via DBIx::Class::Objects::Base: DESTROY
    via DBIx::Class::Objects::Base: new
    via DBIx::Class::Objects::Base -> Moose::Object: BUILDALL
    via DBIx::Class::Objects::Base -> Moose::Object: BUILDARGS
    via DBIx::Class::Objects::Base -> Moose::Object: DEMOLISHALL
    via DBIx::Class::Objects::Base -> Moose::Object: DOES
    via DBIx::Class::Objects::Base -> Moose::Object: does
    via DBIx::Class::Objects::Base -> Moose::Object: dump
    via UNIVERSAL: VERSION
    via UNIVERSAL: can
    via UNIVERSAL: isa

That's actually not too bad, compared to C<DBIx::Class>. If you remove
C<UNIVERSAL> methods and methods in ALL CAPS, you get this:

    _my_object_person
    birthday
    customer
    email
    meta
    name
    object_source
    person_id
    result_source
    update
    via DBIx::Class::Objects::Base: new
    via DBIx::Class::Objects::Base -> Moose::Object: does
    via DBIx::Class::Objects::Base -> Moose::Object: dump

That's actually a fairly clean object. The C<person_id>, C<email>, C<name> and
C<birthday> objects are handled by the C<result_source>. If you want to update
the object, you do this:

    $person->name($new_name);
    $person->update;

=head2 Creating your own objects

Having these objects spring up automatically is great and if you have 100
result sources, it's nice that you don't have to write 100 object classes.
However, though you have far fewer methods, what's the point?

Well, you can write your own classes:

    package My::Object::Person;

    use Moose;
    use namespace::autoclean;

    # this is optional. If you forget to include it, DBIx::Class::Objects will
    # inject this for you. However, it's good to have it here for
    # documentation purposes.
    extends 'DBIx::Class::Objects::Base';

    sub is_customer {
        my $self = shift;
        return defined $self->customer;
    }

    __PACKAGE__->meta->make_immutable;

    1;

Again, that's not much of a win, but what if you want inheritance?

    package My::Object::Customer;

    use Moose;
    extends 'My::Object::Person';

    __PACKAGE__->meta->make_immutable;

    1;

You've now inherited the delegated methods from C<My::Object::Person>.

    my $customer_os = $objects->objectset('Customer')->search(
        \%dbix_class_search_args
    );
    foreach my $customer ($customer_os->next) {
        if ( $some_condition ) {
            $customer->name('new name');
            $customer->update; # updates $customer->person, too
        }
    }

For every object, calling C<result_source> gets you the original
C<DBIx::Class::Result>,

    say $customer->result_source; # Sample::Schema::Result::Customer
    say $customer->person->result_source; # Sample::Schema::Result::Person

and calling C<object_source> gets you the encapsulating C<DBIx::Class::Objects>
object.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

Dan Burke C<< dburke at addictmud.org >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-object-bridge at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Objects>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Objects

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Objects>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Objects>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Objects>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Objects/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
