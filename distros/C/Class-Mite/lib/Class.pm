package Class;

use strict;
use warnings;
use version;
use Exporter;
use mro ();

our $VERSION   = qv('v0.1.1');
our $AUTHORITY = 'cpan:MANWAR';

our @EXPORT = qw(extends with);
our @ISA    = qw(Exporter);

my %BUILD_METHODS_CACHE;
my %METHOD_COPY_CACHE;

# Precomputed skip patterns for faster method filtering
my %SKIP_METHODS = map { $_ => 1 } qw(
    BUILD new extends with does import AUTOLOAD DESTROY BEGIN END
    ISA VERSION EXPORT AUTHORITY INC
);

sub new {
    my $class = shift;
    my %attrs = @_;
    my $self = bless { %attrs }, $class;

    # Use cached BUILD methods for maximum performance
    my $build_methods = $BUILD_METHODS_CACHE{$class} ||= _compute_build_methods($class);
    $_->($self, \%attrs) for @$build_methods;

    return $self;
}

sub _compute_build_methods {
    my $class = shift;

    my @build_order;
    my %visited;

    # Depth-first traversal for true parent-first order
    _depth_first_traverse($class, \@build_order, \%visited);

    my @build_methods;
    foreach my $c (@build_order) {
        no strict 'refs';
        if (defined &{"${c}::BUILD"}) {
            push @build_methods, \&{"${c}::BUILD"};
        }
    }

    return \@build_methods;
}

sub _depth_first_traverse {
    my ($class, $order, $visited) = @_;

    return if $visited->{$class}++;

    no strict 'refs';
    my @parents = @{"${class}::ISA"};

    # Process all parents first (depth-first)
    foreach my $parent (@parents) {
        _depth_first_traverse($parent, $order, $visited);
    }

    # Then add current class
    push @$order, $class;
}

sub extends {
    my ($maybe_class, @maybe_parents) = @_;
    my $child_class = caller;

    _delete_build_cache($child_class);

    my @parents = @maybe_parents ? ($maybe_class, @maybe_parents) : ($maybe_class);

    no strict 'refs';

    for my $parent_class (@parents) {
        die "Recursive inheritance detected: $child_class cannot extend itself"
            if $child_class eq $parent_class;

        # Efficient parent loading - only load from disk if necessary
        unless ($INC{"$parent_class.pm"} || defined &{"${parent_class}::new"}) {
            (my $parent_file = "$parent_class.pm") =~ s{::}{/}g;
            eval { require $parent_file };
            # ignore errors - parent might be defined inline
        }

        # Link inheritance if not already linked
        unless (grep { $_ eq $parent_class } @{"${child_class}::ISA"}) {
            push @{"${child_class}::ISA"}, $parent_class;
        }

        # Copy public methods from parent to child for direct access
        _copy_public_methods($child_class, $parent_class);
    }
}

sub _copy_public_methods {
    my ($child, $parent) = @_;

    # Use cache to avoid re-copying methods for same parent-child pair
    my $cache_key = "$child|$parent";
    return if $METHOD_COPY_CACHE{$cache_key};
    $METHOD_COPY_CACHE{$cache_key} = 1;

    no strict 'refs';
    my $parent_symtab = \%{"${parent}::"};

    # Single pass with optimized checks
    for my $method (keys %$parent_symtab) {
        # Skip special methods and private methods quickly
        next if $SKIP_METHODS{$method};
        next if $method =~ /^_/;
        next if $method =~ /::$/;  # Skip nested packages

        # Skip if already defined in child or not a CODE ref in parent
        next if defined &{"${child}::${method}"};
        next unless defined &{"${parent}::${method}"};

        # Copy the method
        *{"${child}::${method}"} = \&{"${parent}::${method}"};
    }
}

sub _delete_build_cache {
    my ($class) = @_;
    delete $BUILD_METHODS_CACHE{$class};

    # Clear cache for all classes that inherit from this one
    for my $cached_class (keys %BUILD_METHODS_CACHE) {
        if (_inherits_from($cached_class, $class)) {
            delete $BUILD_METHODS_CACHE{$cached_class};
        }
    }

    # Also clear method copy cache for affected classes
    for my $cache_key (keys %METHOD_COPY_CACHE) {
        my ($child, $parent) = split(/\|/, $cache_key);
        if ($child eq $class || _inherits_from($child, $class)) {
            delete $METHOD_COPY_CACHE{$cache_key};
        }
    }
}

