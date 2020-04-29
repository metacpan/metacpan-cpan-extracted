package Data::Object::Cast;

use 5.014;

use strict;
use warnings;

use Data::Object::Space;

use Scalar::Util qw(
  blessed
  looks_like_number
  reftype
);

our $To = 'Data::Object';

our $VERSION = '0.02'; # VERSION

# FUNCTIONS

sub Deduce {
  my ($data) = @_;

  return TypeUndef($data) if not(defined($data));
  return DeduceBlessed($data) if blessed($data);
  return DeduceDefined($data);
}

sub DeduceDefined {
  my ($data) = @_;

  return DeduceReferences($data) if ref($data);
  return DeduceNumberlike($data) if looks_like_number($data);
  return DeduceStringLike($data);
}

sub DeduceBlessed {
  my ($data) = @_;

  return TypeRegexp($data) if $data->isa('Regexp');
  return $data;
}

sub DeduceReferences {
  my ($data) = @_;

  return TypeArray($data) if 'ARRAY' eq ref $data;
  return TypeCode($data) if 'CODE' eq ref $data;
  return TypeHash($data) if 'HASH' eq ref $data;
  return TypeScalar($data); # glob, etc
}

sub DeduceNumberlike {
  my ($data) = @_;

  return TypeFloat($data) if $data =~ /\./;
  return TypeNumber($data);
}

sub DeduceStringLike {
  my ($data) = @_;

  return TypeString($data);
}

sub DeduceDeep {
  my @data = map Deduce($_), @_;

  for my $data (@data) {
    my $type = TypeName($data);

    if ($type and $type eq 'HASH') {
      for my $i (keys %$data) {
        my $val = $data->{$i};
        $data->{$i} = ref($val) ? DeduceDeep($val) : Deduce($val);
      }
    }
    if ($type and $type eq 'ARRAY') {
      for (my $i = 0; $i < @$data; $i++) {
        my $val = $data->[$i];
        $data->[$i] = ref($val) ? DeduceDeep($val) : Deduce($val);
      }
    }
  }

  return wantarray ? (@data) : $data[0];
}

sub Detract {
  my ($data) = (Deduce($_[0]));
  my $type = TypeName($data);

INSPECT:
  return $data unless $type;

  return [@$data] if $type eq 'ARRAY';
  return {%$data} if $type eq 'HASH';

  return $$data if $type eq 'BOOLEAN';
  return $$data if $type eq 'REGEXP';
  return $$data if $type eq 'FLOAT';
  return $$data if $type eq 'NUMBER';
  return $$data if $type eq 'STRING';

  return undef  if $type eq 'UNDEF';

  if ($type eq 'ANY' or $type eq 'SCALAR') {
    $type = reftype($data) // '';

    return [@$data] if $type eq 'ARRAY';
    return {%$data} if $type eq 'HASH';

    return $$data if $type eq 'BOOLEAN';
    return $$data if $type eq 'FLOAT';
    return $$data if $type eq 'NUMBER';
    return $$data if $type eq 'REGEXP';
    return $$data if $type eq 'STRING';

    return undef  if $type eq 'UNDEF';

    if ($type eq 'SCALAR') {
      return do { my $v = $$data; \$v };
    }

    if ($type eq 'REF') {
      $type = TypeName($data = $$data) and goto INSPECT;
    }
  }

  if ($type eq 'CODE') {
    return sub { goto $data };
  }

  return undef;
}

sub DetractDeep {
  my @data = map Detract($_), @_;

  for my $data (@data) {
    if ($data and 'HASH' eq ref $data) {
      for my $i (keys %$data) {
        my $val = $data->{$i};
        $data->{$i} = ref($val) ? DetractDeep($val) : Detract($val);
      }
    }
    if ($data and 'ARRAY' eq ref $data) {
      for (my $i = 0; $i < @$data; $i++) {
        my $val = $data->[$i];
        $data->[$i] = ref($val) ? DetractDeep($val) : Detract($val);
      }
    }
  }

  return wantarray ? (@data) : $data[0];
}

