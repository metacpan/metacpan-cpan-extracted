#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# -------------------
# 1. Define a Role
# -------------------
package Loggable;

use Role;
requires qw/get_name/;

sub log_message {
    my ($self, $action) = @_;
    return "User: " . $self->get_name() . " did: $action";
}

# -------------------
# 2. Define a Class that consumes the role and uses BUILD
# -------------------
package MyClass;

use Class;
with qw/Loggable/;

# A method to satisfy the role requirement
sub get_name {
    return $_[0]->{name};
}

# The BUILD hook, which we will use to check if the constructor was run
sub BUILD {
    my ($self, $args) = @_;

    # Check if we received constructor arguments (the hash ref)
    die "BUILD did not receive arguments!" unless ref $args eq 'HASH';

    # Modify the object after construction
    $self->{initialized} = 1;
    $self->{full_name}   = $args->{name} . ' ' . $args->{surname};
    delete $self->{surname}; # Clean up an initial argument
    return $self;
}

# A simple accessor to check the BUILD modifications
sub get_full_name {
    return $_[0]->{full_name};
}

# A simple accessor to check the BUILD flag
sub is_initialized {
    return $_[0]->{initialized};
}

package main;

# --- Test 1: Instantiation using Class::new (via Class) ---
my $object = MyClass->new(
    name    => 'Jane',
    surname => 'Doe',
    id      => 123,
);

ok( defined $object, '1. Object was successfully instantiated' );
is( ref $object, 'MyClass', '2. Object is blessed into the correct class' );


# --- Test 2: BUILD Method Execution Check ---
is( $object->is_initialized, 1, '3. BUILD method was executed (checked flag)' );


# --- Test 3: BUILD Method Argument Handling Check ---
is( $object->get_full_name, 'Jane Doe', '4. BUILD successfully processed and merged arguments' );
ok( !exists $object->{surname}, '5. BUILD successfully deleted the surname argument' );


# --- Test 4: Role Method Composition Check ---
ok( $object->can('log_message'), '6. Role method (log_message) was successfully composed' );


# --- Test 5: Role Requirement Satisfaction Check ---
my $log = $object->log_message('checked out');
is( $log, 'User: Jane did: checked out', '7. Role method executed correctly, calling class method (get_name)' );


# --- Test 6: Class Integration Check (does method) ---
ok( $object->does('Loggable'), '8. Object reports correctly that it does the role' );

done_testing;
