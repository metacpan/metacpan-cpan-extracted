use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Space

=cut

=abstract

Namespace Class for Perl 5

=cut

=includes

method: append
method: array
method: arrays
method: base
method: bless
method: build
method: call
method: child
method: children
method: cop
method: functions
method: hash
method: hashes
method: id
method: inherits
method: load
method: methods
method: name
method: parent
method: parse
method: parts
method: prepend
method: root
method: routine
method: routines
method: scalar
method: scalars
method: sibling
method: siblings
method: used
method: variables
method: version

=cut

=inherits

Data::Object::Name

=cut

=libraries

Types::Standard

=cut

=synopsis

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/bar');

=cut

=description

This package provides methods for parsing and manipulating package namespaces.

=cut

=method append

The append method modifies the object by appending to the package namespace
parts.

=signature append

append(Str @args) : Object

=example-1 append

  # given: synopsis

  $space->append('baz');

  # 'Foo/Bar/Baz'

=example-2 append

  # given: synopsis

  $space->append('baz', 'bax');

  # $space->package;

  # 'Foo/Bar/Baz/Bax'

=cut

=method array

The array method returns the value for the given package array variable name.

=signature array

array(Str $arg1) : ArrayRef

=example-1 array

  # given: synopsis

  package Foo::Bar;

  our @handler = 'start';

  package main;

  $space->array('handler')

  # ['start']

=cut

=method arrays

The arrays method searches the package namespace for arrays and returns their
names.

=signature arrays

arrays() : ArrayRef

=example-1 arrays

  # given: synopsis

  package Foo::Bar;

  our @handler = 'start';
  our @initial = ('next', 'prev');

  package main;

  $space->arrays

  # ['handler', 'initial']

=cut

=method base

The base method returns the last segment of the package namespace parts.

=signature base

base() : Str

=example-1 base

  # given: synopsis

  $space->base

  # Bar

=cut

=method bless

The bless method blesses the given value into the package namespace and returns
an object. If no value is given, an empty hashref is used.

=signature bless

bless(Any $arg1 = {}) : Object

=example-1 bless

  # given: synopsis

  package Foo::Bar;

  sub import;

  package main;

  $space->bless

  # bless({}, 'Foo::Bar')

=example-2 bless

  # given: synopsis

  package Foo::Bar;

  sub import;

  package main;

  $space->bless({okay => 1})

  # bless({okay => 1}, 'Foo::Bar')

=cut

=method build

The build method attempts to call C<new> on the package namespace and if successful returns the resulting object.

=signature build

build(Any @args) : Object

=example-1 build

  package Foo::Bar::Baz;

  sub new {
    bless {}, $_[0]
  }

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/bar/baz');

  $space->build

  # bless({}, 'Foo::Bar::Baz')

=example-2 build

  package Foo::Bar::Bax;

  sub new {
    bless $_[1], $_[0]
  }

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/bar/bax');

  $space->build({okay => 1})

  # bless({okay => 1}, 'Foo::Bar::Bax')

=cut

=method call

The call method attempts to call the given subroutine on the package namespace
and if successful returns the resulting value.

=signature call

call(Any @args) : Any

=example-1 call

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

=cut

=method child

The child method returns a new L<Data::Object::Space> object for the child
package namespace.

=signature child

child(Str $arg1) : Object

=example-1 child

  # given: synopsis

  $space->child('baz');

  # $space->package;

  # Foo::Bar::Baz

=cut

=method children

The children method searches C<%INC> and C<@INC> and retuns a list of
L<Data::Object::Space> objects for each child namespace found (one level deep).

=signature children

children() : ArrayRef[Object]

=example-1 children

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

=cut

=method cop

The cop method attempts to curry the given subroutine on the package namespace
and if successful returns a closure.

=signature cop

cop(Any @args) : CodeRef

=example-1 cop

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

=cut

=method functions

The functions method searches the package namespace for functions and returns
their names.

=signature functions

functions() : ArrayRef

=example-1 functions

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

=cut

=method hash

The hash method returns the value for the given package hash variable name.

=signature hash

hash(Str $arg1) : HashRef

=example-1 hash

  # given: synopsis

  package Foo::Bar;

  our %settings = (
    active => 1
  );

  package main;

  $space->hash('settings')

  # {active => 1}

=cut

=method hashes

The hashes method searches the package namespace for hashes and returns their
names.

=signature hashes

hashes() : ArrayRef

=example-1 hashes

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

=cut

=method id

The id method returns the fully-qualified package name as a label.

=signature id

id() : Str

=example-1 id

  # given: synopsis

  $space->id

  # Foo_Bar

=cut

=method inherits

The inherits method returns the list of superclasses the target package is
derived from.

=signature inherits

inherits() : ArrayRef

=example-1 inherits

  package Bar;

  package main;

  my $space = Data::Object::Space->new('bar');

  $space->inherits

  # []

=example-2 inherits

  package Foo;

  package Bar;

  use base 'Foo';

  package main;

  my $space = Data::Object::Space->new('bar');

  $space->inherits

  # ['Foo']