sub TypeName {
  my ($data) = (Deduce($_[0]));

  return "ARRAY" if $data->isa("${To}::Array");
  return "BOOLEAN" if $data->isa("${To}::Boolean");
  return "HASH" if $data->isa("${To}::Hash");
  return "CODE" if $data->isa("${To}::Code");
  return "FLOAT" if $data->isa("${To}::Float");
  return "NUMBER" if $data->isa("${To}::Number");
  return "STRING" if $data->isa("${To}::String");
  return "SCALAR" if $data->isa("${To}::Scalar");
  return "REGEXP" if $data->isa("${To}::Regexp");
  return "UNDEF" if $data->isa("${To}::Undef");

  return undef;
}

sub TypeArray {
  my $class = "${To}::Array";
  my $space = Data::Object::Space->new($class);
  my $point = $space->load->can('new');

  unshift @_, $class and goto $point;
}

sub TypeCode {
  my $class = "${To}::Code";
  my $space = Data::Object::Space->new($class);
  my $point = $space->load->can('new');

  unshift @_, $class and goto $point;
}

sub TypeFloat {
  my $class = "${To}::Float";
  my $space = Data::Object::Space->new($class);
  my $point = $space->load->can('new');

  unshift @_, $class and goto $point;
}

sub TypeHash {
  my $class = "${To}::Hash";
  my $space = Data::Object::Space->new($class);
  my $point = $space->load->can('new');

  unshift @_, $class and goto $point;
}

sub TypeNumber {
  my $class = "${To}::Number";
  my $space = Data::Object::Space->new($class);
  my $point = $space->load->can('new');

  unshift @_, $class and goto $point;
}

sub TypeRegexp {
  my $class = "${To}::Regexp";
  my $space = Data::Object::Space->new($class);
  my $point = $space->load->can('new');

  unshift @_, $class and goto $point;
}

sub TypeScalar {
  my $class = "${To}::Scalar";
  my $space = Data::Object::Space->new($class);
  my $point = $space->load->can('new');

  unshift @_, $class and goto $point;
}

sub TypeString {
  my $class = "${To}::String";
  my $space = Data::Object::Space->new($class);
  my $point = $space->load->can('new');

  unshift @_, $class and goto $point;
}

sub TypeUndef {
  my $class = "${To}::Undef";
  my $space = Data::Object::Space->new($class);
  my $point = $space->load->can('new');

  unshift @_, $class and goto $point;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Cast

=cut

=head1 ABSTRACT

Data Type Casting for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Cast;

  local $Data::Object::Cast::To = 'Test::Object';

  # Data::Object::Cast::Deduce([1..4]); # Test::Object::Array

=cut

=head1 DESCRIPTION

This package provides functions for casting native data types to objects and
the reverse.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 FUNCTIONS

This package implements the following functions:

=cut

=head2 deduce

  Deduce(Any $value) : Object

The Deduce function returns the argument as a data type object.

=over 4

=item Deduce example #1

  # given: synopsis

  Data::Object::Cast::Deduce([1..4])

  # $array

=back

=over 4

=item Deduce example #2

  # given: synopsis

  Data::Object::Cast::Deduce(sub { shift })

  # $code

=back

=over 4

=item Deduce example #3

  # given: synopsis

  Data::Object::Cast::Deduce(1.23)

  # $float

=back

=over 4

=item Deduce example #4

  # given: synopsis

  Data::Object::Cast::Deduce({1..4})

  # $hash

=back

=over 4

=item Deduce example #5

  # given: synopsis

  Data::Object::Cast::Deduce(123)

  # $number

=back

=over 4

=item Deduce example #6

  # given: synopsis

  Data::Object::Cast::Deduce(qr/.*/)

  # $regexp

=back

=over 4

=item Deduce example #7

  # given: synopsis

  Data::Object::Cast::Deduce(\'abc')

  # $scalar

=back

=over 4

=item Deduce example #8

  # given: synopsis

  Data::Object::Cast::Deduce('abc')

  # $string

=back

=over 4

=item Deduce example #9

  # given: synopsis

  Data::Object::Cast::Deduce(undef)

  # $undef

=back

=cut

=head2 deducedeep

  DeduceDeep(Any @args) : (Object)

The DeduceDeep function returns any arguments as data type objects, including
nested data.

=over 4

=item DeduceDeep example #1

  # given: synopsis

  Data::Object::Cast::DeduceDeep([1..4])

  # $array <$number>

=back

=over 4

=item DeduceDeep example #2

  # given: synopsis

  Data::Object::Cast::DeduceDeep({1..4})

  # $hash <$number>

=back

=cut

=head2 detract

  Detract(Any $value) : Any

The Detract function returns the argument as native Perl data type value.

=over 4

=item Detract example #1

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      [1..4]
    )
  )

  # $arrayref

