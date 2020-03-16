package Data::Object::Space;

use 5.014;

use strict;
use warnings;
use routines;

use parent 'Data::Object::Name';

our $VERSION = '2.01'; # VERSION

# METHODS

method append(@args) {
  my $class = $self->class;

  my $path = join '/',
    $self->path, map $class->new($_)->path, @args;

  return $class->new($path);
}

method array($name) {
  no strict 'refs';

  my $class = $self->package;

  return [@{"${class}::${name}"}];
}

method arrays() {
  no strict 'refs';

  my $class = $self->package;

  my $arrays = [
    sort grep !!@{"${class}::$_"},
    grep /^[_a-zA-Z]\w*$/, keys %{"${class}::"}
  ];

  return $arrays;
}

method base() {

  return $self->parse->[-1];
}

method bless($data = {}) {
  my $class = $self->load;

  return CORE::bless $data, $class;
}

method build(@args) {
  my $class = $self->load;

  return $self->call('new', $class, @args);
}

method call($func, @args) {
  my $class = $self->load;

  unless ($func) {
    require Carp;

    my $text = qq[Attempt to call undefined object method in package "$class"];

    Carp::confess $text;
  }

  my $next = $class->can($func);

  unless ($next) {
    require Carp;

    my $text = qq[Unable to locate object method "$func" via package "$class"];

    Carp::confess $text;
  }

  @_ = @args; goto $next;
}

method child(@args) {

  return $self->append(@args);
}

