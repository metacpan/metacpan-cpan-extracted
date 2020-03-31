package Data::Object::Attributes;

use 5.014;

use strict;
use warnings;
use registry;
use routines;

use Moo;

our $VERSION = '0.06'; # VERSION

# BUILD

my $builders = {};

fun import($class, @args) {
  my $has = (my $target = caller)->can('has') or return;

  no strict 'refs';
  no warnings 'redefine';

  *{"${target}::has"} = generate([$class, $target], $has);

  return;
}

fun generate($info, $orig) {
  # generate "has" keyword

  return fun(@args) { @_ = options($info, @args); goto $orig };
}

$builders->{new} = fun($info, $name, %opts) {
  if (delete $opts{new}) {
    $opts{builder} = "new_${name}";
    $opts{lazy} = 1;
  }

  return (%opts);
};

$builders->{bld} = fun($info, $name, %opts) {
  $opts{builder} = delete $opts{bld};

  return (%opts);
};

$builders->{clr} = fun($info, $name, %opts) {
  $opts{clearer} = delete $opts{clr};

  return (%opts);
};

$builders->{crc} = fun($info, $name, %opts) {
  $opts{coerce} = delete $opts{crc};

  return (%opts);
};

$builders->{def} = fun($info, $name, %opts) {
  $opts{default} = delete $opts{def};

  return (%opts);
};

$builders->{hnd} = fun($info, $name, %opts) {
  $opts{handles} = delete $opts{hnd};

  return (%opts);
};

$builders->{isa} = fun($info, $name, %opts) {
  return (%opts) if ref($opts{isa});

  my $registry = registry::access($info->[1]);

  return (%opts) if !$registry;

  my $constraint = $registry->lookup($opts{isa});

  return (%opts) if !$constraint;

  $opts{isa} = $constraint;

  return (%opts);
};

$builders->{lzy} = fun($info, $name, %opts) {
  $opts{lazy} = delete $opts{lzy};

  return (%opts);
};

$builders->{opt} = fun($info, $name, %opts) {
  delete $opts{opt};

  $opts{required} = 0;

  return (%opts);
};

$builders->{pre} = fun($info, $name, %opts) {
  $opts{predicate} = delete $opts{pre};

  return (%opts);
};

$builders->{rdr} = fun($info, $name, %opts) {
  $opts{reader} = delete $opts{rdr};

  return (%opts);
};

$builders->{req} = fun($info, $name, %opts) {
  delete $opts{req};

  $opts{required} = 1;

  return (%opts);
};

$builders->{tgr} = fun($info, $name, %opts) {
  $opts{trigger} = delete $opts{tgr};

  return (%opts);
};

$builders->{use} = fun($info, $name, %opts) {
  if (my $use = delete $opts{use}) {
    $opts{builder} = $builders->{use_builder}->($info, $name, @$use);
    $opts{lazy} = 1;
  }

  return (%opts);
};

$builders->{use_builder} = fun($info, $name, $sub, @args) {
  return fun($self) {
    @_ = ($self, @args);

    my $point = $self->can($sub) or do {
      require Carp;

      my $class = $info->[1];

      Carp::confess("has '$name' cannot 'use' method '$sub' via package '$class'");
    };

    goto $point;
  };
};

$builders->{wkr} = fun($info, $name, %opts) {
  $opts{weak_ref} = delete $opts{wkr};

  return (%opts);
};

$builders->{wrt} = fun($info, $name, %opts) {
  $opts{writer} = delete $opts{wrt};

  return (%opts);
};

