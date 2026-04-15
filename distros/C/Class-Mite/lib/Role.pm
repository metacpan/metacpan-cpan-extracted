package Role;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.1.1');
our $AUTHORITY = 'cpan:MANWAR';

our %REQUIRED_METHODS;
our %IS_ROLE;
our %EXCLUDED_ROLES;
our %APPLIED_ROLES;
our %METHOD_ALIASES;
our %ROLE_ATTRIBUTES;
our %METHOD_ORIGIN_CACHE;
our %ROLE_LOAD_CACHE;
our %CAN_HANDLE_ATTR_CACHE;
our %ROLE_METHODS_CACHE;

# Precomputed skip patterns
my %SKIP_METHODS = map { $_ => 1 } qw(
    BEGIN END import DESTROY new requires
    excludes IS_ROLE with has does
    AUTOLOAD VERSION AUTHORITY INC
);

sub import {
    my ($class, @args) = @_;
    my $caller = caller;
    no strict 'refs';

    $IS_ROLE{$caller} = 1;

    if (@args == 0) {
        $REQUIRED_METHODS{$caller} = [];
        *{"${caller}::requires"} = \&requires;
        *{"${caller}::excludes"} = \&excludes;
        *{"${caller}::has"} = \&_role_has;
    } else {
        _setup_role_application($caller, @args);
    }

    strict->import;
    warnings->import;
    _export_with($caller);
}

sub with {
    my (@roles) = @_;
    my $caller = caller;

    # Called inside a ROLE
    if ($IS_ROLE{$caller}) {
        my ($clean_roles_ref, $aliases_by_role)
            = _process_role_arguments(@roles);
        $METHOD_ALIASES{$caller} = $aliases_by_role;

        foreach my $role (@$clean_roles_ref) {
            _ensure_role_loaded($role);
            push @{ $APPLIED_ROLES{$caller} ||= [] }, $role;

            # Merge required methods
            if (my $req = $REQUIRED_METHODS{$role}) {
                push @{ $REQUIRED_METHODS{$caller} ||= [] }, @$req;
            }
        }

        return;
    }

    apply_role($caller, @roles);
}

sub requires {
    my (@methods) = @_;
    my $caller = caller;
    $REQUIRED_METHODS{$caller} = [] unless exists $REQUIRED_METHODS{$caller};
    push @{$REQUIRED_METHODS{$caller}}, @methods;
}

sub excludes {
    my (@excluded_roles) = @_;
    my $caller = caller;
    $EXCLUDED_ROLES{$caller} = [] unless exists $EXCLUDED_ROLES{$caller};
    push @{$EXCLUDED_ROLES{$caller}}, @excluded_roles;
}

sub apply_role {
    my ($class, @roles) = @_;
    my $target_class = ref($class) ? ref($class) : $class;
    my ($clean_roles_ref, $aliases_by_role) =
        _process_role_arguments(@roles);

    $METHOD_ALIASES{$target_class} = {
        %{$METHOD_ALIASES{$target_class} || {}},
        %$aliases_by_role
    };

    foreach my $role (@$clean_roles_ref) {
        _apply_single_role($target_class, $role);
    }

    _add_does_method($target_class);
    return 1;
}

sub get_applied_roles {
    my ($class) = @_;
    my $target_class = ref($class) ? ref($class) : $class;
    return @{$APPLIED_ROLES{$target_class} || []};
}

sub is_role {
    my ($package) = @_;
    return $IS_ROLE{$package};
}

sub Role::does {
    my ($class_or_obj, $role) = @_;
    return _class_does_role(ref($class_or_obj) || $class_or_obj, $role);
}

sub UNIVERSAL::does {
    my ($self, $role) = @_;
    return _class_does_role(ref($self) || $self, $role);
}

#
#
# PRIVATE FUNCTIONS

