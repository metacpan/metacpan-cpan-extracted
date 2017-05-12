package Class::Anonymous;

use strict;
use warnings;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

use Class::Anonymous::Instance;

use Exporter 'import';
our @EXPORT = qw/class extend via/;

use List::Util 'first';
use Scalar::Util 'refaddr';

my $bless = eval {
  require Package::Anon;
  my $stash = Package::Anon->new;
  $stash->add_method(AUTOLOAD => \&Class::Anonymous::Instance::AUTOLOAD);
  $stash->add_method(DESTROY  => \&Class::Anonymous::Instance::DESTROY);
  $stash->add_method(can => \&Class::Anonymous::Instance::can);
  $stash->add_method(isa => \&Class::Anonymous::Instance::isa);
  sub { $stash->bless($_[0]) };
} || sub { bless $_[0], 'Class::Anonymous::Instance' };

our $CURRENT;

my $new = sub {
  my $class = shift;
  my @isa = $class->isa();
  push @isa, $class;
  my $self = instance(@isa);
  local $CURRENT = $self;
  $_->('BUILD')->($self, @_) for @isa;
  return $self;
};

sub instance {
  my @isa = @_;
  my %methods;

  my $isa = sub {
    my $self = shift;
    return @isa unless @_;
    my $class = shift;
    return unless ref $class;
    my $addr = refaddr $class;
    return first { $addr == refaddr $_ } reverse @isa;
  };

  return $bless->(sub {
    return unless my $name = shift;
    return $isa if $name eq 'isa';
    return $new if $name eq 'new';
    $methods{$name} = shift if @_;
    return $methods{$name};
  });
};

sub class (&) {
  my $builder = shift;
  my $class = instance(@_);
  $class->(BUILD => $builder);
  return $class;
}

sub extend {
  my ($class, $extension) = @_;
  my @isa = $class->isa();
  return &class($extension, @isa, $class);
}

sub via (&) { $_[0] }

1;

=head1 NAME

Class::Anonymous - Truly private classes with private data for Perl5

=head1 SYNOPSIS

  use feature 'say';
  use Class::Anonymous;
  use Class::Anonymous::Utils ':all';

  my $lifeform = class {
    my ($self, $name) = @_;
    method greeting => sub { "My name is $name" };
  };

  my $mortal = extend $lifeform => via {
    my ($self, $name, $age) = @_;
    around greeting => sub {
      my $orig = shift;
      $orig->() . " and I'm $age years old";
    };
  };

  my $bob = $mortal->new('Bob', 40);
  say $bob->greeting;
  say 'Bob is mortal' if $bob->isa($mortal);
  say 'Bob is a lifeform' if $bob->isa($lifeform);

=head1 DESCRIPTION

L<Class::Anonymous> implements anonymous classes and private data.
This private data is just the lexical variables available during the builder callback(s) that are used to build the class.
If L<Package::Anon> is available, then no stash entry is created at all.
If not, then the classes will actually be blessed into L<Class::Anonymous::Instance> though this is to be considered an implementation detail and subject to change.

The instance itself is a code reference which can be thought of as a meta-object.
Called with a single string fetches the method of that name and returns it.
Called with a string and a code reference attaches a new method to the object.
Helper functions are provided in L<Class::Anonymous::Utils> which provides L<Class::Anonymous::Utils/method> and method modifiers for ease of use.

  my $class = class {
    my ($self) = @_;
    $self->(mymethod = sub { ... });
    my $mymethod = $self->('mymethod');
  }

=head1 EXPORTED FUNCTIONS

=head2 class

  my $class = class { my ($self) = @_; ... };

Define a new class.
Takes a block (or code reference) which will be called to build and instance of that class.
The callback is called with the new empty instance and any arguments passed to C<new>.
Note that subclasses might need more initialization arguments, so you might want to plan for that.

=head2 extend

  my $subclass = extend $class, sub { my ($self) = @_; ... };

Define a new subclass of an existing anonymous class.
Takes an existing class and a code reference which will be called after the parent class builder callback(s).
Note that all callbacks receive the same arguments, so you might want to plan for that.

=head2 via

  my $subclass = extend $class, via { my ($self) = @_; ... };

Sugar for defining a code reference as a block, simply to make L</extend> look better.

=head1 OTHER FUNCTIONS

=head2 instance

Builds a raw instance of a generic anonymous object.
All arguments are the classes to be returned by C<isa>.
By default it only fully implements the C<isa>, C<AUTOLOAD> and C<DESTROY> methods.
If the instance implements the C<BUILD> method then it is itself a class and you can call C<new> on it.

=head3 Relationship to the class function

The L</class> function simply creates an C<instance> when it creates a class.
It then attaches a C<BUILD> function; this function creates another instance, calls all the C<BUILD> methods from all the C<isa> classes on it, then returns it.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Class-Anonymous>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