fun options($info, $name, %opts) {
  %opts = (is => 'rw') unless %opts;

  $opts{mod} = 1 if $name =~ s/^\+//;

  %opts = (%opts, $builders->{new}->($info, $name, %opts)) if defined $opts{new};
  %opts = (%opts, $builders->{bld}->($info, $name, %opts)) if defined $opts{bld};
  %opts = (%opts, $builders->{clr}->($info, $name, %opts)) if defined $opts{clr};
  %opts = (%opts, $builders->{crc}->($info, $name, %opts)) if defined $opts{crc};
  %opts = (%opts, $builders->{def}->($info, $name, %opts)) if defined $opts{def};
  %opts = (%opts, $builders->{hnd}->($info, $name, %opts)) if defined $opts{hnd};
  %opts = (%opts, $builders->{isa}->($info, $name, %opts)) if defined $opts{isa};
  %opts = (%opts, $builders->{lzy}->($info, $name, %opts)) if defined $opts{lzy};
  %opts = (%opts, $builders->{opt}->($info, $name, %opts)) if defined $opts{opt};
  %opts = (%opts, $builders->{pre}->($info, $name, %opts)) if defined $opts{pre};
  %opts = (%opts, $builders->{rdr}->($info, $name, %opts)) if defined $opts{rdr};
  %opts = (%opts, $builders->{req}->($info, $name, %opts)) if defined $opts{req};
  %opts = (%opts, $builders->{tgr}->($info, $name, %opts)) if defined $opts{tgr};
  %opts = (%opts, $builders->{use}->($info, $name, %opts)) if defined $opts{use};
  %opts = (%opts, $builders->{wkr}->($info, $name, %opts)) if defined $opts{wkr};
  %opts = (%opts, $builders->{wrt}->($info, $name, %opts)) if defined $opts{wrt};

  $name = "+$name" if delete $opts{mod} || delete $opts{modify};

  return ($name, %opts);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Attributes

=cut

=head1 ABSTRACT

Attribute Builder for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  use Data::Object::Attributes;

  has 'data';

  package main;

  my $example = Example->new;

=cut

=head1 DESCRIPTION

This package provides options for defining class attributes. Specifically, this
package wraps the C<has> attribute keyword and adds shortcuts and enhancements.
If no directives are specified, the attribute is declared as C<read-write> and
C<optional>.

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 has

  package Example::Has;

  use Moo;

  has 'data' => (
    is => 'ro',
    isa => sub { die }
  );

  package Example::HasData;

  use Moo;

  use Data::Object::Attributes;

  extends 'Example::Has';

  has '+data' => (
    is => 'ro',
    isa => sub { 1 }
  );

  package main;

  my $example = Example::HasData->new(data => time);

This package supports the C<has> keyword function and all of its
configurations. See the L<Moo> documentation for more details.

=cut

=head2 has-bld

  package Example::HasBld;

  use Moo;
  use routines;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    bld => 1
  );

  method _build_data() {

    return time;
  }

  package main;

  my $example = Example::HasBld->new;

This package supports the C<bld> and C<builder> directives, expects a C<1>, a
method name, or coderef and builds the attribute value if it wasn't provided to
the constructor. See the L<Moo> documentation for more details.

=cut

=head2 has-clr

  package Example::HasClr;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    clr => 1
  );

  package main;

  my $example = Example::HasClr->new(data => time);

  # $example->clear_data;

This package supports the C<clr> and C<clearer> directives expects a C<1> or a
method name of the clearer method. See the L<Moo> documentation for more
details.

=cut

=head2 has-crc

  package Example::HasCrc;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    crc => sub {'0'}
  );

  package main;

  my $example = Example::HasCrc->new(data => time);

This package supports the C<crc> and C<coerce> directives denotes whether an
attribute's value should be automatically coerced. See the L<Moo> documentation
for more details.

=cut

=head2 has-def

  package Example::HasDef;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    def => '0'
  );

  package main;

  my $example = Example::HasDef->new;

This package supports the C<def> and C<default> directives expects a
non-reference or a coderef to be used to build a default value if one is not
provided to the constructor. See the L<Moo> documentation for more details.

=cut

=head2 has-hnd

  package Example::Time;

  use Moo;
  use routines;

  method maketime() {

    return time;
  }

  package Example::HasHnd;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    hnd => ['maketime']
  );

  package main;

  my $example = Example::HasHnd->new(data => Example::Time->new);

This package supports the C<hnd> and C<handles> directives denotes the methods
created on the object which dispatch to methods available on the attribute's
object. See the L<Moo> documentation for more details.

=cut

=head2 has-is

  package Example::HasIs;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro'
  );

  package main;

  my $example = Example::HasIs->new(data => time);

This package supports the C<is> directive, used to denote whether the attribute
is read-only or read-write. See the L<Moo> documentation for more details.

=cut

=head2 has-isa

  package Example::HasIsa;

  use Moo;
  use registry;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    isa => 'Str' # e.g. Types::Standard::Str
  );

  package main;

  my $example = Example::HasIsa->new(data => time);

This package supports the C<isa> directive, used to define the type constraint
to validate the attribute against. See the L<Moo> documentation for more
details.

=cut

=head2 has-lzy

  package Example::HasLzy;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    def => sub {time},
    lzy => 1
  );

  package main;

  my $example = Example::HasLzy->new;