sub _get_role_methods_directly {
    my ($role) = @_;
    no strict 'refs';
    my $role_stash = \%{"${role}::"};
    my @methods;

    foreach my $name (keys %$role_stash) {
        next if $SKIP_METHODS{$name};
        next if $name =~ /^[A-Z_]+$/;  # skip constants
        my $glob = $role_stash->{$name};
        next unless defined *{$glob}{CODE};
        push @methods, $name;
    }

    return \@methods;
}

sub _class_can_handle_attributes {
    my ($class) = @_;
    return $CAN_HANDLE_ATTR_CACHE{$class}
        if exists $CAN_HANDLE_ATTR_CACHE{$class};

    my $result = 0;
    if ($class->can('can_handle_attributes')) {
        $result = $class->can_handle_attributes ? 1 : 0;
    }
    elsif ($class->can('has') && $class->can('extends')) {
        $result = 1;
    }
    else {
        no strict 'refs';
        $result = (grep { $_ eq 'Class::More' } @{"${class}::ISA"}) ? 1 : 0;
    }

    return $CAN_HANDLE_ATTR_CACHE{$class} = $result;
}

sub _ensure_role_loaded {
    my ($role) = @_;
    return if $ROLE_LOAD_CACHE{$role};

    unless ($IS_ROLE{$role}) {
        (my $role_file = "$role.pm") =~ s{::}{/}g;
        eval { require $role_file };
        if ($@) {
            die "Failed to load role '$role': $@\n" .
                "Make sure $role package uses 'use Role;' ".
                "and is properly defined";
        }
        $ROLE_LOAD_CACHE{$role} = 1;
        $IS_ROLE{$role} = 1;
        _cache_role_methods($role);
    }
}

sub _cache_role_methods {
    my ($role) = @_;
    no strict 'refs';
    my $role_stash = \%{"${role}::"};
    my @methods;

    foreach my $name (keys %$role_stash) {
        next if $SKIP_METHODS{$name};
        next if $name =~ /^[A-Z_]+$/;  # Skip constants
        my $glob = $role_stash->{$name};
        next unless defined *{$glob}{CODE};
        push @methods, $name;
    }

    $ROLE_METHODS_CACHE{$role} = \@methods;
}

sub _export_with {
    my $caller = shift;
    no strict 'refs';
    *{"${caller}::with"} = \&with unless defined &{"${caller}::with"};
}

sub _ensure_class_base {
    my $class = shift;
    return if $class->can('new');
    eval { require Class } unless $INC{'Class.pm'};
    no strict 'refs';
    push @{"${class}::ISA"}, 'Class'
        unless grep { $_ eq 'Class' } @{"${class}::ISA"};
}

sub _process_role_arguments {
    my (@args) = @_;
    my @roles;
    my %aliases_by_role;

    foreach my $arg (@args) {
        if (ref($arg) eq 'HASH' && $arg->{role}) {
            my $role = $arg->{role};
            push @roles, $role;
            if ($arg->{alias} && ref($arg->{alias}) eq 'HASH') {
                $aliases_by_role{$role} = $arg->{alias};
            }
        } else {
            push @roles, $arg;
        }
    }

    return \@roles, \%aliases_by_role;
}

sub _role_has {
    my ($attr_name, %spec) = @_;
    my $caller = caller;
    $ROLE_ATTRIBUTES{$caller}{$attr_name} = \%spec;
    no strict 'refs';
    *{"${caller}::${attr_name}"} = sub {
        my $self = shift;
        if (@_) {
            $self->{$attr_name} = shift;
        }
        return $self->{$attr_name};
    };
}

