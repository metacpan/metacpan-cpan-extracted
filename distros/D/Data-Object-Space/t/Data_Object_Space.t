use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Space

=cut

=tagline

Namespace Class

=cut

=abstract

Namespace Class for Perl 5

=cut

=includes

method: all
method: append
method: array
method: arrays
method: authority
method: base
method: bless
method: build
method: call
method: child
method: children
method: cop
method: data
method: destroy
method: eval
method: functions
method: hash
method: hashes
method: id
method: included
method: inherits
method: init
method: inject
method: load
method: loaded
method: locate
method: methods
method: name
method: parent
method: parse
method: parts
method: prepend
method: rebase
method: require
method: root
method: routine
method: routines
method: scalar
method: scalars
method: sibling
method: siblings
method: tryload
method: use
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

=method all

The all method executes any available method on the instance and all instances
representing packages inherited by the package represented by the invocant.

=signature all

all(Str $name, Any @args) : ArrayRef[Tuple[Str, Any]]

=example-1 all

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/object/space');

  $space->all('id');

  # [
  #   ['Data::Object::Space', 'Data_Object_Space'],
  #   ['Data::Object::Name', 'Data_Object_Name'],
  # ]

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

=method authority

The authority method returns the C<AUTHORITY> declared on the target package,
if any.

=signature authority

authority() : Maybe[Str]

=example-1 authority

  package Foo::Boo;

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/boo');

  $space->authority

  # undef

=example-2 authority

  package Foo::Boo;

  our $AUTHORITY = 'cpan:AWNCORP';

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/boo');

  $space->authority

  # 'cpan:AWNCORP'

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

=example-2 call

  # given: synopsis

  package Zoo;

  sub import;

  sub AUTOLOAD {
    bless {};
  }

  sub DESTROY {
    ; # noop
  }

  package main;

  use Data::Object::Space;

  $space = Data::Object::Space->new('zoo');

  $space->call('start')

  # bless({}, 'Zoo')

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

=method data

The data method attempts to read and return any content stored in the C<DATA>
section of the package namespace.

=signature data

data() : Str

=example-1 data

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo');

  $space->data; # ''

=cut

=method destroy

The destroy method attempts to wipe out a namespace and also remove it and its
children from C<%INC>. B<NOTE:> This can cause catastrophic failures if used
incorrectly.

=signature destroy

destroy() : Object

=example-1 destroy

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/dumper');

  $space->load; # Data/Dumper

  $space->destroy;

=cut

=method eval

The eval method takes a list of strings and evaluates them under the namespace
represented by the instance.

=signature eval

eval(Str @args) : Any

=example-1 eval

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo');

  $space->eval('our $VERSION = 0.01');

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

=method included

The included method returns the path of the namespace if it exists in C<%INC>.

=signature included

included() : Str

=example-1 included

  package main;

  my $space = Data::Object::Space->new('Data/Object/Space');

  $space->included;

  # lib/Data/Object/Space.pm

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

=method init

The init method ensures that the package namespace is loaded and, whether
created in-memory or on-disk, is flagged as being loaded and loadable.

=signature init

init() : Str

=example-1 init

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('kit');

  $space->init

  # Kit

=cut

=method inject

The inject method monkey-patches the package namespace, installing a named
subroutine into the package which can then be called normally, returning the
fully-qualified subroutine name.

=signature inject

inject(Str $name, Maybe[CodeRef] $coderef) : Any

=example-1 inject

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('kit');

  $space->inject('build', sub { 'finished' });

  # *Kit::build

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

=method loaded

The loaded method checks whether the package namespace is already loaded
returns truthy or falsy.

=signature loaded

loaded() : Int

=example-1 loaded

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/dumper');

  $space->loaded;

  # 0

=example-2 loaded

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/dumper');

  $space->load;

  $space->loaded;

  # 1

=cut

=method locate

