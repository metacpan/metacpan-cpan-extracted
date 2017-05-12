#!/usr/bin/perl

=head1 NAME

Class::Mutator - Run-time Dynamic Multiple Inheritance

=head1 SYNOPSIS

  package Frog;
  use Class::Mutator qw( -isasubclass );
  sub new { ... }
  sub eat_flies { ... }

  package Prince;
  sub be_charming { ... }

  my $froggie = Frog->new;
  $froggie->mutate('Prince');

  # Now the froggie has been reblessed into a "Frog Prince"
  # class and can take advantage of methods in both classes.
  $froggie->eat_flies;
  $froggie->be_charming;

=head1 DESCRIPTION

Class::Mutator adds the power of "dynamic polymorphism" to Perl
objects.

Any object that inherits Class::Mutator principally gains two new
methods, mutate and unmutate that allows them to add methods to
themselves at runtime from other packages. The most recently mutated
packages take precedence when methods with the same name are defined
in more than one package.

This module is similar to Sex.pm, which Michael Schwern was working
on around the same time, only a little bit more predictable. It
came about while I was doing some training at the BBC and someone
asked how you could do this easily; after discussion with my fellow
London.pm'ers, in particular Piers Cawley, this module came about.

More recently Matthew Simon Cavalletto sent me a version with
everything I had been meaning to do on the module a little after I
uploaded version 0.03 which only had more substantial tests. So major
kudos to Matthew.

=head1 USE

To enable a class of objects to mutate, make it a subclass of
Class::Mutator.

  package MyBaseClass;
  use Class::Mutator;
  push @ISA, 'Class::Mutator';
  ...
  MyBaseClass->new()->mutate( ... );

As a shortcut, you may pass the C<-isasubclass> flag in your use
statement, which will produce the same result.

  package MyBaseClass;
  use Class::Mutator '-isasubclass';
  ...
  MyBaseClass->new()->mutate( ... );

Finally, if you need to retroactively add mutation capabilities to
an existing class, you can do so using the same syntax, with the
target class passeds as a parameter.

  package main;
  use MyBaseClass;
  use Class::Mutator '-isasubclass' => 'MyBaseClass';
  MyBaseClass->new()->mutate( ... );

You can also import the specific methods and functions described
below and call them directly.

  package main;
  use MyBaseClass;
  use Class::Mutator 'mutate';
  mutate( MyBaseClass->new(), ... );

=cut

package Class::Mutator;
$VERSION='0.04';

@EXPORT_OK = qw( mutate unmutate apply_mutation modify_mutation_list
                 get_mutation_list build_mutation_package );

sub import {
  my $class = shift;

  if ( ! scalar @_ ) {
    return;
  } elsif ( $_[0] eq '-isasubclass' ) {
    my $target_class = $_[1] || ( caller )[0];
    no strict 'refs';
    push @{"$target_class\::ISA"}, $class
      unless ( grep { $_ eq $class } @{"$target_class\::ISA"} );
  } else {
    require Exporter and goto &Exporter::import # lazy Exporter
  }
}

use strict;

=head1 METHODS

These methods provide the module's public object-oriented interface.

=head2 mutate

  $object->mutate( @packages );

Adds a mutation.

=cut

sub mutate {
    my $self = shift;
    my @packages = @_;
    apply_mutation($self, '+', @packages);
}

=head2 unmutate

  $object->unmutate( @packages );

Remove mutation abilities via a package

=cut

sub unmutate {
    my $self = shift;
    my @packages = @_;
    apply_mutation($self, '-', @packages);
}


=head1 FUNCTIONS

These functions are used internally to support the methods described
above.

=head2 apply_mutation

  $reblessed_object = apply_mutation( $object, $op, @packages );

Builds a new package list, based on the current package for a given
object, the operator (either "+" or "-"), and the packages to be
added or removed.

=cut

sub apply_mutation {
    my $self = shift;
    bless $self, build_mutation_package( modify_mutation_list( $self, @_ ) )
}

=head2 get_mutation_list

  @packages = get_mutation_list($object_or_class);

Returns the list of classes a mutated object is based on. If the
object is not a mutant, its normal class name will be returned.

=cut

sub get_mutation_list {
    my $self = shift;

    my $curr = ref($self) || $self;

    if ($curr =~ s/^Class::Mutator:://) {
        return map { s/__/::/g; $_ } split /::/,$curr;
    } else {
        return $curr
    }
}

=head2 build_mutation_package

  $new_class_name = build_mutation_package(@packages);

Builds the new mutation package. Returns the name of the new class.

=cut

sub build_mutation_package {
    my @class_list = @_;
    my @ingredients = map { s/::/__/g; $_ } @class_list;
    my $package_name = 'Class::Mutator::'.join('::',@ingredients);

    # If our target class has an inheritance tree, we've already
    # set it up on a previous invocation, so there's nothing to do.
    no strict 'refs';
    unless ( scalar @{$package_name . '::ISA'} ) {
        @{$package_name . '::ISA'} = reverse @class_list;
    }
    return $package_name;
}

=head2 modify_mutation_list

  @packages = modify_mutation_list($object_or_class, $op, @packages);

Builds a new package list based on the current packages list and the
operation and package (the operation is upon) handed to this method.

=cut

sub modify_mutation_list {
  my $self = shift;
  my ($op, @packages) = @_;

  my @active_classes = get_mutation_list( $self );

  foreach my $package ( @packages ) {
    @active_classes = grep { $_ ne $package } @active_classes;
  }

  if ($op eq '+') {
    push(@active_classes, @packages);
  } elsif ($op eq '-') {
    # We've already got this functionality out of the grep above
  } else {
    # Invalid operation
  }

  return @active_classes;
}

=head1 AUTHORS

Greg McCarroll
Mail     : greg@mccarroll.demon.co.uk
Jabber   : greg@jabber.mccarroll.org.uk
Homepage : http://www.mccarroll.org.uk/~gem/

Matthew Simon Cavalletto
Mail     : simonm@cavalletto.org,
Homepage : http://www.evoscript.org/

=cut

1;
