# NAME

Class::DbC - Add Design By Contract easily and flexibly to existing code.

# SYNOPSIS

    # Some existing class
    package Example;

    sub new {
        # code not shown
    }

    sub do_something {
        # code not shown
    }

    # A contract
    package Example::Contract;

    use Class::DbC
        interface => {
            do_something => {
                precond => {
                    a_description => sub {
                        # return true if precondition is satistifed
                    },
                },
                postcond => {
                    a_description => sub {
                        # return true if postcondition is satistifed
                    },
                }
            },
            new => {
                # contracts not shown
            }
        },
        invariant => {
            a_description => sub {
                # return true if invariant is satistifed
            },
        },
    ;

    # A program
    package main;
    use Example;
    use Example::Contract;

    Example::Contract->govern('Example');

    my $e = Example->new(...);
    $e->do_something();

# DESCRIPTION

Class::DbC allows Eiffel style [Contracts](https://www.eiffel.com/values/design-by-contract/introduction/) to be easily and flexibly added to existing code.

These contracts are separate from the code that they verify, and they can be turned on or not (or even off) at runtime.

# USAGE

## Defining a contract

A contract is a package defined by using Class::DbC and providing a configuration hash with the following keys

### interface

The value of this key is a hash that describes the interface (methods called by users of the class) of the class being verified.

This hash maps the name of a method to a contract hash which in turn has the following keys:

#### precond (preconditions)

The corresponding value is a hash of description => subroutine pairs.

Each such subroutine is a method that receives the same parameters as the method the precondition is attached to,
and returns either a true or false result. If false is returned, an exception is raised indicating which precondition
was violated.

A precondition is an assertion that is run before a given method, that defines one or more conditions that must
be met in order for the given method to be callable.

#### postcond (postconditions)

The corresponding value is a hash of description => subroutine pairs.

Each such subroutine is a method that receives the following parameters: the object as it is after the method call,
the object as it was before the method call, the results of the method call stored in array ref, and any parameters
that were passed to the method.

The subroutine should return either a true or false result. If false is returned, an exception is raised indicating which postcondition was violated.

A postcondition is an assertion that is run after a given method, that defines one or more conditions that must
be met after the given method has been called.

### invariant

The value of this key is a hash of description => subroutine pairs that describes the invariants of the class being verified.

Each such subroutine is a method that receives the object as its only parameter, and returns either a true or false result. If false is returned, an exception is raised indicating which invariant
was violated.

An invariant is an assertion that is run before and after every method in the interface, that defines one or more conditions that must be met before and after the method has been called.

### extends

The value of this key is the name of another contract (the parent) which the one being defined (the child) will extend i.e. any specifications in the parent that are not found in the child contract will be copied to the child contract.

### clone\_with

If the target objects can't be cloned with the [Storable](https://metacpan.org/pod/Storable) module's `dclone` function, then use this to specify a coderef that returns a deep clone of the object.

### constructor\_name

If the constructor of the target class is not named "new", use this to specify its name.

## Applying a contract

Once defined, a contract package is able to call its `govern` method to verify the behaviour of the target class.

### govern(TARGET, \[{ OPTIONS }\])

The `govern` class method expects to be given the name of the target class and an optional hashref of boolean options which are as follows

#### pre

Preconditions wil be enabled if this value is true.

#### post

Postconditions wil be enabled if this value is true.

#### invariant

Invariants wil be enabled if this value is true.

#### all

All contract types wil be enabled if this value is true. This is the assumed behaviour if no options are given.

#### emulate

If this option is true, `govern` will not modify the target class, but will return a new class that emulates the target class but is governed by the contract. This emulation can have its contracts adjusted at run time by making further calls to `govern`.

# EXAMPLES

## The Target Class

In this example we create a contract to govern the following bounded queue class.

This is a type of queue that can never have more than the number of items specified at creation time.

The queue maintains a fixed maximum size by evicting items at the front of the queue.

    package Example::BoundedQueue;

    sub new {
        my( $class, $size ) = @_;

        bless {
            max_size => $size,
            items => [],
        }, $class;
    }

    sub head {
        my( $self ) = @_;

        $self->{ items }[0];
    }

    sub tail {
        my( $self ) = @_;

        $self->{ items }[-1];
    }

    sub max_size {
        my( $self ) = @_;

        $self->{ max_size };
    }

    sub size {
        my $self = shift;

        scalar @{ $self->{ items } };
    }

    sub pop {
        my $self = shift;

        shift @{ $self->{ items } };
    }

    sub push {
        my( $self, $item ) = @_;

        shift @{ $self->{ items } } if @{ $self->{ items } } == $self->{ max_size };

        push @{ $self->{ items } }, $item;
    }

    1;

## Defining the contract

The contract is the following package:

    package Example::Contract::BoundedQueue;

    use Class::DbC
        interface => {
            new => {
                precond => {
                    positive_int_size => sub {
                        my (undef, $size) = @_;
                        $size =~ /^\d+$/ && $size > 0;
                    },
                },
                postcond => {
                    zero_sized => sub {
                        my ($obj) = @_;
                        $obj->size == 0;
                    },
                }
            },
            head => {},
            tail => {},
            size => {},
            max_size => {},

            push => {
                postcond => {
                    size_increased => sub {
                        my ($self, $old) = @_;

                        return $self->size < $self->max_size
                            ? $self->size == $old->size + 1
                            : 1;
                    },
                    tail_updated => sub {
                        my ($self, $old, $results, $item) = @_;
                        $self->tail == $item;
                    },
                }
            },

            pop => {
                precond => {
                    not_empty => sub {
                        my ($self) = @_;
                        $self->size > 0;
                    },
                },
                postcond => {
                    returns_old_head => sub {
                        my ($self, $old, $results) = @_;
                        $results->[0] == $old->head;
                    },
                }
            },
        },
        invariant => {
            max_size_not_exceeded => sub {
                my ($self) = @_;
                $self->size <= $self->max_size;
            },
        },
    ;

    1;

The contract constrains the behaviour of its target package in various ways:

- The precondition on `new` requires that its argument is a positive integer.
- The postconditions on `push` ensure that the queue size increases by one after a push, and that the newly pushed item is at the back of the queue.
- The postcondition on `pop` ensures that a popped item was previously at the front of the queue.
- The invariant ensures that the queue never exceeds its maximum size.

## Applying the contract

A short script showing how the contract is applied:

    use strict;
    use Test::More;
    use Example::BoundedQueue;
    use Example::Contract::BoundedQueue;

    Example::Contract::BoundedQueue::->govern('Example::BoundedQueue');

    my $q = Example::BoundedQueue::->new(3);

    $q->push($_) for 1 .. 3;
    is $q->size => 3;

    $q->push($_) for 4 .. 6;
    is $q->size => 3;
    is $q->pop => 4;
    done_testing();

In this case, all of the contract types are active. It is also possible to activate only certain contract types e.g.

    Example::Contract::BoundedQueue::->govern('Example::BoundedQueue', { invariant => 1 });

will only active invariant checking.

## Emulation

Contracts can also be actived in emulation mode, which alows them to be toggled at run time e.g.

    my $target_class = 'Example::BoundedQueue';

    my $emulation = Example::Contract::BoundedQueue::->govern($target_class, { emulate => 1 });

    # all contract types in force
    my $q = $emulation->new(3);

    Example::Contract::BoundedQueue::->govern($target_class, { emulate => 1, pre=>1, invariant=>1 });
    # postconditions turned off

    Example::Contract::BoundedQueue::->govern($target_class, { emulate => 1, pre=>1 });
    # invariants turned off

    Example::Contract::BoundedQueue::->govern($target_class, { emulate => 1, pre=>0 });
    # preconditions turned off, so all contracts are now ignored

# SEE ALSO

[Class::Contract](https://metacpan.org/pod/Class::Contract)

[Class::Agreement](https://metacpan.org/pod/Class::Agreement)

# BUGS

Please report any bugs or feature requests via the GitHub [issue tracker](https://github.com/arunbear/Class-DbC/issues).

# COPYRIGHT

Copyright 2018- Arun Prasaad

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU public license, version 3.