sub _apply_single_role {
    my ($class, $role) = @_;

    _ensure_class_base($class);
    _ensure_role_loaded($role);

    # Skip if already applied
    if ($APPLIED_ROLES{$class}
        && grep { $_ eq $role } @{$APPLIED_ROLES{$class}}) {
        warn "Role '$role' is already applied to class '$class'";
        return;
    }

    # Role exclusions
    if (my $excluded = $EXCLUDED_ROLES{$role}) {
        my @violated = grep { _class_does_role($class, $_) } @$excluded;
        if (@violated) {
            die "Role '$role' cannot be composed with role(s): @violated";
        }
    }

    # Apply role attributes
    _apply_role_attributes($class, $role);

    # Merge applied roles metadata
    push @{ $APPLIED_ROLES{$class} ||= [] }, $role;

    # Validate required methods (classes only)
    unless ($IS_ROLE{$class}) {
        my @missing;
        my $required = $REQUIRED_METHODS{$role} || [];

        # Get methods provided by the role being applied
        # so we don't treat them as missing.
        my @role_provides = @{$ROLE_METHODS_CACHE{$role}
            || _get_role_methods_directly($role)};
        my %role_provides = map { $_ => 1 } @role_provides;

        foreach my $method (@$required) {
            # Check if the method is missing AND not provided
            # by the role itself.
            unless ($class->can($method) || $role_provides{$method}) {
                push @missing, $method;
            }
        }
        if (@missing) {
            die "Role '$role' requires method(s) that are missing in ".
                "class '$class': " . join(', ', @missing);
        }
    }

    # Prepare methods and aliases
    my $aliases_for_role =
        $METHOD_ALIASES{$class}
        ? ($METHOD_ALIASES{$class}->{$role} || {}) : {};
    my @methods_to_copy =
        @{$ROLE_METHODS_CACHE{$role} || _get_role_methods_directly($role)};

    # Detect conflicts BEFORE installing
    my @conflicts;
    foreach my $name (@methods_to_copy) {
        my $install_name = $aliases_for_role->{$name} || $name;

        if ($class->can($install_name)) {
            my $origin = _find_method_origin($class, $install_name);
            # Skip class or same role
            next if $origin eq $class || $origin eq $role;
            my ($role1, $role2) = sort ($origin, $role);

            if ($install_name ne $name) {
                push @conflicts, {
                    method        => $name,
                    alias         => $install_name,
                    existing_role => $role1,
                    new_role      => $role2,
                    is_alias      => 1
                };
            } else {
                push @conflicts, {
                    method        => $install_name,
                    existing_role => $role1,
                    new_role      => $role2,
                    is_alias      => 0
                };
            }
        }
    }

    @conflicts = sort { $a->{method} cmp $b->{method} } @conflicts;

    if (@conflicts) {
        # Prefer alias conflicts first
        my ($first) = grep { $_->{is_alias} } @conflicts;
        $first ||= $conflicts[0];

        if ($first->{is_alias}) {
            die "Method conflict: $first->{method} (aliased to " .
                "$first->{alias}) between $first->{existing_role} " .
                "and $first->{new_role}";
        } else {
            die "Method conflict: method '$first->{method}' provided " .
                "by both '$first->{existing_role}' " .
                "and '$first->{new_role}'";
        }
    }

    # Install methods
    unless ($IS_ROLE{$class}) {
        no strict 'refs';
        no warnings 'redefine';
        foreach my $name (@methods_to_copy) {
            my $install_name = $aliases_for_role->{$name} || $name;
            next if $class->can($install_name); # class method wins
            *{"${class}::${install_name}"} = *{"${role}::${name}"}{CODE};
        }
    }

    # Add role to @ISA
    no strict 'refs';
    push @{"${class}::ISA"}, $role
        unless grep { $_ eq $role } @{"${class}::ISA"};

    # Add does() method
    _add_does_method($class);
}

sub _apply_role_attributes {
    my ($class, $role) = @_;
    my $role_attrs = $ROLE_ATTRIBUTES{$role} || {};
    my $can_handle_attributes = _class_can_handle_attributes($class);

    if (!$can_handle_attributes && %$role_attrs) {
        return;
    }

    eval { require Class::More };
    return if $@;

    no strict 'refs';
    foreach my $attr_name (keys %$role_attrs) {
        my $attr_spec = $role_attrs->{$attr_name};
        $Class::More::ATTRIBUTES{$class} = {}
            unless exists $Class::More::ATTRIBUTES{$class};
        $Class::More::ATTRIBUTES{$class}{$attr_name} = $attr_spec;

        if (!defined *{"${class}::${attr_name}"}{CODE}) {
            *{"${class}::${attr_name}"} = sub {
                my $self = shift;
                if (@_) {
                    $self->{$attr_name} = shift;
                }
                return $self->{$attr_name};
            };
        }
    }
}