sub _inherits_from {
    my ($class, $parent) = @_;

    no strict 'refs';
    my @isa = @{"${class}::ISA"};

    return 1 if grep { $_ eq $parent } @isa;

    foreach my $direct_parent (@isa) {
        return 1 if _inherits_from($direct_parent, $parent);
    }

    return 0;
}

sub import {
    my ($class, @args) = @_;
    my $caller = caller;

    # Enable strict and warnings
    strict->import;
    warnings->import;

    # Load Role.pm if exists
    eval { require Role };
    if (!$@) {
        no strict 'refs';
        *{"${caller}::with"} = \&Role::with;
        *{"${caller}::does"} = \&Role::does;
    }

    # Install new and extends
    no strict 'refs';
    *{"${caller}::new"}     = \&Class::new;
    *{"${caller}::extends"} = \&Class::extends;

    # optional extends => Parent
    if (@args && $args[0] eq 'extends') {
        $class->extends(@args[1..$#args]);
    }
}

=head1 NAME

Class - Lightweight Perl object system with parent-first BUILD and method copying

=head1 VERSION

Version v0.1.1

=head1 SYNOPSIS

    use Class;

    # Simple class with attributes and BUILD
    package Person;
    use Class;

    sub BUILD {
        my ($self, $attrs) = @_;
        $self->{full_name} = $attrs->{first} . ' ' . $attrs->{last};
    }

    package Employee;
    use Class;
    extends 'Person';

    sub BUILD {
        my ($self, $attrs) = @_;
        $self->{employee_id} = $attrs->{id};
    }

    # Create an object
    my $emp = Employee->new(first => 'John', last => 'Doe', id => 123);

    print $emp->{full_name};   # John Doe
    print $emp->{employee_id}; # 123

    # Using roles if Role.pm is available
    package Manager;
    use Class;
    with 'SomeRole';
    my $mgr = Manager->new();

=head1 DESCRIPTION

Class provides a lightweight Perl object system with:

=over 4

=item * Parent-first constructor building via C<BUILD> methods.

=item * Simple inheritance via C<extends> with method copying.

=item * Optional role consumption via C<with> and C<does> (if C<Role> module is available).

=item * Automatic caching of BUILD order for efficient object creation.

=item * Optimized method copying for better performance.

=back

This module includes performance optimizations such as cached BUILD method resolution,
efficient parent class loading, and optimized method copying with caching.

=cut

=head1 BUILD METHODS

Classes can define a C<BUILD> method:

    sub BUILD {
        my ($self, $attrs) = @_;
        # initialize object
    }

All BUILD methods in the inheritance chain are called in parent-first order during C<new>. The order is determined by depth-first traversal, ensuring that parent classes are always initialized before their children.

For diamond inheritance patterns:

    A
   / \
  B   C
   \ /
    D

BUILD methods are called in the order: A, B, C, D (true parent-first order)

=head1 METHOD COPYING

This system copies public methods from parent classes to child classes. This design enables:

=over 4

=item * Direct method access in child symbol tables

=item * Proper functioning of object cloning

=item * Better performance for frequently called methods

=item * Compatibility with code that expects direct method access

=back

The following methods are NOT copied:

=over 4

=item * Special methods (BUILD, new, extends, with, does, import, AUTOLOAD, DESTROY)

=item * Private methods (starting with underscore)

=item * Package metadata (ISA, VERSION, EXPORT, etc.)

=back

=head1 ROLES

If a C<Role> module is available, you can consume roles via:

    with 'RoleName';
    does 'RoleName';

This provides role-based composition for shared behavior. The Role module must be installed separately.

=head1 PERFORMANCE OPTIMISATIONS

This version includes significant performance improvements:

=over 4

=item * Cached BUILD method resolution using depth-first parent-first order

=item * Precomputed skip patterns for fast method filtering

=item * Method copying cache to avoid duplicate operations

=item * Efficient parent class loading with minimal overhead

=item * Optimized symbol table scanning

=back

=head1 CACHING

Class uses internal caches to optimise performance:

=over 4

=item * C<%BUILD_METHODS_CACHE> - caches linearised parent-first build order

=item * C<%METHOD_COPY_CACHE> - tracks which parent-child pairs have had methods copied

=back

Caches are automatically updated when inheritance changes via C<extends>.

=head1 ERROR HANDLING

=over 4

=item * Recursive inheritance is detected and throws an exception.

=item * Failure to load a parent class is non-fatal (parent might be defined inline).

=back

=head1 EXAMPLES

=head2 Basic Inheritance with Method Copying

    package Animal;
    use Class;
    sub speak { "animal sound" }
    sub eat   { "eating" }

    package Dog;
    use Class;
    extends 'Animal';
    sub speak { "woof" }  # Overrides parent method

    my $dog = Dog->new;
    print $dog->speak;  # "woof" (from Dog)
    print $dog->eat;    # "eating" (copied from Animal)

    # Method is copied to Dog's symbol table
    no strict 'refs';
    print defined &Dog::eat ? "copied" : "not copied";  # "copied"

=head2 Diamond Inheritance

    package A;
    use Class;
    sub BUILD { print "A BUILD\n" }

    package B;
    use Class;
    extends 'A';
    sub BUILD { print "B BUILD\n" }

    package C;
    use Class;
    extends 'A';
    sub BUILD { print "C BUILD\n" }

    package D;
    use Class;
    extends 'B', 'C';
    sub BUILD { print "D BUILD\n" }

    my $d = D->new;
    # Output: A BUILD, B BUILD, C BUILD, D BUILD

=head2 Object Cloning with Method Copying

    package Base;
    use Class;
    sub clone_method { "works" }

    package Child;
    use Class;
    extends 'Base';

    my $original = Child->new;
    my $cloned = bless { %$original }, ref($original);

    # Works because methods are copied to Child
    print $cloned->clone_method;  # "works"

=head1 METHODS

=head2 new

    my $obj = Class->new(%attributes);

Constructs a new object of the class, calling all C<BUILD> methods from parent classes in parent-first order. All attributes are passed to C<BUILD> as a hashref.

The constructor uses cached BUILD method references for optimal performance, especially in deep inheritance hierarchies.

=cut

=head2 _compute_build_methods

    my $build_methods = _compute_build_methods($class);

Internal method that computes the BUILD methods in parent-first order using depth-first traversal.

This ensures BUILD methods are called from the root parent down to the child class, which is essential for proper initialisation in inheritance hierarchies.

=cut

=head2 _depth_first_traverse

    _depth_first_traverse($class, \@order, \%visited);

Internal recursive method that performs depth-first traversal of the inheritance hierarchy.

This method ensures that parent classes are always processed before their children, which is crucial for correct BUILD method ordering.

=cut

=head2 extends

    extends 'ParentClass';
    extends 'Parent1', 'Parent2';

Adds one or more parent classes to the calling class. This method:

=over 4

=item * Automatically loads parent classes if not already loaded

=item * Prevents recursive inheritance

=item * Copies public methods from parents to children

=item * Maintains inheritance via C<@ISA>

=item * Clears relevant caches to ensure consistency

=back

Method copying is performed to ensure that inherited methods are directly available in the child class's symbol table, which enables features like object cloning to work correctly.

=cut

=head2 _copy_public_methods

    _copy_public_methods($child_class, $parent_class);

Internal method that copies public methods from parent to child class. This method:

=over 4

=item * Skips special methods (BUILD, new, extends, etc.)

=item * Skips private methods (starting with underscore)

=item * Uses caching to avoid duplicate copying

=item * Only copies methods not already defined in child

=back

This optimised implementation uses precomputed skip patterns and caching for better performance.

=cut

=head2 _delete_build_cache

    _delete_build_cache($class);

Internal method that clears the BUILD methods cache for a class and all classes that inherit from it.

This ensures cache consistency when inheritance relationships change. Also clears method copy caches for affected classes.

=cut

=head2 _inherits_from

    _inherits_from($class, $parent);

Internal recursive method that checks if a class inherits from another class, either directly or indirectly.

Returns true if C<$class> inherits from C<$parent>, false otherwise.

=cut

=head1 IMPORT

    use Class;
    use Class 'extends' => 'Parent';

When imported, Class automatically installs the following functions into the caller's namespace:

=over 4

=item * C<new> - constructor

=item * C<extends> - inheritance helper

=item * C<with> and C<does> - if Role.pm is available

=back

Optionally, you can specify C<extends> in the import statement to immediately set a parent class:

    use Class 'extends' => 'Parent';

The import method also enables L<strict> and L<warnings> in the calling package.

=cut

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Class-Mite>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Class-Mite/issues>.
I will be notified and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class

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

1; # End of Class