The locate method checks whether the package namespace is available in
C<@INC>, i.e. on disk. This method returns the file if found or an empty
string.

=signature locate

locate() : Str

=example-1 locate

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('brianne_spinka');

  $space->locate;

  # ''

=example-2 locate

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/dumper');

  $space->locate;

  # /path/to/Data/Dumper.pm

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

=method rebase

The rebase method returns an object by prepending the package namespace
specified to the base of the current object's namespace.

=signature rebase

rebase(Str @args) : Object

=example-1 rebase

  # given: synopsis

  $space->rebase('zoo');

  # Zoo/Bar

=cut

=method require

The require method executes a C<require> statement within the package namespace
specified.

=signature require

require(Str $target) : Any

=example-1 require

  # given: synopsis

  $space->require('Moo');

  # 1

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

=method tryload

The tryload method attempt to C<load> the represented package using the
L</load> method and returns truthy/falsy based on whether the package was
loaded.

=signature tryload

tryload() : Bool

=example-1 tryload

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('c_p_a_n');

  $space->tryload

  # 1

=example-2 tryload

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('brianne_spinka');

  $space->tryload

  # 0

=cut

=method use

The use method executes a C<use> statement within the package namespace
specified.

=signature use

use(Str | Tuple[Str, Str] $target, Any @params) : Object

=example-1 use

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/goo');

  $space->use('Moo');

  # $self

=example-2 use

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/hoo');

  $space->use('Moo', 'has');

  # $self

=example-3 use

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/ioo');

  $space->use(['Moo', 9.99], 'has');

  # $self

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

$subs->example(-1, 'all', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [
    ['Data::Object::Space', 'Data_Object_Space'],
    ['Data::Object::Name', 'Data_Object_Name'],
  ];

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

$subs->example(-1, 'authority', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, undef;

  $result
});

$subs->example(-2, 'authority', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'cpan:AWNCORP';

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

$subs->example(-2, 'call', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zoo');

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

$subs->example(-1, 'data', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, '';

  $result
});

$subs->example(-1, 'destroy', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  ok !$result->used;
  ok !$result->included;
  ok !$result->loaded;

  $result
});

$subs->example(-1, 'eval', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 0.01;
  is "Foo"->VERSION, 0.01;

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

$subs->example(-1, 'included', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr(Data/Object/Space.pm);

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

$subs->example(-1, 'init', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'Kit';

  $result
});

$subs->example(-1, 'inject', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, '*Kit::build';

  my $package = 'Kit';
  is $package->build, 'finished';

  $result
});

$subs->example(-1, 'load', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'CPAN';

  $result
});

$subs->example(-1, 'loaded', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'loaded', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'locate', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok !length($result);

  $result
});

$subs->example(-2, 'locate', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok length($result);

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

$subs->example(-1, 'rebase', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $$result, 'Zoo/Bar';

  $result
});

$subs->example(-1, 'require', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

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

$subs->example(-1, 'tryload', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'tryload', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'use', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->package, 'Foo::Goo';
  ok $result->package->can('after');
  ok $result->package->can('before');
  ok $result->package->can('extends');
  ok $result->package->can('has');
  ok $result->package->can('with');

  $result
});

$subs->example(-2, 'use', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->package, 'Foo::Hoo';
  ok $result->package->can('after');
  ok $result->package->can('before');
  ok $result->package->can('extends');
  ok $result->package->can('has');
  ok $result->package->can('with');

  $result
});

$subs->example(-3, 'use', 'method', fun($tryable) {
  my $failed = 0;
  $tryable->default(fun($error) {
    $failed++;
    Data::Object::Space->new('foo/ioo');
  });
  ok my $result = $tryable->result;
  is $result->package, 'Foo::Ioo';
  ok $failed;
  ok !$result->package->can('after');
  ok !$result->package->can('before');
  ok !$result->package->can('extends');
  ok !$result->package->can('has');
  ok !$result->package->can('with');

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