sub _find_method_origin {
    my ($class, $method) = @_;
    my $cache_key = "$class|$method";
    return $METHOD_ORIGIN_CACHE{$cache_key}
        if exists $METHOD_ORIGIN_CACHE{$cache_key};

    no strict 'refs';

    # First check if method exists in the class itself
    if (defined &{"${class}::${method}"}) {
        # Check if it comes from an applied role
        if ($APPLIED_ROLES{$class}) {
            foreach my $role (@{$APPLIED_ROLES{$class}}) {
                my $aliases = $METHOD_ALIASES{$class}->{$role} || {};
                my %reverse_aliases = reverse %$aliases;
                my $original_name = $reverse_aliases{$method} || $method;

                if (defined &{"${role}::${original_name}"}
                    || exists $reverse_aliases{$method}) {
                    return $METHOD_ORIGIN_CACHE{$cache_key} = $role;
                }
            }
        }
        # If not from a role, it's from the class itself
        return $METHOD_ORIGIN_CACHE{$cache_key} = $class;
    }

    # Check inheritance chain
    for my $parent (@{"${class}::ISA"}) {
        if ($parent->can($method)) {
            return $METHOD_ORIGIN_CACHE{$cache_key} = $parent;
        }
    }

    return $METHOD_ORIGIN_CACHE{$cache_key} = '';
}

sub _class_does_role {
    my ($class, $role) = @_;
    return 0 unless $IS_ROLE{$role};
    no strict 'refs';
    return 1 if grep { $_ eq $role } @{"${class}::ISA"};
    return 1 if ($APPLIED_ROLES{$class}
                && grep { $_ eq $role } @{$APPLIED_ROLES{$class}});
    return 0;
}

sub _add_does_method {
    my ($class) = @_;
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::does"} = sub {
        my ($self, $role) = @_;
        return _class_does_role(ref($self) || $self, $role);
    };
}

=head1 NAME

Role - A simple role system for Perl

=head1 VERSION

Version v0.1.1

=head1 SYNOPSIS

=head2 Creating Roles

    package Role::Printable;
    use Role;

    requires 'to_string';  # Classes must implement this

    sub print {
        my $self = shift;
        print $self->to_string . "\n";
    }

    1;

    package Role::Serialisable;
    use Role;

    requires 'serialize', 'deserialize';

    sub to_json {
        my $self = shift;
        # ... implementation
    }

    1;

=head2 Using Roles in Classes

    package My::Class;
    use Class;
    with qw/Role::Printable Role::Serialisable/;

    sub to_string {
        my $self = shift;
        return "My::Class instance";
    }

    sub serialize   { ... }
    sub deserialize { ... }

    1;

=head2 Applying Roles at Runtime

    package My::Class;
    use Class;

    # Later, apply roles dynamically
    Role::apply_role(__PACKAGE__, 'Role::Printable');

    1;

=head2 Role Aliasing

    package My::Class;
    use Class;
    use Role::Printable => {
        role  => 'Role::Printable',
        alias => { print => 'display' }
    };

    # Now use $obj->display() instead of $obj->print()

=head2 Role Composition with Exclusions

    package Role::A;
    use Role;
    excludes 'Role::B';  # Cannot be used with Role::B

    package Role::B;
    use Role;

    package My::Class;
    use Class;
    use Role::A;    # OK
    # use Role::B;  # This would die

=head1 DESCRIPTION

Role provides a simple, efficient role system for Perl. Roles are reusable units
of behavior that can be composed into classes. They support requirements,
method conflicts detection, aliasing, and runtime application.

This module is designed to work with any class system but integrates particularly
well with L<Class::More>.

=head1 FEATURES

=head2 Core Features

