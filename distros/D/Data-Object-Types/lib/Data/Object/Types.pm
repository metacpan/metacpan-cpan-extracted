package Data::Object::Types;

use 5.014;

use strict;
use warnings;

use Scalar::Util ();
use Type::Utils ();

use Data::Object::Types::Keywords;

use base 'Data::Object::Types::Library';

our $VERSION = '0.04'; # VERSION

extends 'Types::Standard';
extends 'Types::TypeTiny';
extends 'Types::Common::Numeric';
extends 'Types::Common::String';

# TYPES

register(DoArgsConfig());
register(DoDataConfig());
register(DoDumpableConfig());
register(DoArrayConfig());
register(DoBooleanConfig());
register(DoCliConfig());
register(DoCodeConfig());
register(DoExceptionConfig());
register(DoFloatConfig());
register(DoFuncConfig());
register(DoHashConfig());
register(DoImmutableConfig());
register(DoNumberConfig());
register(DoOptsConfig());
register(DoRegexpConfig());
register(DoReplaceConfig());
register(DoScalarConfig());
register(DoSearchConfig());
register(DoSpaceConfig());
register(DoStashableConfig());
register(DoStateConfig());
register(DoStringConfig());
register(DoStructConfig());
register(DoThrowableConfig());
register(DoUndefConfig());
register(DoVarsConfig());

# FUNCTIONS