This package supports the C<lzy> and C<lazy> directives denotes whether the
attribute will be constructed on-demand, or on-construction. See the L<Moo>
documentation for more details.

=cut

=head2 has-mod

  package Example::HasNomod;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'rw',
    opt => 1
  );

  package Example::HasMod;

  use Moo;

  use Data::Object::Attributes;

  extends 'Example::HasNomod';

  has data => (
    is => 'ro',
    req => 1,
    mod => 1
  );

  package main;

  my $example = Example::HasMod->new;

This package supports the C<mod> and C<modify> directives denotes whether a
pre-existing attribute's definition is being modified. This ability is not
supported by the L<Moo> object superclass.

=cut

=head2 has-new

  package Example::HasNew;

  use Moo;
  use routines;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    new => 1
  );

  fun new_data($self) {

    return time;
  }

  package main;

  my $example = Example::HasNew->new(data => time);

This package supports the C<new> directive, if truthy, denotes that the
attribute will be constructed on-demand, i.e. is lazy, with a builder named
new_{attribute}. This ability is not supported by the L<Moo> object superclass.

=cut

=head2 has-opt

  package Example::HasOpt;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    opt => 1
  );

  package main;

  my $example = Example::HasOpt->new(data => time);

This package supports the C<opt> and C<optional> directives, used to denote if
an attribute is optional or required. See the L<Moo> documentation for more
details.

=cut

=head2 has-pre

  package Example::HasPre;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    pre => 1
  );

  package main;

  my $example = Example::HasPre->new(data => time);

This package supports the C<pre> and C<predicate> directives expects a C<1> or
a method name and generates a method for checking the existance of the
attribute. See the L<Moo> documentation for more details.

=cut

=head2 has-rdr

  package Example::HasRdr;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    rdr => 'get_data'
  );

  package main;

  my $example = Example::HasRdr->new(data => time);

This package supports the C<rdr> and C<reader> directives denotes the name of
the method to be used to "read" and return the attribute's value. See the
L<Moo> documentation for more details.

=cut

=head2 has-req

  package Example::HasReq;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    req => 1 # required
  );

  package main;

  my $example = Example::HasReq->new(data => time);

This package supports the C<req> and C<required> directives, used to denote if
an attribute is required or optional. See the L<Moo> documentation for more
details.

=cut

=head2 has-tgr

  package Example::HasTgr;

  use Moo;
  use routines;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    tgr => 1
  );

  method _trigger_data() {
    $self->{triggered} = 1;

    return $self;
  }

  package main;

  my $example = Example::HasTgr->new(data => time);

This package supports the C<tgr> and C<trigger> directives expects a C<1> or a
coderef and is executed whenever the attribute's value is changed. See the
L<Moo> documentation for more details.

=cut

=head2 has-use

  package Example::HasUse;

  use Moo;
  use routines;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    use => ['service', 'time']
  );

  method service($type, @args) {
    $self->{serviced} = 1;

    return time if $type eq 'time';
  }

  package main;

  my $example = Example::HasUse->new;

This package supports the C<use> directive denotes that the attribute will be
constructed on-demand, i.e. is lazy, using a custom builder meant to perform
service construction. This directive exists to provide a simple dependency
injection mechanism for class attributes. This ability is not supported by the
L<Moo> object superclass.

=cut

=head2 has-wkr

  package Example::HasWkr;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    wkr => 1
  );

  package main;

  my $data = do {
    my ($a, $b);

    $a = { time => time };
    $b = { time => $a };

    $a->{time} = $b;
    $a
  };

  my $example = Example::HasWkr->new(data => $data);

This package supports the C<wkr> and C<weak_ref> directives is used to denote if
the attribute's value should be weakened. See the L<Moo> documentation for more
details.

=cut

=head2 has-wrt

  package Example::HasWrt;

  use Moo;

  use Data::Object::Attributes;

  has data => (
    is => 'ro',
    wrt => 'set_data'
  );

  package main;

  my $example = Example::HasWrt->new;

This package supports the C<wrt> and C<writer> directives denotes the name of
the method to be used to "write" and return the attribute's value. See the
L<Moo> documentation for more details.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-attributes/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-attributes/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-attributes>

L<Initiatives|https://github.com/iamalnewkirk/data-object-attributes/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-attributes/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-attributes/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-attributes/issues>

=cut