=over 4

=item * B<Method Requirements>: Roles can declare methods that consuming classes must implement

=item * B<Conflict Detection>: Automatic detection of method conflicts between roles

=item * B<Method Aliasing>: Rename methods when applying roles to avoid conflicts

=item * B<Role Exclusion>: Roles can declare incompatible roles

=item * B<Runtime Application>: Apply roles to classes at runtime

=item * B<Basic Attribute Support>: Simple attribute storage with accessors

=item * B<Performance Optimized>: Method and role caching for better performance

=item * B<Class Method Priority>: Class methods silently override role methods

=back

=head2 Advanced Features

=over 4

=item * B<Batch Conflict Detection>: Detects conflicts between multiple roles before application

=item * B<Sequential Application>: Supports applying roles one at a time with proper conflict checking

=item * B<Inheritance Awareness>: Understands method inheritance chains

=item * B<Role Composition Tracking>: Tracks which roles are applied to each class

=back

=head1 METHODS

=head2 Role Definition Methods

These methods are available in packages that C<use Role>.

=head3 requires

    requires 'method1', 'method2';

Declares that consuming classes must implement the specified methods.

=head3 excludes

    excludes 'Role::Incompatible', 'Role::Conflicting';

Declares that this role cannot be composed with the specified roles.

=head3 has

    has 'attribute_name';
    has 'attribute_name' => ( default => 'value' );

Defines a simple attribute in the role. Creates a basic accessor method.
The attribute specification can include:

=over 4

=item * C<default> - Default value for the attribute

=back

Note: This provides basic attribute storage. For advanced attribute features
like type constraints, coercion, or lazy building, use a full-featured
class system.

=head2 Role Application Methods

=head3 with

    package My::Class;
    use Class;

    with 'Role::A', 'Role::B';

    # With aliasing
    with
        { role => 'Role::A', alias => { method_a => 'new_name' } },
        'Role::B';

Composes roles into a class. Can be called as a class method.

=head3 apply_role

    Role::apply_role('My::Class', 'Role::Printable');
    Role::apply_role($object, 'Role::Serialisable');

Applies a role to a class or object at runtime. Returns true on success.

=head2 Query Methods

=head3 does

    if ($object->does('Role::Printable')) {
        $object->print;
    }

Checks if a class or object consumes a specific role.

=head3 get_applied_roles

    my @roles = Role::get_applied_roles('My::Class');
    my @roles = Role::get_applied_roles($object);

Returns the list of roles applied to a class.

=head3 is_role

    if (Role::is_role('Role::Printable')) {
        # It's a role
    }

Checks if a package is a role.

=head1 EXAMPLES

=head2 Basic Role with Requirements

    package Role::Validator;
    use Role;

    requires 'validate', 'get_errors';

    sub is_valid {
        my $self = shift;
        return $self->validate && !@{$self->get_errors};
    }

    1;

=head2 Role with Simple Attributes

    package Role::Timestamped;
    use Role;

    has 'created_at' => ( default => sub { time } );
    has 'updated_at' => ( default => sub { time } );

    sub update_timestamp {
        my $self = shift;
        $self->updated_at(time);
    }

    1;

    # Usage in class:
    package My::Class;
    use Class;
    with qw/Role::Timestamped/;

    sub new {
        my ($class, %args) = @_;
        my $self = bless \%args, $class;
        $self->created_at(time) unless $self->created_at;
        return $self;
    }

    1;

=head2 Role with Aliasing

    package My::Class;
    use Class;

    # Avoid conflict by aliasing
    with
        { role => 'Role::Logger', alias => { log => 'file_log' } },
        { role => 'Role::Debug', alias => { log => 'debug_log' } };

    sub log {
        my ($self, $message) = @_;
        $self->file_log($message);
        $self->debug_log($message);
    }

    1;

