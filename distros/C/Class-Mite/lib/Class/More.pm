package Class::More;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.1.1');
our $AUTHORITY = 'cpan:MANWAR';

my %ACCESSOR_CACHE;
my %BUILD_ORDER_CACHE;
my %PARENT_LOADED_CACHE;
my %ALL_ATTRIBUTES_CACHE;
our %ATTRIBUTES;

sub _generate_fast_accessor {
    my ($attr_name) = @_;

    return $ACCESSOR_CACHE{$attr_name} ||= sub {
        $_[0]{$attr_name} = $_[1] if @_ > 1;
        return $_[0]{$attr_name};
    };
}

sub import {
    my ($class, @args) = @_;
    my $caller = caller;

    strict->import;
    warnings->import;

    no strict 'refs';

    # Install optimised new method
    *{"${caller}::new"} = _generate_optimised_constructor($caller);

    # Install has method
    *{"${caller}::has"} = \&_has;

    # Install extends method
    *{"${caller}::extends"} = \&_extends;

    # Load Role.pm if available
    eval { require Role };
    if (!$@) {
        *{"${caller}::with"} = \&Role::with;
        *{"${caller}::does"} = \&Role::does;
    }

    if (@args && $args[0] eq 'extends') {
        _extends($caller, @args[1..$#args]);
    }
}

sub _generate_optimised_constructor {
    my $class = shift;

    return sub {
        my $class = shift;
        my %args = @_;

        # Fast path: bless hashref directly for maximum speed
        my $self = bless {}, $class;

        # Get cached attributes
        my $class_attrs = _get_all_attributes_fast($class);

        # Ultra-fast path: no attributes, no BUILD methods
        unless (%$class_attrs) {
            my $build_methods = $BUILD_ORDER_CACHE{$class} ||= _compute_build_methods_fast($class);
            unless (@$build_methods) {
                # Absolute fastest path: just copy args and return
                %$self = %args;
                return $self;
            }
        }

        # Make args copy for defaults
        my %args_copy = %args;

        # Process attributes efficiently
        _process_attributes_ultra_fast($class, $self, \%args, \%args_copy, $class_attrs);

        # Copy remaining args
        while (my ($key, $value) = each %args) {
            $self->{$key} = $value unless exists $self->{$key};
        }

        # Call BUILD methods if any
        my $build_methods = $BUILD_ORDER_CACHE{$class} ||= _compute_build_methods_fast($class);
        if (@$build_methods) {
            $_->($self, \%args_copy) for @$build_methods;
        }

        return $self;
    };
}

sub _process_attributes_ultra_fast {
    my ($class, $self, $args, $args_copy, $class_attrs) = @_;

    my @required_check;

    # PASS 1: Constructor values with minimal operations
    foreach my $attr_name (keys %$class_attrs) {
        my $spec = $class_attrs->{$attr_name};

        if (exists $args->{$attr_name}) {
            $self->{$attr_name} = $args->{$attr_name};
            delete $args->{$attr_name};
            next;
        }

        push @required_check, $attr_name if $spec->{required};
    }

    # PASS 2: Defaults
    foreach my $attr_name (keys %$class_attrs) {
        next if exists $self->{$attr_name};

        my $spec = $class_attrs->{$attr_name};
        if (exists $spec->{default}) {
            my $default = $spec->{default};
            $self->{$attr_name} = ref $default eq 'CODE'
                ? $default->($self, $args_copy)
                : $default;
        }
    }

    # PASS 3: Required attributes (only if any exist)
    if (@required_check) {
        foreach my $attr_name (@required_check) {
            unless (defined $self->{$attr_name}) {
                die "Required attribute '$attr_name' not provided for class $class";
            }
        }
    }
}

sub _get_all_attributes_fast {
    my ($class) = @_;

    return $ALL_ATTRIBUTES_CACHE{$class} if exists $ALL_ATTRIBUTES_CACHE{$class};

    my %all_attrs;

    # Current class
    if (my $current_attrs = $ATTRIBUTES{$class}) {
        %all_attrs = %$current_attrs;
    }

    # Parents
    no strict 'refs';
    my @isa = @{"${class}::ISA"};
    foreach my $parent (@isa) {
        next if $parent eq 'Class::More' || $parent eq 'UNIVERSAL';
        if (my $parent_attrs = $ATTRIBUTES{$parent}) {
            %all_attrs = (%$parent_attrs, %all_attrs);
        }
    }

    return $ALL_ATTRIBUTES_CACHE{$class} = \%all_attrs;
}

sub _compute_build_methods_fast {
    my ($class) = @_;

    my @inheritance_tree = _get_inheritance_tree_dfs($class);
    my @build_methods;

    foreach my $c (@inheritance_tree) {
        no strict 'refs';
        if (defined &{"${c}::BUILD"}) {
            push @build_methods, \&{"${c}::BUILD"};
        }
    }

    return \@build_methods;
}

# Efficient DFS
sub _get_inheritance_tree_dfs {
    my ($class, $visited) = @_;
    $visited ||= {};

    return () if $visited->{$class} || !defined $class;
    $visited->{$class} = 1;

    my @order;

    no strict 'refs';
    my @isa = @{"${class}::ISA"};

    foreach my $parent (@isa) {
        next if !defined $parent || $parent eq 'Class::More' || $parent eq 'UNIVERSAL' || $parent eq '';
        push @order, _get_inheritance_tree_dfs($parent, $visited);
    }

    push @order, $class;
    return @order;
}

sub _has {
    my ($attr_name, %spec) = @_;
    my $current_class = caller;

    _clear_attributes_cache($current_class);

    $ATTRIBUTES{$current_class} = {} unless exists $ATTRIBUTES{$current_class};
    $ATTRIBUTES{$current_class}{$attr_name} = \%spec;

    no strict 'refs';
    if (!defined &{"${current_class}::${attr_name}"}) {
        *{"${current_class}::${attr_name}"} = _generate_fast_accessor($attr_name);
    }
}

sub _extends {
    my $caller = caller;
    my @parents = @_;

    _delete_build_cache($caller);
    _clear_attributes_cache($caller);

    for my $parent_class (@parents) {
        die "Recursive inheritance detected: $caller cannot extend itself"
            if $caller eq $parent_class;

        unless ($PARENT_LOADED_CACHE{$parent_class}) {
            my $parent_file = "$parent_class.pm";
            $parent_file =~ s{::}{/}g;

            unless ($INC{$parent_file}) {
                eval { require $parent_file };
            }
            $PARENT_LOADED_CACHE{$parent_class} = 1;
        }

        no strict 'refs';
        unless (grep { $_ eq $parent_class } @{"${caller}::ISA"}) {
            push @{"${caller}::ISA"}, $parent_class;
        }
    }
}

sub _delete_build_cache {
    my ($class) = @_;
    delete $BUILD_ORDER_CACHE{$class};
    for my $cached_class (keys %BUILD_ORDER_CACHE) {
        if (_inherits_from_fast($cached_class, $class)) {
            delete $BUILD_ORDER_CACHE{$cached_class};
        }
    }
}

sub _inherits_from_fast {
    my ($class, $parent) = @_;
    no strict 'refs';
    my @isa = @{"${class}::ISA"};
    return 1 if grep { $_ eq $parent } @isa;
    foreach my $direct_parent (@isa) {
        return 1 if _inherits_from_fast($direct_parent, $parent);
    }
    return 0;
}

sub _clear_attributes_cache {
    my ($class) = @_;
    delete $ALL_ATTRIBUTES_CACHE{$class};
    for my $cached_class (keys %ALL_ATTRIBUTES_CACHE) {
        if (_inherits_from_fast($cached_class, $class)) {
            delete $ALL_ATTRIBUTES_CACHE{$cached_class};
        }
    }
}

sub can_handle_attributes { 1 }

sub meta {
    my $class = shift;
    return {
        can_handle_attributes => 1,
        attributes => $ATTRIBUTES{$class} || {},
    };
}

sub get_all_attributes {
    my ($class) = @_;
    return _get_all_attributes_fast($class);
}

sub _get_all_attributes {
    my ($class) = @_;
    return _get_all_attributes_fast($class);
}

=head1 NAME

Class::More - A fast, lightweight class builder for Perl

=head1 VERSION

Version v0.1.1

=head1 SYNOPSIS

    package My::Class;
    use Class::More;

    # Define attributes
    has 'name' => ( required => 1 );
    has 'age'  => ( default => 0 );
    has 'tags' => ( default => sub { [] } );

    # Set up inheritance
    extends 'My::Parent';

    # Custom constructor logic
    sub BUILD {
        my ($self, $args) = @_;
        $self->{initialized} = time;
    }

    sub greet {
        my $self = shift;
        return "Hello, " . $self->name;
    }

    1;

    # Usage
    my $obj = My::Class->new(
        name => 'Alice',
        age  => 30
    );

    print $obj->name;  # Alice
    print $obj->age;   # 30

=head1 DESCRIPTION

Class::More provides a fast, lightweight class building system for Perl with
attribute support, inheritance, and constructor building. It's designed for
performance and simplicity while providing essential object-oriented features.

The module focuses on speed with optimized method generation, caching, and
minimal runtime overhead.

=head1 FEATURES

=head2 Core Features

=over 4

=item * B<Fast Attribute System>: Simple attributes with required flags and defaults

=item * B<Automatic Accessors>: Automatically generates getter/setter methods

=item * B<Inheritance Support>: Multiple inheritance with proper method resolution

=item * B<BUILD Methods>: Constructor-time initialisation hooks

=item * B<Performance Optimised>: Extensive caching and optimised code paths

=item * B<Role Integration>: Works seamlessly with L<Role> when available

=back

=head2 Performance Features

=over 4

=item * Pre-generated accessors for maximum speed

=item * Method resolution order caching

=item * Attribute specification caching

=item * Fast inheritance checks

=item * Batch accessor installation

=back

=head1 METHODS

=head2 Class Definition Methods

These methods are exported to your class when you C<use Class::More>.

=head3 has

    has 'attribute_name';
    has 'count' => ( default => 0 );
    has 'items' => ( default => sub { [] } );
    has 'name'  => ( required => 1 );

Defines an attribute in your class. Creates an accessor method that can get
and set the attribute value.

Supported options:

=over 4

=item * C<default> - Default value or code reference that returns default value

=item * C<required> - Boolean indicating if attribute must be provided to constructor

=back

=head3 extends

    extends 'Parent::Class';
    extends 'Parent1', 'Parent2';

Sets up inheritance for your class. Can specify multiple parents for multiple
inheritance. Automatically loads parent classes if needed.

=head3 new

    my $obj = My::Class->new(%attributes);
    my $obj = My::Class->new( name => 'test', count => 42 );

The constructor method. Automatically provided by Class::More. Handles:

=over 4

=item * Attribute initialisation with defaults

=item * Required attribute validation

=item * BUILD method calling in proper inheritance order

=back

=head2 Special Methods

=head3 BUILD

    sub BUILD {
        my ($self, $args) = @_;
        # Custom initialization logic
        $self->{internal_field} = process($args->{external_field});
    }

Optional method called after object construction but before returning from C<new>.
Receives the object and the hashref of constructor arguments.

BUILD methods are called in inheritance order (parent classes first).

=head3 meta

    my $meta = My::Class->meta;
    print $meta->{can_handle_attributes};  # 1
    print keys %{$meta->{attributes}};     # name, age, tags

Returns metadata about the class. Currently provides:

=over 4

=item * C<can_handle_attributes> - Always true

=item * C<attributes> - Hashref of attribute specifications

=back

=head1 ATTRIBUTE SYSTEM

=head2 Basic Usage

    package User;
    use Class::More;

    has 'username' => ( required => 1 );
    has 'email'    => ( required => 1 );
    has 'status'   => ( default => 'active' );
    has 'created'  => ( default => sub { time } );

Attributes defined with C<has> automatically get accessor methods:

    my $user = User->new(
        username => 'alice',
        email    => 'alice@example.com'
    );

    # Getter
    print $user->username;  # alice

    # Setter
    $user->status('inactive');

=head2 Required Attributes

    has 'critical_data' => ( required => 1 );

If a required attribute is not provided to the constructor, an exception is thrown:

    # Dies: "Required attribute 'critical_data' not provided for class User"
    User->new( username => 'test' );

=head2 Default Values

    has 'counter' => ( default => 0 );
    has 'list'    => ( default => sub { [] } );
    has 'complex' => ( default => sub {
        return { computed => time }
    });

Defaults can be simple values or code references. Code references are executed
at construction time and receive the object and constructor arguments.

=head2 Inheritance and Attributes

    package Parent;
    use Class::More;
    has 'parent_attr' => ( default => 'from_parent' );

    package Child;
    use Class::More;
    extends 'Parent';
    has 'child_attr' => ( default => 'from_child' );

Child classes inherit parent attributes. If both parent and child define the
same attribute, the child's specification takes precedence.

=head1 PERFORMANCE OPTIMISATIONS

Class::More includes several performance optimisations:

=over 4

=item * B<Pre-generated Accessors>: Simple accessors are pre-compiled and reused

=item * B<Attribute Caching>: Combined attribute specifications are cached per class

=item * B<BUILD Order Caching>: BUILD method call order is computed once per class

=item * B<Fast Inheritance Checks>: Optimised inheritance tree traversal

=item * B<Batch Operations>: Multiple accessors installed in batch when possible

=back

=head1 EXAMPLES

=head2 Simple Class

    package Person;
    use Class::More;

    has 'name' => ( required => 1 );
    has 'age'  => ( default => 0 );

    sub introduce {
        my $self = shift;
        return "I'm " . $self->name . ", age " . $self->age;
    }

    1;

=head2 Class with Inheritance

    package Animal;
    use Class::More;

    has 'species' => ( required => 1 );
    has 'sound'   => ( required => 1 );

    sub speak {
        my $self = shift;
        return $self->sound;
    }

    package Dog;
    use Class::More;
    extends 'Animal';

    sub BUILD {
        my ($self, $args) = @_;
        $self->{species} = 'Canine' unless $args->{species};
        $self->{sound}   = 'Woof!'  unless $args->{sound};
    }

    sub fetch {
        my $self = shift;
        return $self->name . " fetches the ball!";
    }

=head2 Class with Complex Attributes

    package Configuration;
    use Class::More;

    has 'settings' => ( default => sub { {} } );
    has 'counters' => ( default => sub { { success => 0, failure => 0 } } );
    has 'log_file' => ( required => 1 );

    sub BUILD {
        my ($self, $args) = @_;

        # Initialize complex data structures
        $self->{internal_cache} = {};
        $self->{start_time} = time;
    }

    sub increment {
        my ($self, $counter) = @_;
        $self->counters->{$counter}++;
    }

=head1 INTEGRATION WITH Role

When L<Role> is available, Class::More automatically exports:

=head3 with

    package My::Class;
    use Class::More;

    with 'Role::Printable', 'Role::Serialisable';

Composes roles into your class. See L<Role> for complete documentation.

=head3 does

    if ($obj->does('Role::Printable')) {
        $obj->print;
    }

Checks if an object consumes a specific role.

=head1 LIMITATIONS

=head2 Attribute System Limitations

=over 4

=item * B<No Type Constraints>: Attributes don't support type checking

=item * B<No Access Control>: All attributes are readable and writable

=item * B<No Coercion>: No automatic value transformation

=item * B<No Triggers>: No callbacks when attributes change

=item * B<No Lazy Building>: Defaults are applied immediately at construction

=item * B<No Private/Protected>: All attributes are publicly accessible via accessors

=back

=head2 Inheritance Limitations

=over 4

=item * B<No Interface Enforcement>: No compile-time method requirement checking

=item * B<Limited Meta-Object Protocol>: Basic metadata only

=item * B<No Traits>: No trait-based composition

=item * B<Diamond Problem>: Multiple inheritance may have ambiguous method resolution

=back

=head2 General Limitations

=over 4

=item * B<No Immutability>: Can't make classes immutable for performance

=item * B<No Serialisation>: No built-in serialisation/deserialisation

=item * B<No Database Integration>: No ORM-like features

=item * B<No Exception Hierarchy>: No custom exception classes

=back

=head2 Compatibility Notes

=over 4

=item * Designed for simplicity and speed over feature completeness

=item * Uses standard Perl OO internals (blessed hashrefs)

=item * Compatible with most CPAN modules that expect blessed hashrefs

=item * Not compatible with Moose/Mouse object systems

=item * Role integration requires separate L<Role> module

=back

=head1 DIAGNOSTICS

=head2 Common Errors

=over 4

=item * C<"Required attribute 'attribute_name' not provided for class Class::Name">

A required attribute was not passed to the constructor.

=item * C<"Recursive inheritance detected: ClassA cannot extend itself">

A class tries to inherit from itself, directly or indirectly.

=item * C<"Invalid attribute option 'option_name' for 'attribute_name' in Class::Name">

An unsupported attribute option was used.

=item * C<"Can't locate Parent/Class.pm in @INC">

A parent class specified in C<extends> couldn't be loaded.

=back

=head2 Performance Tips

=over 4

=item * Use simple defaults when possible (avoid sub refs for static values)

=item * Define all attributes before calling C<extends> for optimal caching

=item * Keep BUILD methods lightweight

=item * Use the provided C<new> method rather than overriding it

=back

=head1 SEE ALSO

=over 4

=item * L<Role> - Companion role system for Class::More

=item * L<Moo> - Lightweight Moose-like OO system

=item * L<Mojo::Base> - Minimalistic base class for Mojolicious

=item * L<Object::Tiny> - Extremely lightweight class builder

=item * L<Class::Accessor> - Simple class builder with accessors

=item * L<Moose> - Full-featured object system

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Class-Mite>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Class-Mite/issues>.
I will be notified and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::More

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Class-Mite/issues>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and / or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Class::More