=cut

=method load

The load method checks whether the package namespace is already loaded and if
not attempts to load the package. If the package is not loaded and is not
loadable, this method will throw an exception using confess. If the package is
loadable, this method returns truthy with the package name. As a workaround for
packages that only exist in-memory, if the package contains a C<new>, C<with>,
C<meta>, or C<import> routine it will be recognized as having been loaded.

=signature load

load() : Str

=example-1 load

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('c_p_a_n');

  $space->load

  # CPAN

=cut

=method methods

The methods method searches the package namespace for methods and returns their
names.

=signature methods

methods() : ArrayRef

=example-1 methods

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

=cut

=method name

The name method returns the fully-qualified package name.

=signature name

name() : Str

=example-1 name

  # given: synopsis

  $space->name

  # Foo::Bar

=cut

=method parent

The parent method returns a new L<Data::Object::Space> object for the parent
package namespace.

=signature parent

parent() : Object

=example-1 parent

  # given: synopsis

  $space->parent;

  # $space->package;

  # Foo

=cut

=method parse

The parse method parses the string argument and returns an arrayref of package
namespace segments (parts).

=signature parse

parse() : ArrayRef

=example-1 parse

  my $space = Data::Object::Space->new('Foo::Bar');

  $space->parse;

  # ['Foo', 'Bar']

=example-2 parse

  my $space = Data::Object::Space->new('Foo/Bar');

  $space->parse;

  # ['Foo', 'Bar']

=example-3 parse

  my $space = Data::Object::Space->new('Foo\Bar');

  $space->parse;

  # ['Foo', 'Bar']

=example-4 parse

  my $space = Data::Object::Space->new('foo-bar');

  $space->parse;

  # ['FooBar']

=example-5 parse

  my $space = Data::Object::Space->new('foo_bar');

  $space->parse;

  # ['FooBar']

=cut

=method parts

The parts method returns an arrayref of package namespace segments (parts).

=signature parts

parts() : ArrayRef

=example-1 parts

  my $space = Data::Object::Space->new('foo');

  $space->parts;

  # ['Foo']

=example-2 parts

  my $space = Data::Object::Space->new('foo/bar');

  $space->parts;

  # ['Foo', 'Bar']

=example-3 parts

  my $space = Data::Object::Space->new('foo_bar');

  $space->parts;

  # ['FooBar']

=cut

=method prepend

The prepend method modifies the object by prepending to the package namespace
parts.

=signature prepend

prepend(Str @args) : Object

=example-1 prepend

  # given: synopsis

  $space->prepend('etc');

  # 'Etc/Foo/Bar'

=example-2 prepend

  # given: synopsis

  $space->prepend('etc', 'tmp');

  # 'Etc/Tmp/Foo/Bar'

=cut

=method root

The root method returns the root package namespace segments (parts). Sometimes
separating the C<root> from the C<parts> helps identify how subsequent child
objects were derived.

=signature root

root() : Str

=example-1 root

  # given: synopsis

  $space->root

  # Foo

=cut

=method routine

The routine method returns the subroutine reference for the given subroutine
name.

=signature routine

routine(Str $arg1) : CodeRef

=example-1 routine

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

=cut

=method routines

The routines method searches the package namespace for routines and returns
their names.

=signature routines

routines() : ArrayRef

=example-1 routines

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

=cut

=method scalar

The scalar method returns the value for the given package scalar variable name.

=signature scalar

scalar(Str $arg1) : Any

=example-1 scalar

  # given: synopsis

  package Foo::Bar;

  our $root = '/path/to/file';

  package main;

  $space->scalar('root')

  # /path/to/file

=cut

=method scalars

The scalars method searches the package namespace for scalars and returns their
names.

=signature scalars

scalars() : ArrayRef

=example-1 scalars

  # given: synopsis

  package Foo::Bar;

  our $root = 'root';
  our $base = 'path/to';
  our $file = 'file';

  package main;

  $space->scalars

  # ['root', 'base', 'file']

=cut

=method sibling

The sibling method returns a new L<Data::Object::Space> object for the sibling
package namespace.

=signature sibling

sibling(Str $arg1) : Object

=example-1 sibling

  # given: synopsis

  $space->sibling('baz')

  # Foo::Baz

=cut

=method siblings

The siblings method searches C<%INC> and C<@INC> and retuns a list of
L<Data::Object::Space> objects for each sibling namespace found (one level
deep).

=signature siblings

siblings() : ArrayRef[Object]

=example-1 siblings

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('encode/m_i_m_e');

  $space->siblings

  # [
  #   'Encode/Alias',
  #   'Encode/Config'
  #   ...
  # ]

=cut

=method used

The used method searches C<%INC> for the package namespace and if found returns
the filepath and complete filepath for the loaded package, otherwise returns
falsy with an empty string.

=signature used

used() : Str

=example-1 used

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/xyz');

  $space->used

  # ''