sub DoArgsConfig {
  {
    name => 'DoArgs',
    aliases => [
      'ArgsObj',
      'ArgsObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Args');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoArrayConfig {
  {
    name => 'DoArray',
    aliases => [
      'ArrayObj',
      'ArrayObject'
    ],
    coercions => [
      'ArrayRef', sub {
        eval { require Data::Object::Array };

        Data::Object::Array->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Array');
      return 1;
    },
    explaination => sub {
      my ($data, $type, $name) = @_;

      my $param = $type->parameters->[0];

      for my $i (0 .. $#$data) {
        next if $param->check($data->[$i]);

        my $indx = sprintf('%s->[%d]', $name, $i);
        my $desc = $param->validate_explain($data->[$i], $indx);
        my $text = '"%s" constrains each value in the array object with "%s"';

        return [sprintf($text, $type, $param), @{$desc}];
      }

      return;
    },
    parameterize_constraint => sub {
      my ($data, $type) = @_;

      $type->check($_) || return for @$data;

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
  }
}

sub DoBooleanConfig {
  {
    name => 'DoBoolean',
    aliases => [
      'BoolObj',
      'BoolObject',
      'BooleanObj',
      'BooleanObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Boolean');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoCliConfig {
  {
    name => 'DoCli',
    aliases => [
      'CliObj',
      'CliObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Cli');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoCodeConfig {
  {
    name => 'DoCode',
    aliases => [
      'CodeObj',
      'CodeObject'
    ],
    coercions => [
      'CodeRef', sub {
        eval { require Data::Object::Code };

        Data::Object::Code->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Code');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoDataConfig {
  {
    name => 'DoData',
    aliases => [
      'DataObj',
      'DataObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Data');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoDumpableConfig {
  {
    name => 'DoDumpable',
    aliases => [
      'Dumpable'
    ],
    validation => sub {
      return 0 if !$_[0]->does('Data::Object::Role::Dumpable');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoExceptionConfig {
  {
    name => 'DoException',
    aliases => [
      'ExceptionObj',
      'ExceptionObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Exception');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoFloatConfig {
  {
    name => 'DoFloat',
    aliases => [
      'FloatObj',
      'FloatObject'
    ],
    coercions => [
      'Str', sub {
        eval { require Data::Object::Float };

        Data::Object::Float->new($_[0]);
      },
      'Num', sub {
        eval { require Data::Object::Float };

        Data::Object::Float->new($_[0]);
      },
      'LaxNum', sub {
        eval { require Data::Object::Float };

        Data::Object::Float->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Float');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoFuncConfig {
  {
    name => 'DoFunc',
    aliases => [
      'FuncObj',
      'FuncObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Func');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoHashConfig {
  {
    name => 'DoHash',
    aliases => [
      'HashObj',
      'HashObject'
    ],
    coercions => [
      'HashRef', sub {
        eval { require Data::Object::Hash };

        Data::Object::Hash->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Hash');
      return 1;
    },
    explaination => sub {
      my ($data, $type, $name) = @_;

      my $param = $type->parameters->[0];

      for my $k (sort keys %$data) {
        next if $param->check($data->{$k});

        my $indx = sprintf('%s->{%s}', $name, B::perlstring($k));
        my $desc = $param->validate_explain($data->{$k}, $indx);
        my $text = '"%s" constrains each value in the hash object with "%s"';

        return [sprintf($text, $type, $param), @{$desc}];
      }

      return;
    },
    parameterize_constraint => sub {
      my ($data, $type) = @_;

      $type->check($_) || return for values %$data;

      return !!1;
    },
    parameterize_coercions => sub {
      my ($data, $type, $anon) = @_;

      my $coercions = [];

      push @$coercions, 'HashRef', sub {
        my $value = @_ ? $_[0] : $_;
        my $items = {};

        for my $k (sort keys %$value) {
          return $value unless $anon->check($value->{$k});
          $items->{$k} = $data->coerce($value->{$k});
        }

        return $type->coerce($items);
      };

      return $coercions;
    },
    parent => 'Object'
  }
}

sub DoImmutableConfig {
  {
    name => 'DoImmutable',
    aliases => [
      'Immutable'
    ],
    validation => sub {
      return 0 if !$_[0]->does('Data::Object::Role::Immutable');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoNumberConfig {
  {
    name => 'DoNum',
    aliases => [
      'NumObj',
      'NumObject',
      'NumberObj',
      'NumberObject'
    ],
    coercions => [
      'Int', sub {
        eval { require Data::Object::Number };

        Data::Object::Number->new($_[0]);
      },
      'Num', sub {
        eval { require Data::Object::Number };

        Data::Object::Number->new($_[0]);
      },
      'LaxNum', sub {
        eval { require Data::Object::Number };

        Data::Object::Number->new($_[0]);
      },
      'StrictNum', sub {
        eval { require Data::Object::Number };

        Data::Object::Number->new($_[0]);
      },
      'Str', sub {
        eval { require Data::Object::Number };

        Data::Object::Number->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Number');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoOptsConfig {
  {
    name => 'DoOpts',
    aliases => [
      'OptsObj',
      'OptsObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Opts');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoRegexpConfig {
  {
    name => 'DoRegexp',
    aliases => [
      'RegexpObj',
      'RegexpObject'
    ],
    coercions => [
      'RegexpRef', sub {
        eval { require Data::Object::Regexp };

        Data::Object::Regexp->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Regexp');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoReplaceConfig {
  {
    name => 'DoReplace',
    aliases => [
      'ReplaceObj',
      'ReplaceObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Replace');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoScalarConfig {
  {
    name => 'DoScalar',
    aliases => [
      'ScalarObj',
      'ScalarObject'
    ],
    coercions => [
      'ScalarRef', sub {
        eval { require Data::Object::Scalar };

        Data::Object::Scalar->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Scalar');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoSearchConfig {
  {
    name => 'DoSearch',
    aliases => [
      'SearchObj',
      'SearchObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Search');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoSpaceConfig {
  {
    name => 'DoSpace',
    aliases => [
      'SpaceObj',
      'SpaceObject'
    ],
    coercions => [
      'Str', sub {
        eval { require Data::Object::Space };

        Data::Object::Space->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Space');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoStashableConfig {
  {
    name => 'DoStashable',
    aliases => [
      'Stashable'
    ],
    validation => sub {
      return 0 if !$_[0]->does('Data::Object::Role::Stashable');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoStateConfig {
  {
    name => 'DoState',
    aliases => [
      'StateObj',
      'StateObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::State');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoStringConfig {
  {
    name => 'DoStr',
    aliases => [
      'StrObj',
      'StrObject',
      'StringObj',
      'StringObject'
    ],
    coercions => [
      'Str', sub {
        eval { require Data::Object::String };

        Data::Object::String->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::String');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoStructConfig {
  {
    name => 'DoStruct',
    aliases => [
      'StructObj',
      'StructObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Struct');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoThrowableConfig {
  {
    name => 'DoThrowable',
    aliases => [
      'Throwable'
    ],
    validation => sub {
      return 0 if !$_[0]->does('Data::Object::Role::Throwable');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoUndefConfig {
  {
    name => 'DoUndef',
    aliases => [
      'UndefObj',
      'UndefObject'
    ],
    coercions => [
      'Undef', sub {
        eval { require Data::Object::Undef };

        Data::Object::Undef->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Undef');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoVarsConfig {
  {
    name => 'DoVars',
    aliases => [
      'VarsObj',
      'VarsObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Vars');
      return 1;
    },
    parent => 'Object'
  }
}

# ONE-OFFS

Type::Utils::declare('RegexpLike', Type::Utils::as(Object(), Type::Utils::where(sub {
  return !!re::is_regexp($_[0]) || (Scalar::Util::blessed($_[0]) &&
    ($_[0]->isa('Regexp') || $_[0]->isa('Data::Object::Regexp')));
})));

Type::Utils::declare('NumberLike', Type::Utils::as(StringLike(), Type::Utils::where(sub {
  return Scalar::Util::looks_like_number("$_[0]");
})));

1;

=encoding utf8

=head1 NAME

Data::Object::Types

=cut

=head1 ABSTRACT

Data-Object Type Constraints

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Types;

  1;

=cut

=head1 DESCRIPTION

This package provides type constraints for L<Data::Object>.

=cut

=head1 CONSTRAINTS

This package declares the following type constraints:

=cut

=head2 argsobj

  ArgsObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item argsobj parent

  Object

=back

=over 4

=item argsobj composition

  InstanceOf["Data::Object::Args"]

=back

=over 4

=item argsobj example #1

  # package ArgsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Args';

  package main;

  bless {}, 'ArgsExample';

=back

=cut

=head2 argsobject

  ArgsObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item argsobject parent

  Object

=back

=over 4

=item argsobject composition

  InstanceOf["Data::Object::Args"]

=back

=over 4

=item argsobject example #1

  # package ArgsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Args';

  package main;

  bless {}, 'ArgsExample';

=back

=cut

=head2 arrayobj

  ArrayObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item arrayobj parent

  Object

=back

=over 4

=item arrayobj composition

  InstanceOf["Data::Object::Array"]

=back

=over 4

=item arrayobj coercion #1

  # coerce from ArrayRef

  []

=back

=over 4

=item arrayobj example #1

  # package ArrayExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Array';

  package main;

  bless [], 'ArrayExample';

=back

=cut

=head2 arrayobject

  ArrayObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item arrayobject parent

  Object

=back

=over 4

=item arrayobject composition

  InstanceOf["Data::Object::Array"]

=back

=over 4

=item arrayobject coercion #1

  # coerce from ArrayRef

  []

=back

=over 4

=item arrayobject example #1

  # package ArrayExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Array';

  package main;

  bless [], 'ArrayExample';

=back

=cut

=head2 boolobj

  BoolObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item boolobj parent

  Object

=back

=over 4

=item boolobj composition

  InstanceOf["Data::Object::Boolean"]

=back

=over 4

=item boolobj example #1

  # package BooleanExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Boolean';

  package main;

  my $bool = 1;

  bless \$bool, 'BooleanExample';

=back

=cut

=head2 boolobject

  BoolObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item boolobject parent

  Object

=back

=over 4

=item boolobject composition

  InstanceOf["Data::Object::Boolean"]

=back

=over 4

=item boolobject example #1

  # package BooleanExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Boolean';

  package main;

  my $bool = 1;

  bless \$bool, 'BooleanExample';

=back

=cut

=head2 booleanobj

  BooleanObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item booleanobj parent

  Object

=back

=over 4

=item booleanobj composition

  InstanceOf["Data::Object::Boolean"]

=back

=over 4

=item booleanobj example #1

  # package BooleanExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Boolean';

  package main;

  my $bool = 1;

  bless \$bool, 'BooleanExample';

=back

=cut

=head2 booleanobject

  BooleanObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item booleanobject parent

  Object

=back

=over 4

=item booleanobject composition

  InstanceOf["Data::Object::Boolean"]

=back

=over 4

=item booleanobject example #1

  # package BooleanExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Boolean';

  package main;

  my $bool = 1;

  bless \$bool, 'BooleanExample';

=back

=cut

=head2 cliobj

  CliObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item cliobj parent

  Object

=back

=over 4

=item cliobj composition

  InstanceOf["Data::Object::Cli"]

=back

=over 4

=item cliobj example #1

  # package CliExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Cli';

  package main;

  bless {}, 'CliExample';

=back

=cut

=head2 cliobject

  CliObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item cliobject parent

  Object

=back

=over 4

=item cliobject composition

  InstanceOf["Data::Object::Cli"]

=back

=over 4

=item cliobject example #1

  # package CliExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Cli';

  package main;

  bless {}, 'CliExample';

=back

=cut

=head2 codeobj

  CodeObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item codeobj parent

  Object

=back

=over 4

=item codeobj composition

  InstanceOf["Data::Object::Code"]

=back

=over 4

=item codeobj coercion #1

  # coerce from CodeRef

  sub{}

=back

=over 4

=item codeobj example #1

  # package CodeExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Code';

  package main;

  bless sub{}, 'CodeExample';

=back

=cut

=head2 codeobject

  CodeObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item codeobject parent

  Object

=back

=over 4

=item codeobject composition

  InstanceOf["Data::Object::Code"]

=back

=over 4

=item codeobject coercion #1

  # coerce from CodeRef

  sub{}

=back

=over 4

=item codeobject example #1

  # package CodeExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Code';

  package main;

  bless sub{}, 'CodeExample';

=back

=cut

=head2 dataobj

  DataObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dataobj parent

  Object

=back

=over 4

=item dataobj composition

  InstanceOf["Data::Object::Data"]

=back

=over 4

=item dataobj example #1

  # package DataExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Data';

  package main;

  bless {}, 'DataExample';

=back

=cut

=head2 dataobject

  DataObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dataobject parent

  Object

=back

=over 4

=item dataobject composition

  InstanceOf["Data::Object::Data"]

=back

=over 4

=item dataobject example #1

  # package DataExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Data';

  package main;

  bless {}, 'DataExample';

=back

=cut

=head2 doargs

  DoArgs

This type is defined in the L<Data::Object::Types> library.

=over 4

=item doargs parent

  Object

=back

=over 4

=item doargs composition

  InstanceOf["Data::Object::Args"]

=back

=over 4

=item doargs example #1

  # package ArgsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Args';

  package main;

  bless {}, 'ArgsExample';

=back

=cut

=head2 doarray

  DoArray

This type is defined in the L<Data::Object::Types> library.

=over 4

=item doarray parent

  Object

=back

=over 4

=item doarray composition

  InstanceOf["Data::Object::Array"]

=back

=over 4

=item doarray coercion #1

  # coerce from ArrayRef

  []

=back

=over 4

=item doarray example #1

  # package ArrayExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Array';

  package main;

  bless [], 'ArrayExample';

=back

=cut

=head2 doboolean

  DoBoolean

This type is defined in the L<Data::Object::Types> library.

=over 4

=item doboolean parent

  Object

=back

=over 4

=item doboolean composition

  InstanceOf["Data::Object::Boolean"]

=back

=over 4

=item doboolean example #1

  # package BooleanExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Boolean';

  package main;

  my $bool = 1;

  bless \$bool, 'BooleanExample';

=back

=cut

=head2 docli

  DoCli

This type is defined in the L<Data::Object::Types> library.

=over 4

=item docli parent

  Object

=back

=over 4

=item docli composition

  InstanceOf["Data::Object::Cli"]

=back

=over 4

=item docli example #1

  # package CliExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Cli';

  package main;

  bless {}, 'CliExample';

=back

=cut

=head2 docode

  DoCode

This type is defined in the L<Data::Object::Types> library.

=over 4

=item docode parent

  Object

=back

=over 4

=item docode composition

  InstanceOf["Data::Object::Code"]

=back

=over 4

=item docode coercion #1

  # coerce from CodeRef

  sub{}

=back

=over 4

=item docode example #1

  # package CodeExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Code';

  package main;

  bless sub{}, 'CodeExample';

=back

=cut

=head2 dodata

  DoData

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dodata parent

  Object

=back

=over 4

=item dodata composition

  InstanceOf["Data::Object::Data"]

=back

=over 4

=item dodata example #1

  # package DataExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Data';

  package main;

  bless {}, 'DataExample';

=back

=cut

=head2 dodumpable

  DoDumpable

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dodumpable parent

  Object

=back

=over 4

=item dodumpable composition

  ConsumerOf["Data::Object::Role::Dumpable"]

=back

=over 4

=item dodumpable example #1

  # package DumpableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Dumpable';

  package main;

  bless {}, 'DumpableExample';

=back

=cut

=head2 doexception

  DoException

This type is defined in the L<Data::Object::Types> library.

=over 4

=item doexception parent

  Object

=back

=over 4

=item doexception composition

  InstanceOf["Data::Object::Exception"]

=back

=over 4

=item doexception example #1

  # package ExceptionExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Exception';

  package main;

  bless {}, 'ExceptionExample';

=back

=cut

=head2 dofloat

  DoFloat

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dofloat parent

  Object

=back

=over 4

=item dofloat composition

  InstanceOf["Data::Object::Float"]

=back

=over 4

=item dofloat coercion #1

  # coerce from LaxNum

  123

=back

=over 4

=item dofloat coercion #2

  # coerce from Str

  '123'

=back

=over 4

=item dofloat coercion #3

  # coerce from Num

  123

=back

=over 4

=item dofloat example #1

  # package FloatExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Float';

  package main;

  my $float = 1.23;

  bless \$float, 'FloatExample';

=back

=cut

=head2 dofunc

  DoFunc

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dofunc parent

  Object

=back

=over 4

=item dofunc composition

  InstanceOf["Data::Object::Func"]

=back

=over 4

=item dofunc example #1

  # package FuncExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Func';

  package main;

  bless {}, 'FuncExample';

=back

=cut

=head2 dohash

  DoHash

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dohash parent

  Object

=back

=over 4

=item dohash composition

  InstanceOf["Data::Object::Hash"]

=back

=over 4

=item dohash coercion #1

  # coerce from HashRef

  {}

=back

=over 4

=item dohash example #1

  # package HashExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Hash';

  package main;

  bless {}, 'HashExample';

=back

=cut

=head2 doimmutable

  DoImmutable

This type is defined in the L<Data::Object::Types> library.

=over 4

=item doimmutable parent

  Object

=back

=over 4

=item doimmutable composition

  ConsumerOf["Data::Object::Role::Immutable"]

=back

=over 4

=item doimmutable example #1

  # package ImmutableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Immutable';

  package main;

  bless {}, 'ImmutableExample';

=back

=cut

=head2 donum

  DoNum

This type is defined in the L<Data::Object::Types> library.

=over 4

=item donum parent

  Object

=back

=over 4

=item donum composition

  InstanceOf["Data::Object::Number"]

=back

=over 4

=item donum coercion #1

  # coerce from LaxNum

  123

=back

=over 4

=item donum coercion #2

  # coerce from Str

  '123'

=back

=over 4

=item donum coercion #3

  # coerce from Num

  123

=back

=over 4

=item donum coercion #4

  # coerce from StrictNum

  123

=back

=over 4

=item donum coercion #5

  # coerce from Int

  99999

=back

=over 4

=item donum example #1

  # package NumberExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Number';

  package main;

  my $num = 123;

  bless \$num, 'NumberExample';

=back

=cut

=head2 doopts

  DoOpts

This type is defined in the L<Data::Object::Types> library.

=over 4

=item doopts parent

  Object

=back

=over 4

=item doopts composition

  InstanceOf["Data::Object::Opts"]

=back

=over 4

=item doopts example #1

  # package OptsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Opts';

  package main;

  bless {}, 'OptsExample';

=back

=cut

=head2 doregexp

  DoRegexp

This type is defined in the L<Data::Object::Types> library.

=over 4

=item doregexp parent

  Object

=back

=over 4

=item doregexp composition

  InstanceOf["Data::Object::Regexp"]

=back

=over 4

=item doregexp coercion #1

  # coerce from RegexpRef

  qr//

=back

=over 4

=item doregexp example #1

  # package RegexpExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Regexp';

  package main;

  bless {}, 'RegexpExample';

=back

=cut

=head2 doreplace

  DoReplace

This type is defined in the L<Data::Object::Types> library.

=over 4

=item doreplace parent

  Object

=back

=over 4

=item doreplace composition

  InstanceOf["Data::Object::Replace"]

=back

=over 4

=item doreplace example #1

  # package ReplaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Replace';

  package main;

  bless {}, 'ReplaceExample';

=back

=cut

=head2 doscalar

  DoScalar

This type is defined in the L<Data::Object::Types> library.

=over 4

=item doscalar parent

  Object

=back

=over 4

=item doscalar composition

  InstanceOf["Data::Object::Scalar"]

=back

=over 4

=item doscalar coercion #1

  # coerce from ScalarRef

  do { my $i = 0; \$i }

=back

=over 4

=item doscalar example #1

  # package ScalarExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Scalar';

  package main;

  my $scalar = 'abc';

  bless \$scalar, 'ScalarExample';

=back

=cut

=head2 dosearch

  DoSearch

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dosearch parent

  Object

=back

=over 4

=item dosearch composition

  InstanceOf["Data::Object::Search"]

=back

=over 4

=item dosearch example #1

  # package SearchExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Search';

  package main;

  bless {}, 'SearchExample';

=back

=cut

=head2 dospace

  DoSpace

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dospace parent

  Object

=back

=over 4

=item dospace composition

  InstanceOf["Data::Object::Space"]

=back

=over 4

=item dospace coercion #1

  # coerce from Str

  'abc'

=back

=over 4

=item dospace example #1

  # package SpaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Space';

  package main;

  bless {}, 'SpaceExample';

=back

=cut

=head2 dostashable

  DoStashable

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dostashable parent

  Object

=back

=over 4

=item dostashable composition

  ConsumerOf["Data::Object::Role::Stashable"]

=back

=over 4

=item dostashable example #1

  # package StashableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Stashable';

  package main;

  bless {}, 'StashableExample';

=back

=cut

=head2 dostate

  DoState

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dostate parent

  Object

=back

=over 4

=item dostate composition

  InstanceOf["Data::Object::State"]

=back

=over 4

=item dostate example #1

  # package StateExample;

  # use Data::Object::Class;

  # extends 'Data::Object::State';

  package main;

  bless {}, 'StateExample';

=back

=cut

=head2 dostr

  DoStr

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dostr parent

  Object

=back

=over 4

=item dostr composition

  InstanceOf["Data::Object::String"]

=back

=over 4

=item dostr coercion #1

  # coerce from Str

  'abc'

=back

=over 4

=item dostr example #1

  # package StringExample;

  # use Data::Object::Class;

  # extends 'Data::Object::String';

  package main;

  my $string = 'abc';

  bless \$string, 'StringExample';

=back

=cut

=head2 dostruct

  DoStruct

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dostruct parent

  Object

=back

=over 4

=item dostruct composition

  InstanceOf["Data::Object::Struct"]

=back

=over 4

=item dostruct example #1

  # package StructExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Struct';

  package main;

  bless {}, 'StructExample';

=back

=cut

=head2 dothrowable

  DoThrowable

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dothrowable parent

  Object

=back

=over 4

=item dothrowable composition

  ConsumerOf["Data::Object::Role::Throwable"]

=back

=over 4

=item dothrowable example #1

  # package ThrowableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Throwable';

  package main;

  bless {}, 'ThrowableExample';

=back

=cut

=head2 doundef

  DoUndef

This type is defined in the L<Data::Object::Types> library.

=over 4

=item doundef parent

  Object

=back

=over 4

=item doundef composition

  InstanceOf["Data::Object::Undef"]

=back

=over 4

=item doundef coercion #1

  # coerce from Undef

  undef

=back

=over 4

=item doundef example #1

  # package UndefExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Undef';

  my $undef = undef;

  bless \$undef, 'UndefExample';

=back

=cut

=head2 dovars

  DoVars

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dovars parent

  Object

=back

=over 4

=item dovars composition

  InstanceOf["Data::Object::Vars"]

=back

=over 4

=item dovars example #1

  # package VarsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Vars';

  package main;

  bless {}, 'VarsExample';

=back

=cut

=head2 dumpable

  Dumpable

This type is defined in the L<Data::Object::Types> library.

=over 4

=item dumpable parent

  Object

=back

=over 4

=item dumpable composition

  ConsumerOf["Data::Object::Role::Dumpable"]

=back

=over 4

=item dumpable example #1

  # package DumpableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Dumpable';

  package main;

  bless {}, 'DumpableExample';

=back

=cut

=head2 exceptionobj

  ExceptionObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item exceptionobj parent

  Object

=back

=over 4

=item exceptionobj composition

  InstanceOf["Data::Object::Exception"]

=back

=over 4

=item exceptionobj example #1

  # package ExceptionExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Exception';

  package main;

  bless {}, 'ExceptionExample';

=back

=cut

=head2 exceptionobject

  ExceptionObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item exceptionobject parent

  Object

=back

=over 4

=item exceptionobject composition

  InstanceOf["Data::Object::Exception"]

=back

=over 4

=item exceptionobject example #1

  # package ExceptionExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Exception';

  package main;

  bless {}, 'ExceptionExample';

=back

=cut

=head2 floatobj

  FloatObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item floatobj parent

  Object

=back

=over 4

=item floatobj composition

  InstanceOf["Data::Object::Float"]

=back

=over 4

=item floatobj coercion #1

  # coerce from Num

  123

=back

=over 4

=item floatobj coercion #2

  # coerce from LaxNum

  123

=back

=over 4

=item floatobj coercion #3

  # coerce from Str

  '1.23'

=back

=over 4

=item floatobj example #1

  # package FloatExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Float';

  package main;

  my $float = 1.23;

  bless \$float, 'FloatExample';

=back

=cut

=head2 floatobject

  FloatObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item floatobject parent

  Object

=back

=over 4

=item floatobject composition

  InstanceOf["Data::Object::Float"]

=back

=over 4

=item floatobject coercion #1

  # coerce from Num

  123

=back

=over 4

=item floatobject coercion #2

  # coerce from LaxNum

  123

=back

=over 4

=item floatobject coercion #3

  # coerce from Str

  '1.23'

=back

=over 4

=item floatobject example #1

  # package FloatExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Float';

  package main;

  my $float = 1.23;

  bless \$float, 'FloatExample';

=back

=cut

=head2 funcobj

  FuncObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item funcobj parent

  Object

=back

=over 4

=item funcobj composition

  InstanceOf["Data::Object::Func"]

=back

=over 4

=item funcobj example #1

  # package FuncExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Func';

  package main;

  bless {}, 'FuncExample';

=back

=cut

=head2 funcobject

  FuncObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item funcobject parent

  Object

=back

=over 4

=item funcobject composition

  InstanceOf["Data::Object::Func"]

=back

=over 4

=item funcobject example #1

  # package FuncExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Func';

  package main;

  bless {}, 'FuncExample';

=back

=cut

=head2 hashobj

  HashObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item hashobj parent

  Object

=back

=over 4

=item hashobj composition

  InstanceOf["Data::Object::Hash"]

=back

=over 4

=item hashobj coercion #1

  # coerce from HashRef

  {}

=back

=over 4

=item hashobj example #1

  # package HashExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Hash';

  package main;

  bless {}, 'HashExample';

=back

=cut

=head2 hashobject

  HashObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item hashobject parent

  Object

=back

=over 4

=item hashobject composition

  InstanceOf["Data::Object::Hash"]

=back

=over 4

=item hashobject coercion #1

  # coerce from HashRef

  {}

=back

=over 4

=item hashobject example #1

  # package HashExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Hash';

  package main;

  bless {}, 'HashExample';

=back

=cut

=head2 immutable

  Immutable

This type is defined in the L<Data::Object::Types> library.

=over 4

=item immutable parent

  Object

=back

=over 4

=item immutable composition

  ConsumerOf["Data::Object::Role::Immutable"]

=back

=over 4

=item immutable example #1

  # package ImmutableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Immutable';

  package main;

  bless {}, 'ImmutableExample';

=back

=cut

=head2 numobj

  NumObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item numobj parent

  Object

=back

=over 4

=item numobj composition

  InstanceOf["Data::Object::Number"]

=back

=over 4

=item numobj coercion #1

  # coerce from LaxNum

  123

=back

=over 4

=item numobj coercion #2

  # coerce from Str

  '123'

=back

=over 4

=item numobj coercion #3

  # coerce from Int

  99999

=back

=over 4

=item numobj coercion #4

  # coerce from Num

  123

=back

=over 4

=item numobj coercion #5

  # coerce from StrictNum

  123

=back

=over 4

=item numobj example #1

  # package NumberExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Number';

  package main;

  my $num = 123;

  bless \$num, 'NumberExample';

=back

=cut

=head2 numobject

  NumObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item numobject parent

  Object

=back

=over 4

=item numobject composition

  InstanceOf["Data::Object::Number"]

=back

=over 4

=item numobject coercion #1

  # coerce from Num

  123

=back

=over 4

=item numobject coercion #2

  # coerce from StrictNum

  123

=back

=over 4

=item numobject coercion #3

  # coerce from Int

  99999

=back

=over 4

=item numobject coercion #4

  # coerce from LaxNum

  123

=back

=over 4

=item numobject coercion #5

  # coerce from Str

  '123'

=back

=over 4

=item numobject example #1

  # package NumberExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Number';

  package main;

  my $num = 123;

  bless \$num, 'NumberExample';

=back

=cut

=head2 numberobj

  NumberObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item numberobj parent

  Object

=back

=over 4

=item numberobj composition

  InstanceOf["Data::Object::Number"]

=back

=over 4

=item numberobj coercion #1

  # coerce from Int

  99999

=back

=over 4

=item numberobj coercion #2

  # coerce from StrictNum

  123

=back

=over 4

=item numberobj coercion #3

  # coerce from Num

  123

=back

=over 4

=item numberobj coercion #4

  # coerce from Str

  '123'

=back

=over 4

=item numberobj coercion #5

  # coerce from LaxNum

  123

=back

=over 4

=item numberobj example #1

  # package NumberExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Number';

  package main;

  my $num = 123;

  bless \$num, 'NumberExample';

=back

=cut

=head2 numberobject

  NumberObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item numberobject parent

  Object

=back

=over 4

=item numberobject composition

  InstanceOf["Data::Object::Number"]

=back

=over 4

=item numberobject coercion #1

  # coerce from Int

  99999

=back

=over 4

=item numberobject coercion #2

  # coerce from StrictNum

  123

=back

=over 4

=item numberobject coercion #3

  # coerce from Num

  123

=back

=over 4

=item numberobject coercion #4

  # coerce from Str

  '123'

=back

=over 4

=item numberobject coercion #5

  # coerce from LaxNum

  123

=back

=over 4

=item numberobject example #1

  # package NumberExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Number';

  package main;

  my $num = 123;

  bless \$num, 'NumberExample';

=back

=cut

=head2 optsobj

  OptsObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item optsobj parent

  Object

=back

=over 4

=item optsobj composition

  InstanceOf["Data::Object::Opts"]

=back

=over 4

=item optsobj example #1

  # package OptsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Opts';

  package main;

  bless {}, 'OptsExample';

=back

=cut

=head2 optsobject

  OptsObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item optsobject parent

  Object

=back

=over 4

=item optsobject composition

  InstanceOf["Data::Object::Opts"]

=back

=over 4

=item optsobject example #1

  # package OptsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Opts';

  package main;

  bless {}, 'OptsExample';

=back

=cut

=head2 regexpobj

  RegexpObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item regexpobj parent

  Object

=back

=over 4

=item regexpobj composition

  InstanceOf["Data::Object::Regexp"]

=back

=over 4

=item regexpobj coercion #1

  # coerce from RegexpRef

  qr//

=back

=over 4

=item regexpobj example #1

  # package RegexpExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Regexp';

  package main;

  bless {}, 'RegexpExample';

=back

=cut

=head2 regexpobject

  RegexpObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item regexpobject parent

  Object

=back

=over 4

=item regexpobject composition

  InstanceOf["Data::Object::Regexp"]

=back

=over 4

=item regexpobject coercion #1

  # coerce from RegexpRef

  qr//

=back

=over 4

=item regexpobject example #1

  # package RegexpExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Regexp';

  package main;

  bless {}, 'RegexpExample';

=back

=cut

=head2 replaceobj

  ReplaceObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item replaceobj parent

  Object

=back

=over 4

=item replaceobj composition

  InstanceOf["Data::Object::Replace"]

=back

=over 4

=item replaceobj example #1

  # package ReplaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Replace';

  package main;

  bless {}, 'ReplaceExample';

=back

=cut

=head2 replaceobject

  ReplaceObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item replaceobject parent

  Object

=back

=over 4

=item replaceobject composition

  InstanceOf["Data::Object::Replace"]

=back

=over 4

=item replaceobject example #1

  # package ReplaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Replace';

  package main;

  bless {}, 'ReplaceExample';

=back

=cut

=head2 scalarobj

  ScalarObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item scalarobj parent

  Object

=back

=over 4

=item scalarobj composition

  InstanceOf["Data::Object::Scalar"]

=back

=over 4

=item scalarobj coercion #1

  # coerce from ScalarRef

  do { my $i = 0; \$i }

=back

=over 4

=item scalarobj example #1

  # package ScalarExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Scalar';

  package main;

  my $scalar = 'abc';

  bless \$scalar, 'ScalarExample';

=back

=cut

=head2 scalarobject

  ScalarObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item scalarobject parent

  Object

=back

=over 4

=item scalarobject composition

  InstanceOf["Data::Object::Scalar"]

=back

=over 4

=item scalarobject coercion #1

  # coerce from ScalarRef

  do { my $i = 0; \$i }

=back

=over 4

=item scalarobject example #1

  # package ScalarExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Scalar';

  package main;

  my $scalar = 'abc';

  bless \$scalar, 'ScalarExample';

=back

=cut

=head2 searchobj

  SearchObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item searchobj parent

  Object

=back

=over 4

=item searchobj composition

  InstanceOf["Data::Object::Search"]

=back

=over 4

=item searchobj example #1

  # package SearchExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Search';

  package main;

  bless {}, 'SearchExample';

=back

=cut

=head2 searchobject

  SearchObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item searchobject parent

  Object

=back

=over 4

=item searchobject composition

  InstanceOf["Data::Object::Search"]

=back

=over 4

=item searchobject example #1

  # package SearchExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Search';

  package main;

  bless {}, 'SearchExample';

=back

=cut

=head2 spaceobj

  SpaceObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item spaceobj parent

  Object

=back

=over 4

=item spaceobj composition

  InstanceOf["Data::Object::Space"]

=back

=over 4

=item spaceobj coercion #1

  # coerce from Str

  'abc'

=back

=over 4

=item spaceobj example #1

  # package SpaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Space';

  package main;

  bless {}, 'SpaceExample';

=back

=cut

=head2 spaceobject

  SpaceObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item spaceobject parent

  Object

=back

=over 4

=item spaceobject composition

  InstanceOf["Data::Object::Space"]

=back

=over 4

=item spaceobject coercion #1

  # coerce from Str

  'abc'

=back

=over 4

=item spaceobject example #1

  # package SpaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Space';

  package main;

  bless {}, 'SpaceExample';

=back

=cut

=head2 stashable

  Stashable

This type is defined in the L<Data::Object::Types> library.

=over 4

=item stashable parent

  Object

=back

=over 4

=item stashable composition

  ConsumerOf["Data::Object::Role::Stashable"]

=back

=over 4

=item stashable example #1

  # package StashableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Stashable';

  package main;

  bless {}, 'StashableExample';

=back

=cut

=head2 stateobj

  StateObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item stateobj parent

  Object

=back

=over 4

=item stateobj composition

  InstanceOf["Data::Object::State"]

=back

=over 4

=item stateobj example #1

  # package StateExample;

  # use Data::Object::Class;

  # extends 'Data::Object::State';

  package main;

  bless {}, 'StateExample';

=back

=cut

=head2 stateobject

  StateObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item stateobject parent

  Object

=back

=over 4

=item stateobject composition

  InstanceOf["Data::Object::State"]

=back

=over 4

=item stateobject example #1

  # package StateExample;

  # use Data::Object::Class;

  # extends 'Data::Object::State';

  package main;

  bless {}, 'StateExample';

=back

=cut

=head2 strobj

  StrObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item strobj parent

  Object

=back

=over 4

=item strobj composition

  InstanceOf["Data::Object::String"]

=back

=over 4

=item strobj coercion #1

  # coerce from Str

  'abc'

=back

=over 4

=item strobj example #1

  # package StringExample;

  # use Data::Object::Class;

  # extends 'Data::Object::String';

  package main;

  my $string = 'abc';

  bless \$string, 'StringExample';

=back

=cut

=head2 strobject

  StrObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item strobject parent

  Object

=back

=over 4

=item strobject composition

  InstanceOf["Data::Object::String"]

=back

=over 4

=item strobject coercion #1

  # coerce from Str

  'abc'

=back

=over 4

=item strobject example #1

  # package StringExample;

  # use Data::Object::Class;

  # extends 'Data::Object::String';

  package main;

  my $string = 'abc';

  bless \$string, 'StringExample';

=back

=cut

=head2 stringobj

  StringObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item stringobj parent

  Object

=back

=over 4

=item stringobj composition

  InstanceOf["Data::Object::String"]

=back

=over 4

=item stringobj coercion #1

  # coerce from Str

  'abc'

=back

=over 4

=item stringobj example #1

  # package StringExample;

  # use Data::Object::Class;

  # extends 'Data::Object::String';

  package main;

  my $string = 'abc';

  bless \$string, 'StringExample';

=back

=cut

=head2 stringobject

  StringObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item stringobject parent

  Object

=back

=over 4

=item stringobject composition

  InstanceOf["Data::Object::String"]

=back

=over 4

=item stringobject coercion #1

  # coerce from Str

  'abc'

=back

=over 4

=item stringobject example #1

  # package StringExample;

  # use Data::Object::Class;

  # extends 'Data::Object::String';

  package main;

  my $string = 'abc';

  bless \$string, 'StringExample';

=back

=cut

=head2 structobj

  StructObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item structobj parent

  Object

=back

=over 4

=item structobj composition

  InstanceOf["Data::Object::Struct"]

=back

=over 4

=item structobj example #1

  # package StructExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Struct';

  package main;

  bless {}, 'StructExample';

=back

=cut

=head2 structobject

  StructObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item structobject parent

  Object

=back

=over 4

=item structobject composition

  InstanceOf["Data::Object::Struct"]

=back

=over 4

=item structobject example #1

  # package StructExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Struct';

  package main;

  bless {}, 'StructExample';

=back

=cut

=head2 throwable

  Throwable

This type is defined in the L<Data::Object::Types> library.

=over 4

=item throwable parent

  Object

=back

=over 4

=item throwable composition

  ConsumerOf["Data::Object::Role::Throwable"]

=back

=over 4

=item throwable example #1

  # package ThrowableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Throwable';

  package main;

  bless {}, 'ThrowableExample';

=back

=cut

=head2 undefobj

  UndefObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item undefobj parent

  Object

=back

=over 4

=item undefobj composition

  InstanceOf["Data::Object::Undef"]

=back

=over 4

=item undefobj coercion #1

  # coerce from Undef

  undef

=back

=over 4

=item undefobj example #1

  # package UndefExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Undef';

  package main;

  my $undef = undef;

  bless \$undef, 'UndefExample';

=back

=cut

=head2 undefobject

  UndefObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item undefobject parent

  Object

=back

=over 4

=item undefobject composition

  InstanceOf["Data::Object::Undef"]

=back

=over 4

=item undefobject coercion #1

  # coerce from Undef

  undef

=back

=over 4

=item undefobject example #1

  # package UndefExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Undef';

  package main;

  my $undef = undef;

  bless \$undef, 'UndefExample';

=back

=cut

=head2 varsobj

  VarsObj

This type is defined in the L<Data::Object::Types> library.

=over 4

=item varsobj parent

  Object

=back

=over 4

=item varsobj composition

  InstanceOf["Data::Object::Vars"]

=back

=over 4

=item varsobj example #1

  # package VarsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Vars';

  package main;

  bless {}, 'VarsExample';

=back

=cut

=head2 varsobject

  VarsObject

This type is defined in the L<Data::Object::Types> library.

=over 4

=item varsobject parent

  Object

=back

=over 4

=item varsobject composition

  InstanceOf["Data::Object::Vars"]

=back

=over 4

=item varsobject example #1

  # package VarsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Vars';

  package main;

  bless {}, 'VarsExample';

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
