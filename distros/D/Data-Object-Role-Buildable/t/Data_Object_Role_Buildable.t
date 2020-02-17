use 5.014;

use strict;
use warnings;

use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Buildable

=cut

=abstract

Buildable Role for Perl 5

=cut

=synopsis

  package Vehicle;

  use Moo;

  with 'Data::Object::Role::Buildable';

  has name => (
    is => 'rw'
  );

  1;

=cut

=description

This package provides methods for hooking into object construction of the
consuming class, e.g. handling single-arg object construction.

=cut

=scenario buildarg

This package supports handling a C<build_arg> method, as a hook into object
construction, which is called and passed a single argument if a single argument
is passed to the constructor.

=example buildarg

  package Car;

  use Moo;

  extends 'Vehicle';

  sub build_arg {
    my ($class, $name) = @_;

    # do something with $name or $class ...

    return { name => $name };
  }

  package main;

  my $car = Car->new('tesla');

=scenario buildargs

This package supports handling a C<build_args> method, as a hook into object
construction, which is called and passed a C<hashref> during object
construction.

=example buildargs

  package Sedan;

  use Moo;

  extends 'Car';

  sub build_args {
    my ($class, $args) = @_;

    # do something with $args or $class ...

    $args->{name} = ucfirst $args->{name};

    return $args;
  }

  package main;

  my $sedan = Sedan->new('tesla');

=scenario buildself

This package supports handling a C<build_self> method, as a hook into object
construction, which is called and passed a C<hashref> during object
construction. Note: Manipulating the arguments doesn't effect object's
construction or properties.

=example buildself

  package Taxicab;

  use Moo;

  extends 'Sedan';

  sub build_self {
    my ($self, $args) = @_;

    # do something with $self or $args ...

    $args->{name} = 'Toyota';

    return;
  }

  package main;

  my $taxicab = Taxicab->new('tesla');

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->scenario('buildarg', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  ok $result->isa('Car');
  is $result->name, 'tesla';

  $result;
});

$subtests->scenario('buildargs', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  ok $result->isa('Sedan');
  ok $result->isa('Car');
  is $result->name, 'Tesla';

  $result;
});

$subtests->scenario('buildself', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  ok $result->isa('Taxicab');
  ok $result->isa('Sedan');
  ok $result->isa('Car');
  is $result->name, 'Tesla';

  $result;
});

ok 1 and done_testing;
