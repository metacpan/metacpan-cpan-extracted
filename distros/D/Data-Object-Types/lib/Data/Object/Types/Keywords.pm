package Data::Object::Types::Keywords;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use base 'Exporter';

use Type::Coercion ();
use Type::Tiny ();
use Types::TypeTiny ();

BEGIN {
  require Type::Utils;
}

use Type::Utils (@Type::Utils::EXPORT_OK);

our @EXPORT = (
  'is_any_of',
  'is_all_of',
  'is_one_of',
  'is_instance_of',
  'is_capable_of',
  'is_comprised_of',
  'is_consumer_of',
  'register',
  @Type::Utils::EXPORT_OK
);

our $VERSION = '0.04'; # VERSION

# FUNCTIONS

fun is_any_of(CodeRef @checks) {
  fun($value) {
    for my $check (@checks) {
      return 1 if $check->($value);
    }
    return 0;
  }
}

fun is_all_of(CodeRef @checks) {
  fun($value) {
    for my $check (@checks) {
      return 0 if !$check->($value);
    }
    return 1;
  }
}

fun is_one_of(CodeRef @checks) {
  fun($value) {
    return (grep {$_->($value)} @checks) > 1 ? 0 : 1;
  }
}

fun is_instance_of(Str $name) {
  fun($value) {
    return 1 if $value->isa($name);
    return 0;
  }
}

fun is_consumer_of(Str $name) {
  fun($value) {
    return 1 if $value->does($name);
    return 0;
  }
}

fun is_capable_of(Str @routines) {
  fun($value) {
    return 0 if grep {!$value->can($_)} @routines;
    return 1;
  }
}

fun is_comprised_of(Str @names) {
  fun($value) {
    return 0 if !UNIVERSAL::isa($value, 'HASH');
    return 0 if grep {!exists $value->{$_}} @names;
    return 1;
  }
}

fun register(HashRef @types) {
  my $caller = caller;
  my @created = map _register_all($caller->meta, $_), @types;

  return wantarray ? (@created) : $created[0];
}

sub _options {
  my ($library, $type) = @_;

  my %options;

  $options{name} = $type->{name};
  $options{parent} = $type->{parent};
  $options{constraint} = sub { goto $type->{validation} };

  if ($type->{explaination}) {
    $options{deep_explanation} = sub {
      _generate_explanation($library, $type, @_)
    };
  }

  if ($type->{parameterize_coercions}) {
    $options{coercion_generator} = sub {
      _generate_coercion($library, $type, @_)
    };
  }

  if ($type->{parameterize_constraint}) {
    $options{constraint_generator} = sub {
      _generate_constraint($library, $type, @_)
    };
  }

  if (!ref($options{parent})) {
    $options{parent} = $library->get_type($options{parent});
  }

  return %options;
}

sub _register {
  my ($library, $type) = @_;

  my $name = $type->{name};
  my $aliases = $type->{aliases};
  my $parent = $type->{parent};
  my $coercions = $type->{coercions};
  my $validation = $type->{validation};

  return if $library->get_type($name);

  my $tinytype = Type::Tiny->new(_options($library, $type));

  if ($type->{coercions}) {
    my $coercions = $type->{coercions};

    for (my $i = 0; $i < @$coercions; $i+=2) {
      if (!ref($coercions->[$i])) {
        $coercions->[$i] = $library->get_type($coercions->[$i]);
      }
    }

    $tinytype->coercion->add_type_coercions(@$coercions);
  }

  $library->add_type($tinytype);

  return $tinytype;
}

sub _register_all {
  my ($library, $type) = @_;

  my $registered = _register($library, $type);

  for my $alias (@{$type->{aliases}}) {
    _register($library, {%{$type}, name => $alias, aliases => []});
  }

  return $registered;
}