=back

=over 4

=item Detract example #2

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      sub { shift }
    )
  )

  # $coderef

=back

=over 4

=item Detract example #3

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      1.23
    )
  )

  # $number

=back

=over 4

=item Detract example #4

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      {1..4}
    )
  )

  # $hashref

=back

=over 4

=item Detract example #5

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      123
    )
  )

  # $number

=back

=over 4

=item Detract example #6

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      qr/.*/
    )
  )

  # $regexp

=back

=over 4

=item Detract example #7

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      \'abc'
    )
  )

  # $scalarref

=back

=over 4

=item Detract example #8

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      'abc'
    )
  )

  # $string

=back

=over 4

=item Detract example #9

  # given: synopsis

  Data::Object::Cast::Detract(
    Data::Object::Cast::Deduce(
      undef
    )
  )

  # $undef

=back

=cut

=head2 detractdeep

  DetractDeep(Any @args) : (Any)

The DetractDeep function returns any arguments as native Perl data type values,
including nested data.

=over 4

=item DetractDeep example #1

  # given: synopsis

  Data::Object::Cast::DetractDeep(
    Data::Object::Cast::DeduceDeep(
      [1..4]
    )
  )

=back

=over 4

=item DetractDeep example #2

  # given: synopsis

  Data::Object::Cast::DetractDeep(
    Data::Object::Cast::DeduceDeep(
      {1..4}
    )
  )

=back

=cut

=head2 typename

  TypeName(Any $value) : Maybe[Str]

The TypeName function returns the name of the value's data type.

=over 4

=item TypeName example #1

  # given: synopsis

  Data::Object::Cast::TypeName([1..4])

  # 'ARRAY'

=back

=over 4

=item TypeName example #2

  # given: synopsis

  Data::Object::Cast::TypeName(sub { shift })

  # 'CODE'

=back

=over 4

=item TypeName example #3

  # given: synopsis

  Data::Object::Cast::TypeName(1.23)

  # 'FLOAT'

=back

=over 4

=item TypeName example #4

  # given: synopsis

  Data::Object::Cast::TypeName({1..4})

  # 'HASH'

=back

=over 4

=item TypeName example #5

  # given: synopsis

  Data::Object::Cast::TypeName(123)

  # 'NUMBER'

=back

=over 4

=item TypeName example #6

  # given: synopsis

  Data::Object::Cast::TypeName(qr/.*/)

  # 'REGEXP'

=back

=over 4

=item TypeName example #7

  # given: synopsis

  Data::Object::Cast::TypeName(\'abc')

  # 'STRING'

=back

=over 4

=item TypeName example #8

  # given: synopsis

  Data::Object::Cast::TypeName('abc')

  # 'STRING'

=back

=over 4

=item TypeName example #9

  # given: synopsis

  Data::Object::Cast::TypeName(undef)

  # 'UNDEF'

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/foobar/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/foobar/wiki>

L<Project|https://github.com/iamalnewkirk/foobar>

L<Initiatives|https://github.com/iamalnewkirk/foobar/projects>

L<Milestones|https://github.com/iamalnewkirk/foobar/milestones>

L<Contributing|https://github.com/iamalnewkirk/foobar/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/foobar/issues>

=cut
