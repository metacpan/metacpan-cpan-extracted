use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;

=name

Data::Object::Role::Formulatable

=cut

=tagline

Objectify Class Attributes

=cut

=abstract

Formulatable Role for Perl 5

=cut

=synopsis

  package Test::Student;

  use registry;
  use routines;

  use Data::Object::Class;
  use Data::Object::ClassHas;

  with 'Data::Object::Role::Formulatable';

  has 'name';
  has 'dates';

  sub formulate {
    {
      name => 'test/data/str',
      dates => 'test/data/str'
    }
  }

  package main;

  my $student = Test::Student->new({
    name => 'levi nolan',
    dates => ['1587717124', '1587717169']
  });

  # $student->name;
  # <Test::Data::Str>

  # $student->dates;
  # [<Test::Data::Str>]

=cut

=libraries

Types::Standard

=cut

=integrates

Data::Object::Role::Buildable

=cut

=description

This package provides a mechanism for automatically inflating objects from
constructor arguments.

=cut

=scenario automation

This package supports automatically calling I<"before"> and I<"after"> routines
specific to each piece of data provided. This is automatically enabled if the
presence of a C<before_formulate> and/or C<after_formulate> routine is
detected. If so, these routines should return a hashref keyed off the class
attributes where the values are either C<1> (denoting that the hook name should
be generated) or some other routine name.

=example automation

  package Test::Teacher;

  use registry;
  use routines;

  use Data::Object::Class;
  use Data::Object::ClassHas;

  with 'Data::Object::Role::Formulatable';

  has 'name';
  has 'dates';

  sub formulate {
    {
      name => 'test/data/str',
      dates => 'test/data/str'
    }
  }

  sub after_formulate {
    {
      name => 1
    }
  }

  sub after_formulate_name {
    my ($self, $value) = @_;

    $value
  }

  sub before_formulate {
    {
      name => 1
    }
  }

  sub before_formulate_name {
    my ($self, $value) = @_;

    $value
  }

  package main;

  my $teacher = Test::Teacher->new({
    name => 'levi nolan',
    dates => ['1587717124', '1587717169']
  });

  # $teacher->name;
  # <Test::Data::Str>

  # $teacher->dates;
  # [<Test::Data::Str>]

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Student');
  ok $result->does('Data::Object::Role::Formulatable');
  ok $result->can('formulate');
  ok $result->can('formulate_object');
  ok $result->can('formulation');

  is ref $result->dates, 'ARRAY';

  ok $result->name;
  ok $result->name->isa('Test::Data::Str');
  ok $result->dates->[0]->isa('Test::Data::Str');
  ok $result->dates->[1]->isa('Test::Data::Str');

  $result
});

$subs->scenario('automation', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Test::Teacher');
  ok $result->does('Data::Object::Role::Formulatable');
  ok $result->can('formulate');
  ok $result->can('formulate_object');
  ok $result->can('formulation');

  is ref $result->dates, 'ARRAY';

  ok $result->name;
  ok $result->name->isa('Test::Data::Str');
  ok $result->dates->[0]->isa('Test::Data::Str');
  ok $result->dates->[1]->isa('Test::Data::Str');

  $result
});

ok 1 and done_testing;