=example-2 used

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('c_p_a_n');

  $space->load;
  $space->used

  # 'CPAN'

=example-3 used

  package Foo::Bar;

  sub import;

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/bar');

  $space->used

  # 'Foo/Bar'

=cut

=method variables

The variables method searches the package namespace for variables and returns
their names.

=signature variables

variables() : ArrayRef[Tuple[Str, ArrayRef]]

=example-1 variables

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

=cut

=method version

The version method returns the C<VERSION> declared on the target package, if
any.

=signature version

version() : Maybe[Str]

=example-1 version

  package Foo::Boo;

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/boo');

  $space->version

  # undef

=example-2 version

  package Foo::Boo;

  our $VERSION = 0.01;

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/boo');

  $space->version

  # '0.01'

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'append', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $$result, 'Foo/Bar/Baz';

  $result
});

$subs->example(-2, 'append', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $$result, 'Foo/Bar/Baz/Bax';

  $result
});

$subs->example(-1, 'array', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['start'];

  $result
});

$subs->example(-1, 'arrays', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['handler', 'initial'];

  $result
});

$subs->example(-1, 'base', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'Bar';

  $result
});

$subs->example(-1, 'bless', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Foo::Bar');

  $result
});

$subs->example(-2, 'bless', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Foo::Bar');
  is_deeply $result, {okay => 1};

  $result
});

$subs->example(-1, 'build', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Foo::Bar::Baz');

  $result
});

$subs->example(-2, 'build', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Foo::Bar::Bax');
  is_deeply $result, {okay => 1};

  $result
});

$subs->example(-1, 'call', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'started';

  $result
});

$subs->example(-1, 'child', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $$result, 'Foo/Bar/Baz';

  $result
});

$subs->example(-1, 'children', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok @$result > 1;
  ok $_->isa('Data::Object::Space') for @$result;

  $result
});

$subs->example(-1, 'cop', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok ref $result, 'CODE';

  my $returned = $result->(1..4);
  ok $returned->[0]->isa('Foo::Bar');
  is $returned->[1], 1;
  is $returned->[2], 2;
  is $returned->[3], 3;
  is $returned->[4], 4;

  $result
});

$subs->example(-1, 'functions', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['start'];

  $result
});

$subs->example(-1, 'hash', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {active => 1};

  $result
});

$subs->example(-1, 'hashes', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['defaults', 'settings'];

  $result
});

$subs->example(-1, 'id', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'Foo_Bar';

  $result
});

$subs->example(-1, 'inherits', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

$subs->example(-2, 'inherits', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['Foo'];

  $result
});

$subs->example(-1, 'load', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'CPAN';

  $result
});

$subs->example(-1, 'methods', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['start'];

  $result
});

$subs->example(-1, 'name', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'Foo::Bar';

  $result
});

$subs->example(-1, 'parent', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $$result, 'Foo';

  $result
});

$subs->example(-1, 'parse', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['Foo', 'Bar'];

  $result
});

$subs->example(-2, 'parse', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['Foo', 'Bar'];

  $result
});

$subs->example(-3, 'parse', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['Foo', 'Bar'];

  $result
});

$subs->example(-4, 'parse', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['FooBar'];

  $result
});

$subs->example(-5, 'parse', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['FooBar'];

  $result
});

$subs->example(-1, 'parts', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['Foo'];

  $result
});

$subs->example(-2, 'parts', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['Foo', 'Bar'];

  $result
});

$subs->example(-3, 'parts', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['FooBar'];

  $result
});

$subs->example(-1, 'prepend', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $$result, 'Etc/Foo/Bar';

  $result
});

$subs->example(-2, 'prepend', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $$result, 'Etc/Tmp/Foo/Bar';

  $result
});

$subs->example(-1, 'root', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'Foo';

  $result
});

$subs->example(-1, 'routine', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result->('begin'), ['begin'];

  $result
});

$subs->example(-1, 'routines', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply [sort @$result], ['abort', 'start'];

  $result
});

$subs->example(-1, 'scalar', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  $result = '/path/to/file';

  $result
});

$subs->example(-1, 'scalars', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['base', 'file', 'root'];

  $result
});

$subs->example(-1, 'sibling', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $$result, 'Foo/Baz';

  $result
});

$subs->example(-1, 'siblings', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok @$result > 1;
  ok $_->isa('Data::Object::Space') for @$result;

  $result
});

$subs->example(-1, 'used', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'used', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'CPAN';

  $result
});

$subs->example(-3, 'used', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'Foo/Bar';

  $result
});

$subs->example(-1, 'variables', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my $arrays = ['arrays', ['does']];
  my $hashes = ['hashes', ['sets']];
  my $scalars = ['scalars', ['func', 'init']];

  is_deeply $result, [$arrays, $hashes, $scalars];

  $result
});

$subs->example(-1, 'version', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, undef;

  $result
});

$subs->example(-2, 'version', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, '0.01';

  $result
});

ok 1 and done_testing;