method children() {
  my %list;
  my $path;
  my $type;

  $path = quotemeta $self->path;
  $type = 'pm';

  my $regexp = qr/$path\/[^\/]+\.$type/;

  for my $item (keys %INC) {
    $list{$item}++ if $item =~ /$regexp$/;
  }

  my %seen;

  for my $dir (@INC) {
    next if $seen{$dir}++;

    my $re = quotemeta $dir;
    map { s/^$re\///; $list{$_}++ }
    grep !$list{$_}, glob "$dir/@{[$self->path]}/*.$type";
  }

  my $class = $self->class;

  return [
    map $class->new($_),
    map {s/(.*)\.$type$/$1/r}
    sort keys %list
  ];
}

method class() {

  return ref $self;
}

method cop($func, @args) {
  my $class = $self->load;

  unless ($func) {
    require Carp;

    my $text = qq[Attempt to cop undefined object method from package "$class"];

    Carp::confess $text;
  }

  my $next = $class->can($func);

  unless ($next) {
    require Carp;

    my $text = qq[Unable to locate object method "$func" via package "$class"];

    Carp::confess $text;
  }

  return sub { $next->(@args ? (@args, @_) : @_) };
}

method functions() {
  my @functions;

  no strict 'refs';

  require Function::Parameters::Info;

  my $class = $self->package;
  for my $routine (@{$self->routines}) {
    my $code = $class->can($routine) or next;
    my $data = Function::Parameters::info($code);

    push @functions, $routine if $data && !$data->invocant;
  }

  return [sort @functions];
}

method hash($name) {
  no strict 'refs';

  my $class = $self->package;

  return {%{"${class}::${name}"}};
}

method hashes() {
  no strict 'refs';

  my $class = $self->package;

  return [
    sort grep !!%{"${class}::$_"},
    grep /^[_a-zA-Z]\w*$/, keys %{"${class}::"}
  ];
}

method id() {

  return $self->label;
}

method inherits() {

  return $self->array('ISA');
}

my $loaded_spaces = {};

method load() {
  my $class = $self->package;

  return $class if $loaded_spaces->{$class};

  my $failed = !$class || $class !~ /^\w(?:[\w:']*\w)?$/;
  my $loaded;

  my $error = do {
    local $@;
    no strict 'refs';
    $loaded = !!$class->can('new');
    $loaded = !!$class->can('import') if !$loaded;
    $loaded = !!$class->can('meta') if !$loaded;
    $loaded = !!$class->can('with') if !$loaded;
    $loaded = eval "require $class; 1" if !$loaded;
    $@;
  }
  if !$failed;

  do {
    require Carp;

    my $message = $error || "cause unknown";

    Carp::confess "Error attempting to load $class: $message";
  }
  if $error
  or $failed
  or not $loaded;

  $loaded_spaces->{$class} = 1;

  return $class;
}

method methods() {
  my @methods;

  no strict 'refs';

  require Function::Parameters::Info;

  my $class = $self->package;
  for my $routine (@{$self->routines}) {
    my $code = $class->can($routine) or next;
    my $data = Function::Parameters::info($code);

    push @methods, $routine if $data && $data->invocant;
  }

  return [sort @methods];
}

method name() {

  return $self->package;
}

method parent() {
  my @parts = @{$self->parse};

  pop @parts if @parts > 1;

  my $class = $self->class;

  return $class->new(join '/', @parts);
}

method parse() {

  return [
    map ucfirst,
    map join('', map(ucfirst, split /[-_]/)),
    split /[^-_a-zA-Z0-9.]+/,
    $self->path
  ];
}

method parts() {

  return $self->parse;
}

method prepend(@args) {
  my $class = $self->class;

  my $path = join '/',
    (map $class->new($_)->path, @args), $self->path;

  return $class->new($path);
}

method root() {

  return $self->parse->[0];
}

method routine($name) {
  no strict 'refs';

  my $class = $self->package;

  return *{"${class}::${name}"}{"CODE"};
}

method routines() {
  no strict 'refs';

  my $class = $self->package;

  return [
    sort grep *{"${class}::$_"}{"CODE"},
    grep /^[_a-zA-Z]\w*$/, keys %{"${class}::"}
  ];
}

method scalar($name) {
  no strict 'refs';

  my $class = $self->package;

  return ${"${class}::${name}"};
}

method scalars() {
  no strict 'refs';

  my $class = $self->package;

  return [
    sort grep defined ${"${class}::$_"},
    grep /^[_a-zA-Z]\w*$/, keys %{"${class}::"}
  ];
}

method sibling(@args) {

  return $self->parent->append(@args);
}

method siblings() {
  my %list;
  my $path;
  my $type;

  $path = quotemeta $self->parent->path;
  $type = 'pm';

  my $regexp = qr/$path\/[^\/]+\.$type/;

  for my $item (keys %INC) {
    $list{$item}++ if $item =~ /$regexp$/;
  }

  my %seen;

  for my $dir (@INC) {
    next if $seen{$dir}++;

    my $re = quotemeta $dir;
    map { s/^$re\///; $list{$_}++ }
    grep !$list{$_}, glob "$dir/@{[$self->path]}/*.$type";
  }

  my $class = $self->class;

  return [
    map $class->new($_),
    map {s/(.*)\.$type$/$1/r}
    sort keys %list
  ];
}

method used() {
  my $class = $self->package;
  my $loaded = $loaded_spaces->{$class};
  my $path = $self->path;
  my $regexp = quotemeta $path;

  if ($loaded) {

    return $path;
  }
  for my $item (keys %INC) {

    return $path if $item =~ /$regexp\.pm$/;
  }

  return '';
}

method variables() {

  return [map [$_, [sort @{$self->$_}]], qw(arrays hashes scalars)];
}

method version() {

  return $self->scalar('VERSION');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Space

=cut

=head1 ABSTRACT

Namespace Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/bar');

=cut

=head1 DESCRIPTION

This package provides methods for parsing and manipulating package namespaces.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Name>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 append

  append(Str @args) : Object

The append method modifies the object by appending to the package namespace
parts.

=over 4

=item append example #1

  # given: synopsis

  $space->append('baz');

  # 'Foo/Bar/Baz'

=back

=over 4

=item append example #2

  # given: synopsis

  $space->append('baz', 'bax');

  # $space->package;

  # 'Foo/Bar/Baz/Bax'

=back

=cut

=head2 array

  array(Str $arg1) : ArrayRef

The array method returns the value for the given package array variable name.

=over 4

=item array example #1

  # given: synopsis

  package Foo::Bar;

  our @handler = 'start';

  package main;

  $space->array('handler')

  # ['start']

=back

=cut

=head2 arrays

  arrays() : ArrayRef

The arrays method searches the package namespace for arrays and returns their
names.

=over 4

=item arrays example #1

  # given: synopsis

  package Foo::Bar;

  our @handler = 'start';
  our @initial = ('next', 'prev');

  package main;

  $space->arrays

  # ['handler', 'initial']

=back

=cut

=head2 base

  base() : Str

The base method returns the last segment of the package namespace parts.

=over 4

=item base example #1

  # given: synopsis

  $space->base

  # Bar

=back

=cut

=head2 bless

  bless(Any $arg1 = {}) : Object

The bless method blesses the given value into the package namespace and returns
an object. If no value is given, an empty hashref is used.

=over 4

=item bless example #1

  # given: synopsis

  package Foo::Bar;

  sub import;

  package main;

  $space->bless

  # bless({}, 'Foo::Bar')

=back

=over 4

=item bless example #2

  # given: synopsis

  package Foo::Bar;

  sub import;

  package main;

  $space->bless({okay => 1})

  # bless({okay => 1}, 'Foo::Bar')

=back

=cut

=head2 build

  build(Any @args) : Object

The build method attempts to call C<new> on the package namespace and if successful returns the resulting object.

=over 4

=item build example #1

  package Foo::Bar::Baz;

  sub new {
    bless {}, $_[0]
  }

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/bar/baz');

  $space->build

  # bless({}, 'Foo::Bar::Baz')

=back

=over 4

=item build example #2

  package Foo::Bar::Bax;

  sub new {
    bless $_[1], $_[0]
  }

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/bar/bax');

  $space->build({okay => 1})

  # bless({okay => 1}, 'Foo::Bar::Bax')

=back

=cut

=head2 call

  call(Any @args) : Any

The call method attempts to call the given subroutine on the package namespace
and if successful returns the resulting value.

=over 4

=item call example #1

  # given: synopsis

  package Foo;

  sub import;

  sub start {
    'started'
  }

  package main;

  use Data::Object::Space;

  $space = Data::Object::Space->new('foo');

  $space->call('start')

  # started

=back

=cut

=head2 child

  child(Str $arg1) : Object

The child method returns a new L<Data::Object::Space> object for the child
package namespace.

=over 4

=item child example #1

  # given: synopsis

  $space->child('baz');

  # $space->package;

  # Foo::Bar::Baz

=back

=cut

=head2 children

  children() : ArrayRef[Object]

The children method searches C<%INC> and C<@INC> and retuns a list of
L<Data::Object::Space> objects for each child namespace found (one level deep).

=over 4

=item children example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('c_p_a_n');

  $space->children

  # [
  #   'CPAN/Author',
  #   'CPAN/Bundle',
  #   'CPAN/CacheMgr',
  #   ...
  # ]

=back

=cut

=head2 cop

  cop(Any @args) : CodeRef

The cop method attempts to curry the given subroutine on the package namespace
and if successful returns a closure.

=over 4

=item cop example #1

  # given: synopsis

  package Foo::Bar;

  sub import;

  sub handler {
    [@_]
  }

  package main;

  use Data::Object::Space;

  $space = Data::Object::Space->new('foo/bar');

  $space->cop('handler', $space->bless)

  # sub { Foo::Bar::handler(..., @_) }

=back

=cut

=head2 functions

  functions() : ArrayRef

The functions method searches the package namespace for functions and returns
their names.

=over 4

=item functions example #1

  package Foo::Functions;

  use routines;

  fun start() {
    1
  }

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/functions');

  $space->functions

  # ['start']

=back

=cut

=head2 hash

  hash(Str $arg1) : HashRef

The hash method returns the value for the given package hash variable name.

=over 4

=item hash example #1

  # given: synopsis

  package Foo::Bar;

  our %settings = (
    active => 1
  );

  package main;

  $space->hash('settings')

  # {active => 1}

=back

=cut

=head2 hashes

  hashes() : ArrayRef

The hashes method searches the package namespace for hashes and returns their
names.

=over 4

=item hashes example #1

  # given: synopsis

  package Foo::Bar;

  our %defaults = (
    active => 0
  );

  our %settings = (
    active => 1
  );

  package main;

  $space->hashes

  # ['defaults', 'settings']

=back

=cut

=head2 id

  id() : Str

The id method returns the fully-qualified package name as a label.

=over 4

=item id example #1

  # given: synopsis

  $space->id

  # Foo_Bar

=back

=cut

=head2 inherits

  inherits() : ArrayRef

The inherits method returns the list of superclasses the target package is
derived from.

=over 4

=item inherits example #1

  package Bar;

  package main;

  my $space = Data::Object::Space->new('bar');

  $space->inherits

  # []

=back

=over 4

=item inherits example #2

  package Foo;

  package Bar;

  use base 'Foo';

  package main;

  my $space = Data::Object::Space->new('bar');

  $space->inherits

  # ['Foo']

=back

=cut

=head2 load

  load() : Str

The load method checks whether the package namespace is already loaded and if
not attempts to load the package. If the package is not loaded and is not
loadable, this method will throw an exception using confess. If the package is
loadable, this method returns truthy with the package name. As a workaround for
packages that only exist in-memory, if the package contains a C<new>, C<with>,
C<meta>, or C<import> routine it will be recognized as having been loaded.

=over 4

=item load example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('c_p_a_n');

  $space->load

  # CPAN

=back

=cut

=head2 methods

  methods() : ArrayRef

The methods method searches the package namespace for methods and returns their
names.

=over 4

=item methods example #1

  package Foo::Methods;

  use routines;

  method start() {
    1
  }

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/methods');

  $space->methods

  # ['start']

=back

=cut

=head2 name

  name() : Str

The name method returns the fully-qualified package name.

=over 4

=item name example #1

  # given: synopsis

  $space->name

  # Foo::Bar

=back

=cut

=head2 parent

  parent() : Object

The parent method returns a new L<Data::Object::Space> object for the parent
package namespace.

=over 4

=item parent example #1

  # given: synopsis

  $space->parent;

  # $space->package;

  # Foo

=back

=cut

=head2 parse

  parse() : ArrayRef

The parse method parses the string argument and returns an arrayref of package
namespace segments (parts).

=over 4

=item parse example #1

  my $space = Data::Object::Space->new('Foo::Bar');

  $space->parse;

  # ['Foo', 'Bar']

=back

=over 4

=item parse example #2

  my $space = Data::Object::Space->new('Foo/Bar');

  $space->parse;

  # ['Foo', 'Bar']

=back

=over 4

=item parse example #3

  my $space = Data::Object::Space->new('Foo\Bar');

  $space->parse;

  # ['Foo', 'Bar']

=back

=over 4

=item parse example #4

  my $space = Data::Object::Space->new('foo-bar');

  $space->parse;

  # ['FooBar']

=back

=over 4

=item parse example #5

  my $space = Data::Object::Space->new('foo_bar');

  $space->parse;

  # ['FooBar']

=back

=cut

=head2 parts

  parts() : ArrayRef

The parts method returns an arrayref of package namespace segments (parts).

=over 4

=item parts example #1

  my $space = Data::Object::Space->new('foo');

  $space->parts;

  # ['Foo']

=back

=over 4

=item parts example #2

  my $space = Data::Object::Space->new('foo/bar');

  $space->parts;

  # ['Foo', 'Bar']

=back

=over 4

=item parts example #3

  my $space = Data::Object::Space->new('foo_bar');

  $space->parts;

  # ['FooBar']

=back

=cut

=head2 prepend

  prepend(Str @args) : Object

The prepend method modifies the object by prepending to the package namespace
parts.

=over 4

=item prepend example #1

  # given: synopsis

  $space->prepend('etc');

  # 'Etc/Foo/Bar'

=back

=over 4

=item prepend example #2

  # given: synopsis

  $space->prepend('etc', 'tmp');

  # 'Etc/Tmp/Foo/Bar'

=back

=cut

=head2 root

  root() : Str

The root method returns the root package namespace segments (parts). Sometimes
separating the C<root> from the C<parts> helps identify how subsequent child
objects were derived.

=over 4

=item root example #1

  # given: synopsis

  $space->root

  # Foo

=back

=cut

=head2 routine

  routine(Str $arg1) : CodeRef

The routine method returns the subroutine reference for the given subroutine
name.

=over 4

=item routine example #1

  package Foo;

  sub cont {
    [@_]
  }

  sub abort {
    [@_]
  }

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo');

  $space->routine('cont')

  # sub { ... }

=back

=cut

=head2 routines

  routines() : ArrayRef

The routines method searches the package namespace for routines and returns
their names.

=over 4

=item routines example #1

  package Foo::Routines;

  sub start {
    1
  }

  sub abort {
    1
  }

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/routines');

  $space->routines

  # ['start', 'abort']

=back

=cut

=head2 scalar

  scalar(Str $arg1) : Any

The scalar method returns the value for the given package scalar variable name.

=over 4

=item scalar example #1

  # given: synopsis

  package Foo::Bar;

  our $root = '/path/to/file';

  package main;

  $space->scalar('root')

  # /path/to/file

=back

=cut

=head2 scalars

  scalars() : ArrayRef

The scalars method searches the package namespace for scalars and returns their
names.

=over 4

=item scalars example #1

  # given: synopsis

  package Foo::Bar;

  our $root = 'root';
  our $base = 'path/to';
  our $file = 'file';

  package main;

  $space->scalars

  # ['root', 'base', 'file']

=back

=cut

=head2 sibling

  sibling(Str $arg1) : Object

The sibling method returns a new L<Data::Object::Space> object for the sibling
package namespace.

=over 4

=item sibling example #1

  # given: synopsis

  $space->sibling('baz')

  # Foo::Baz

=back

=cut

=head2 siblings

  siblings() : ArrayRef[Object]

The siblings method searches C<%INC> and C<@INC> and retuns a list of
L<Data::Object::Space> objects for each sibling namespace found (one level
deep).

=over 4

=item siblings example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('encode/m_i_m_e');

  $space->siblings

  # [
  #   'Encode/Alias',
  #   'Encode/Config'
  #   ...
  # ]

=back

=cut

=head2 used

  used() : Str

The used method searches C<%INC> for the package namespace and if found returns
the filepath and complete filepath for the loaded package, otherwise returns
falsy with an empty string.

=over 4

=item used example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/xyz');

  $space->used

  # ''

=back

=over 4

=item used example #2

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('c_p_a_n');

  $space->load;
  $space->used

  # 'CPAN'

=back

=over 4

=item used example #3

  package Foo::Bar;

  sub import;

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/bar');

  $space->used

  # 'Foo/Bar'

=back

=cut

=head2 variables

  variables() : ArrayRef[Tuple[Str, ArrayRef]]

The variables method searches the package namespace for variables and returns
their names.

=over 4

=item variables example #1

  package Etc;

  our $init = 0;
  our $func = 1;

  our @does = (1..4);
  our %sets = (1..4);

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('etc');

  $space->variables

  # [
  #   ['arrays', ['does']],
  #   ['hashes', ['sets']],
  #   ['scalars', ['func', 'init']],
  # ]

=back

=cut

=head2 version

  version() : Maybe[Str]

The version method returns the C<VERSION> declared on the target package, if
any.

=over 4

=item version example #1

  package Foo::Boo;

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/boo');

  $space->version

  # undef

=back

=over 4

=item version example #2

  package Foo::Boo;

  our $VERSION = 0.01;

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/boo');

  $space->version

  # '0.01'

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-space/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-space/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-space>

L<Initiatives|https://github.com/iamalnewkirk/data-object-space/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-space/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-space/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-space/issues>

=cut