sub _generate_coercion {
  my ($library, $type, @args) = @_;

  my ($type1, $xtype, $type2) = @args;

  if (!$type2->has_coercion) {
    return $type1->coercion;
  }

  my $anon = $type2->coercion->_source_type_union;
  my $coercion = Type::Coercion->new(type_constraint => $xtype);
  my $generated = $type->{parameterize_coercions}->($type2, $type1, $anon);

  for (my $i = 0; $i < @$generated; $i+=2) {
    my $item = $generated->[$i];

    $generated->[$i] = $library->get_type($item) if !ref($item);
  }

  $coercion->add_type_coercions(@$generated);

  return $coercion;
}

sub _generate_constraint {
  my ($library, $type, @args) = @_;

  return $type->{validator} if !@args;

  my $sign = "@{[$type->{name}]}\[`a\]";
  my $text = "Parameter to $sign expected to be a type constraint";
  my @list = map Types::TypeTiny::to_TypeTiny($_), @args;

  for my $item (@list) {
    if ($item->isa('Type::Tiny')) {
      next;
    }
    if (!Types::TypeTiny::TypeTiny->check($item)) {
      Types::Standard::_croak("$text; got $item");
    }
  }

  return sub { my ($data) = @_; $type->{parameterize_constraint}->($data, @list) };
}

sub _generate_explanation {
  my ($library, $type, @args) = @_;

  return $type->{explaination}->($_[2], $_[1], $_[3]);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Types::Keywords

=cut

=head1 ABSTRACT

Data-Object Type Library Keywords

=cut

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This package provides type library keyword functions for
L<Data::Object::Types::Library> and L<Type::Library> libraries.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 exports

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

This package supports exporting functions which help configure L<Type::Library>
derived libraries.

=cut

=head1 FUNCTIONS

This package implements the following functions:

=cut

=head2 is_all_of

  is_all_of(CodeRef @checks) : CodeRef

The is_all_of function accepts one or more callbacks and returns truthy if all
of the callbacks return truthy.

=over 4

=item is_all_of example #1

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

=back

=cut

=head2 is_any_of

  is_any_of(CodeRef @checks) : CodeRef

The is_any_of function accepts one or more callbacks and returns truthy if any
of the callbacks return truthy.

=over 4

=item is_any_of example #1

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

=back

=cut

=head2 is_capable_of

  is_capable_of(Str @routines) : CodeRef

The is_capable_of function accepts one or more subroutine names and returns a
callback which returns truthy if the value passed to the callback has
implemented all of the routines specified.

=over 4

=item is_capable_of example #1

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

=back

=cut

=head2 is_comprised_of

  is_comprised_of(Str @names) : CodeRef

The is_comprised_of function accepts one or more names and returns a callback
which returns truthy if the value passed to the callback is a hashref or
hashref based object which has keys that correspond to the names provided.

=over 4

=item is_comprised_of example #1

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

=back

=cut

=head2 is_consumer_of

  is_consumer_of(Str $name) : CodeRef

The is_consumer_of function accepts a role name and returns a callback which
returns truthy if the value passed to the callback consumes the role specified.

=over 4

=item is_consumer_of example #1

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

=back

=cut

=head2 is_instance_of

  is_instance_of(Str $name) : CodeRef

The is_instance_of function accepts a class or package name and returns a
callback which returns truthy if the value passed to the callback inherits from
the class or package specified.

=over 4

=item is_instance_of example #1

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

=back

=cut

=head2 is_one_of

  is_one_of(CodeRef @checks) : CodeRef

The is_one_of function accepts one or more callbacks and returns truthy if
only one of the callbacks return truthy.

=over 4

=item is_one_of example #1

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

=back

=cut

=head2 register

  register(HashRef $type) : InstanceOf["Type::Tiny"]

The register function takes a simple hashref and creates and registers a
L<Type::Tiny> type object.

=over 4

=item register example #1

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

=back

=over 4

=item register example #2

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

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-types/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-types/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-types>

L<Initiatives|https://github.com/iamalnewkirk/data-object-types/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-types/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-types/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-types/issues>

=cut
