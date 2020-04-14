use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Types::Keywords

=cut

=abstract

Data-Object Type Library Keywords

=cut

=includes

function: is_any_of
function: is_all_of
function: is_one_of
function: is_instance_of
function: is_capable_of
function: is_comprised_of
function: is_consumer_of
function: register

=cut

=synopsis

  package Test::Library;

  use Data::Object::Types::Keywords;

  use base 'Data::Object::Types::Library';

  extends 'Types::Standard';

  register
  {
    name => 'Person',
    aliases => ['Student', 'Teacher'],
    validation => is_instance_of('Test::Person'),
    parent => 'Object'
  },
  {
    name => 'Principal',
    validation => is_instance_of('Test::Person'),
    parent => 'Object'
  };

  # creates person, student, and teacher constraints

  package main;

  my $library = Test::Library->meta;

=cut

=libraries

Types::Standard

=cut

=description

This package provides type library keyword functions for
L<Data::Object::Types::Library> and L<Type::Library> libraries.

=cut

=scenario exports

This package supports exporting functions which help configure L<Type::Library>
derived libraries.

=example exports

  package Test::Library::Exports;

  use base 'Data::Object::Types::Library';

  use Data::Object::Types::Keywords;

  # The following is a snapshot of the exported keyword functions:

  # as
  # class_type
  # classifier
  # coerce
  # compile_match_on_type
  # declare
  # declare_coercion
  # duck_type
  # dwim_type
  # english_list
  # enum
  # extends
  # from
  # is_all_of
  # is_any_of
  # is_one_of
  # inline_as
  # intersection
  # is_capable_of
  # is_consumer_of
  # is_instance_of
  # match_on_type
  # message
  # register
  # role_type
  # subtype
  # to_type
  # type
  # union
  # via
  # where

  "Test::Library::Exports"

=cut

=function is_any_of

The is_any_of function accepts one or more callbacks and returns truthy if any
of the callbacks return truthy.

=signature is_any_of

is_any_of(CodeRef @checks) : CodeRef

=example-1 is_any_of

  package Test::Library::HasAnyOf;

  use Data::Object::Types::Keywords;

  use base 'Data::Object::Types::Library';

  extends 'Types::Standard';

  my $validation = is_any_of(
    sub {
      my ($value) = @_;

      return 0 if !$value->isa('App::Person');
      return 1;
    },
    sub {
      my ($value) = @_;

      return 0 if !$value->isa('Test::Person');
      return 1;
    },
  );

  register {
    name => 'Person',
    validation => $validation,
    parent => 'Object'
  };

  $validation

=cut

=function is_all_of

The is_all_of function accepts one or more callbacks and returns truthy if all
of the callbacks return truthy.

=signature is_all_of

is_all_of(CodeRef @checks) : CodeRef

=example-1 is_all_of

  package Test::Library::HasAllOf;

  use Data::Object::Types::Keywords;

  use base 'Data::Object::Types::Library';

  extends 'Types::Standard';

  my $validation = is_all_of(
    sub {
      my ($value) = @_;

      return 0 if !$value->isa('Test::Entity');
      return 1;
    },
    sub {
      my ($value) = @_;

      return 0 if !$value->isa('Test::Person');
      return 1;
    },
  );

  register {
    name => 'Person',
    validation => $validation,
    parent => 'Object'
  };

  $validation

=cut

=function is_one_of

The is_one_of function accepts one or more callbacks and returns truthy if
only one of the callbacks return truthy.

=signature is_one_of

is_one_of(CodeRef @checks) : CodeRef

=example-1 is_one_of

  package Test::Library::HasOneOf;

  use Data::Object::Types::Keywords;

  use base 'Data::Object::Types::Library';

  extends 'Types::Standard';

  my $validation = is_one_of(
    sub {
      my ($value) = @_;

      return 0 if !$value->isa('Test::Student');
      return 1;
    },
    sub {
      my ($value) = @_;

      return 0 if !$value->isa('Test::Teacher');
      return 1;
    },
  );

  register {
    name => 'Person',
    validation => $validation,
    parent => 'Object'
  };

  $validation