=head2 Runtime Role Application

    package PluginSystem;
    use Role;

    sub load_plugin {
        my ($self, $plugin_role) = @_;

        unless (Role::is_role($plugin_role)) {
            die "$plugin_role is not a role";
        }

        # Apply the plugin role to this instance's class
        Role::apply_role($self, $plugin_role);

        return $self;
    }

    1;

=head1 ATTRIBUTE SUPPORT

The C<has> method in roles provides basic attribute functionality:

=over 4

=item * Creates a simple accessor method

=item * Supports default values

=item * Stores data in the object hash

=back

However, this is I<basic> attribute support. For advanced attribute features
like:

=over 4

=item * Read-only/read-write access control

=item * Type constraints

=item * Lazy evaluation

=item * Triggers and coercion

=item * Initialisation hooks

=back

You should use a full-featured class system like L<Moose>, L<Moo>, or
L<Object::Pad> and apply roles from those systems instead.

=head1 PERFORMANCE

The module includes several performance optimisations:

=over 4

=item * Method origin caching to avoid repeated lookups

=item * Role loading caching to prevent redundant requires

=item * Precomputed role method lists

=item * Skip patterns for common non-method symbols

=back

For best performance, apply roles at compile time when possible.

=head1 LIMITATIONS

=head2 Known Limitations

=over 4

=item * B<Basic Attribute Support>:

    Only simple attributes with default values are supported. No advanced features like read-only, type constraints, or lazy building.

=item * B<Inheritance Complexity>:

    Deep inheritance hierarchies may have unexpected method resolution behavior.

=item * B<Sequential Application>:

    Applying roles sequentially vs. batched can produce different conflict detection results.

=item * B<Method Modification>:

    Does not support method modifiers (before, after, around) like Moose roles.

=item * B<Role Parameters>:

    Roles cannot take parameters at composition time.

=item * B<Diamond Problem>:

    Limited handling of diamond inheritance patterns in role composition.

=item * B<Meta Information>:

    No rich meta-object protocol for introspection.

=back

=head2 Attribute Limitations

The attribute system is intentionally minimal:

    # Supported:
    has 'name';
    has 'count' => ( default => 0 );
    has 'items' => ( default => sub { [] } );

    # NOT supported:
    has 'name' => ( is => 'ro' );       # No access control
    has 'count' => ( isa => 'Int' );    # No type constraints
    has 'items' => ( lazy => 1 );       # No lazy building
    has 'score' => ( trigger => \&_validate_score );  # No triggers

=head2 Conflict Resolution Limitations

=over 4

=item * Class methods always silently win over role methods

=item * No built-in way to explicitly override role methods

=item * No method selection or combination features

=item * Aliasing is the primary conflict resolution mechanism

=back

=head2 Compatibility Limitations

=over 4

=item * Designed to work with simple class systems and L<Class::More>

=item * May have issues with some class builders that don't follow standard Perl OO

=item * No Moose/Mouse compatibility layer

=item * Limited support for role versioning

=back

=head1 DIAGNOSTICS

=head2 Common Errors

=over 4

=item * C<"Failed to load role 'Role::Name': ...">

The specified role could not be loaded. Make sure the role package exists and uses C<use Role;>.

=item * C<"Conflict: method 'method_name' provided by both 'Role::A' and 'Role::B'...">

Method conflict detected. Use aliasing or role exclusion to resolve.

=item * C<"Role 'Role::Name' requires method(s) that are missing...">

The class doesn't implement all required methods specified by the role.

=item * C<"Role 'Role::A' cannot be composed with role(s): Role::B">

Role exclusion violation.

=item * C<"ROLE WARNING: Role 'Role::Name' has attributes that will be ignored">

Role defines attributes but the class doesn't support attribute handling.

=back

=head1 SEE ALSO

=over 4

=item * L<Class::More> - Simple class builder that works well with Role

=item * L<Moose::Role> - Full-featured role system for Moose

=item * L<Mouse::Role> - Lightweight Moose-compatible roles

=item * L<Role::Tiny> - Minimalist role system

=item * L<Moo::Role> - Roles for Moo classes

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

    perldoc Role

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

1; # End of Role