=cut

=function is_instance_of

The is_instance_of function accepts a class or package name and returns a
callback which returns truthy if the value passed to the callback inherits from
the class or package specified.

=signature is_instance_of

is_instance_of(Str $name) : CodeRef

=example-1 is_instance_of

  package Test::Library::IsInstanceOf;

  use Data::Object::Types::Keywords;

  use base 'Data::Object::Types::Library';

  extends 'Types::Standard';

  my $validation = is_instance_of('Test::Person');

  register {
    name => 'Person',
    validation => $validation,
    parent => 'Object'
  };

  $validation

=cut

=function is_comprised_of

The is_comprised_of function accepts one or more names and returns a callback
which returns truthy if the value passed to the callback is a hashref or
hashref based object which has keys that correspond to the names provided.

=signature is_comprised_of

is_comprised_of(Str @names) : CodeRef

=example-1 is_comprised_of

  package Test::Library::IsComprisedOf;

  use Data::Object::Types::Keywords;

  use base 'Data::Object::Types::Library';

  extends 'Types::Standard';

  my $validation = is_comprised_of(qw(mon tues wed thurs fri sat sun));

  register {
    name => 'WorkHours',
    validation => $validation,
    parent => 'HashRef'
  };

  $validation

=cut

=function is_consumer_of

The is_consumer_of function accepts a role name and returns a callback which
returns truthy if the value passed to the callback consumes the role specified.

=signature is_consumer_of

is_consumer_of(Str $name) : CodeRef

=example-1 is_consumer_of

  package Test::Library::IsConsumerOf;

  use Data::Object::Types::Keywords;

  use base 'Data::Object::Types::Library';

  extends 'Types::Standard';

  my $validation = is_consumer_of('Test::Role::Identifiable');

  register {
    name => 'Person',
    validation => $validation,
    parent => 'Object'
  };

  $validation

=cut

=function is_capable_of

The is_capable_of function accepts one or more subroutine names and returns a
callback which returns truthy if the value passed to the callback has
implemented all of the routines specified.

=signature is_capable_of

is_capable_of(Str @routines) : CodeRef

=example-1 is_capable_of

  package Test::Library::IsCapableOf;

  use Data::Object::Types::Keywords;

  use base 'Data::Object::Types::Library';

  extends 'Types::Standard';

  my $validation = is_capable_of(qw(create update delete));

  register {
    name => 'Person',
    validation => $validation,
    parent => 'Object'
  };

  $validation

=cut

=function register

The register function takes a simple hashref and creates and registers a
L<Type::Tiny> type object.

=signature register

register(HashRef $type) : InstanceOf["Type::Tiny"]

=example-1 register

  package Test::Library::Standard;

  use Data::Object::Types::Keywords;

  use base 'Data::Object::Types::Library';

  extends 'Types::Standard';

  register {
    name => 'Message',
    coercions => [
      'Str', sub {
        my ($value) = @_;

        {
          type => 'simple',
          payload => $value
        }
      }
    ],
    validation => sub {
      my ($value) = @_;

      return 0 if !$value->{type};
      return 0 if !$value->{payload};
      return 1;
    },
    parent => 'HashRef'
  };

=example-2 register

  package Test::Library::Parameterized;

  use Data::Object::Types::Keywords;

  use base 'Data::Object::Types::Library';

  extends 'Types::Standard';

  register {
    name => 'People',
    coercions => [
      'ArrayRef', sub {
        my ($value) = @_;

        Test::People->new($value)
      }
    ],
    validation => sub {
      my ($value) = @_;

      return 0 if !$value->isa('Test::People');
      return 1;
    },
    explaination => sub {
      my ($value, $type, $name) = @_;

      my $param = $type->parameters->[0];

      for my $i (0 .. $#$value) {
        next if $param->check($value->[$i]);

        my $indx = sprintf('%s->[%d]', $name, $i);
        my $desc = $param->validate_explain($value->[$i], $indx);
        my $text = '"%s" constrains each value in the array object with "%s"';

        return [sprintf($text, $type, $param), @{$desc}];
      }

      return;
    },
    parameterize_constraint => sub {
      my ($value, $type) = @_;

      $type->check($_) || return for @$value;

      return !!1;
    },
    parameterize_coercions => sub {
      my ($data, $type, $anon) = @_;

      my $coercions = [];

      push @$coercions, 'ArrayRef', sub {
        my $value = @_ ? $_[0] : $_;
        my $items = [];

        for (my $i = 0; $i < @$value; $i++) {
          return $value unless $anon->check($value->[$i]);
          $items->[$i] = $data->coerce($value->[$i]);
        }

        return $type->coerce($items);
      };

      return $coercions;
    },
    parent => 'Object'
  };

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Types::Library');
  ok $result->isa('Type::Library');
  ok $result->get_type('Person');
  ok $result->get_type('Student');
  ok $result->get_type('Teacher');
  ok $result->get_type('Principal');

  $result
});

$subs->scenario('exports', fun($tryable) {
  my $result = $tryable->result;

  can_ok $result, (
    'as',
    'class_type',
    'classifier',
    'coerce',
    'compile_match_on_type',
    'declare',
    'declare_coercion',
    'duck_type',
    'dwim_type',
    'english_list',
    'enum',
    'extends',
    'from',
    'inline_as',
    'intersection',
    'match_on_type',
    'message',
    'role_type',
    'subtype',
    'to_type',
    'type',
    'union',
    'via',
    'where',
  );

  $result
});

{
  package Test::Entity;

  sub new {
    bless {}, shift;
  }

  sub id;

  package Test::Person;

  use base 'Test::Entity';

  sub new {
    bless {}, shift;
  }

  sub does {
    undef
  }

  sub create;
  sub update;
  sub delete;

  package Test::Student;

  use base 'Test::Person';

  sub does {
    'Test::Student'
  }

  package Test::Teacher;

  use base 'Test::Person';

  sub does {
    'Test::Student'
  }
}

$subs->example(-1, 'is_any_of', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->(Test::Person->new);
  ok !$result->(Test::Entity->new);

  $result
});

$subs->example(-1, 'is_all_of', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->(Test::Person->new);

  $result
});

$subs->example(-1, 'is_one_of', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->(Test::Student->new);
  ok $result->(Test::Teacher->new);

  $result
});

$subs->example(-1, 'is_instance_of', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->(Test::Person->new);
  ok $result->(Test::Teacher->new);
  ok !$result->(Test::Entity->new);

  $result
});

$subs->example(-1, 'is_comprised_of', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->({});
  ok !$result->({map +($_, 1), qw(mon wed fri)});
  ok !$result->({map +($_, 1), qw(mon tues wed thurs fri)});
  ok $result->({map +($_, 1), qw(mon tues wed thurs fri sat sun)});

  $result
});

$subs->example(-1, 'is_consumer_of', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->(Test::Person->new);
  ok $result->(Test::Student->new);
  ok $result->(Test::Teacher->new);

  $result
});

$subs->example(-1, 'is_capable_of', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->(Test::Entity->new);
  ok $result->(Test::Person->new);
  ok $result->(Test::Student->new);
  ok $result->(Test::Teacher->new);

  $result
});

$subs->example(-1, 'register', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Type::Tiny');
  is $result->name, 'Message';
  ok $result->check({
    type => 'simple',
    payload => 'converted to message'
  });

  $result
});

$subs->example(-2, 'register', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Type::Tiny');
  is $result->name, 'People';
  my $str = "Test::Library::Parameterized"->meta->get_type('Str');
  ok $result->parameterize($str)->check(bless [
    'Fred',
    'Wilma'
  ], 'Test::People');

  $result
});

ok 1 and done_testing;
