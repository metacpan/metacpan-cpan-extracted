package Data::Object::Space;

use 5.014;

use strict;
use warnings;
use routines;

use parent 'Data::Object::Name';

our $VERSION = '2.10'; # VERSION

# METHODS

my %has;

method all($name, @args) {
  my $result = [];

  my $class = $self->class;
  for my $package ($self->package, @{$self->inherits}) {
    push @$result, [$package, $class->new($package)->$name(@args)];
  }

  return $result;
}

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

method authority() {

  return $self->scalar('AUTHORITY');
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

    my $text = qq[Attempt to call undefined class method in package "$class"];

    Carp::confess $text;
  }

  my $next = $class->can($func);

  unless ($next) {
    if ($class->can('AUTOLOAD')) {
      $next = sub { no strict 'refs'; &{"${class}::${func}"}(@args) };
    }
  }

  unless ($next) {
    require Carp;

    my $text = qq[Unable to locate class method "$func" via package "$class"];

    Carp::confess $text;
  }

  @_ = @args; goto $next;
}

method chain(@steps) {
  my $result = $self;

  for my $step (@steps) {
    my ($name, @args) = (ref($step) eq 'ARRAY') ? @$step : ($step);

    $result = $result->$name(@args);
  }

  return $result;
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

method data() {
  no strict 'refs';

  my $class = $self->package;

  local $.;

  my $handle = \*{"${class}::DATA"};

  return '' if !fileno $handle;

  seek $handle, 0, 0;

  my $data = join '', <$handle>;

  $data =~ s/^.*\n__DATA__\r?\n/\n/s;
  $data =~ s/\n__END__\r?\n.*$/\n/s;

  return $data;
}

method destroy() {
  require Symbol;

  Symbol::delete_package($self->package);

  my $c_re = quotemeta $self->package;
  my $p_re = quotemeta $self->path;

  map {delete $has{$_}} grep /^$c_re/, keys %has;
  map {delete $INC{$_}} grep /^$p_re/, keys %INC;

  return $self;
}

method eval(@args) {
  local $@;

  my $result = eval join ' ', map "$_", "package @{[$self->package]};", @args;

  Carp::confess $@ if $@;

  return $result;
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

method init() {
  my $class = $self->package;

  if ($self->routine('import')) {

    return $class;
  }

  $class = $self->locate ? $self->load : $self->package;

  if ($self->routine('import')) {

    return $class;
  }
  else {

    my $import = sub { $class };

    $self->inject('import', $import);
    $self->load;

    return $class;
  }
}

method inherits() {

  return $self->array('ISA');
}

method included() {

  return $INC{$self->format('path', '%s.pm')};
}

method inject($name, $coderef) {
  my $class = $self->package;

  local $@;
  no strict 'refs';
  no warnings 'redefine';

  if (state $subutil = eval "require Sub::Util") {
    return *{"${class}::${name}"} = Sub::Util::set_subname(
      "${class}::${name}", $coderef || sub{$class}
    );
  }
  else {
    return *{"${class}::${name}"} = $coderef || sub{$class};
  }
}

method load() {
  my $class = $self->package;

  return $class if $has{$class};

  if ($class eq "main") {
    return do { $has{$class} = 1; $class };
  }

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

  $has{$class} = 1;

  return $class;
}

method loaded() {
  my $class = $self->package;
  my $pexpr = $self->format('path', '%s.pm');

  my $is_loaded_eval = $has{$class};
  my $is_loaded_used = $INC{$pexpr};

  return ($is_loaded_eval || $is_loaded_used) ? 1 : 0;
}

method locate() {
  my $found = '';

  my $file = $self->format('path', '%s.pm');

  for my $path (@INC) {
    do { $found = "$path/$file"; last } if -f "$path/$file";
  }

  return $found;
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

method rebase(@args) {
  my $class = $self->class;

  my $path = join '/', map $class->new($_)->path, @args;

  return $class->new($self->base)->prepend($path);
}

method reload() {
  my $class = $self->package;

  delete $has{$class};

  my $path = $self->format('path', '%s.pm');

  delete $INC{$path};

  no strict 'refs';

  @{"${class}::ISA"} = ();

  return $self->load;
}

method require($target) {
  $target = "'$target'" if -f $target;

  return $self->eval("require $target");
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

method tryload() {

  return do { local $@; eval { $self->load }; int!$@ };
}

method use($target, @params) {
  my $version;

  my $class = $self->package;

  ($target, $version) = @$target if ref $target eq 'ARRAY';

  $self->require($target);

  require Scalar::Util;

  my @statement = (
    'no strict "subs";',
    (
      Scalar::Util::looks_like_number($version)
        ? "${target}->VERSION($version);" : ()
    ),
    'sub{ my ($target, @params) = @_; $target->import(@params)}'
  );

  $self->eval(join("\n", @statement))->($target, $class, @params);

  return $self;
}

method used() {
  my $class = $self->package;
  my $path = $self->path;
  my $regexp = quotemeta $path;

  return $path if $has{$class};

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

Data::Object::Space - Namespace Class

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

=head2 all

  all(Str $name, Any @args) : ArrayRef[Tuple[Str, Any]]

The all method executes any available method on the instance and all instances
representing packages inherited by the package represented by the invocant.

=over 4

=item all example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/object/space');

  $space->all('id');

  # [
  #   ['Data::Object::Space', 'Data_Object_Space'],
  #   ['Data::Object::Name', 'Data_Object_Name'],
  # ]

=back

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

=head2 authority

  authority() : Maybe[Str]

The authority method returns the C<AUTHORITY> declared on the target package,
if any.

=over 4

=item authority example #1

  package Foo::Boo;

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/boo');

  $space->authority

  # undef

=back

=over 4

=item authority example #2

  package Foo::Boo;

  our $AUTHORITY = 'cpan:AWNCORP';

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/boo');

  $space->authority

  # 'cpan:AWNCORP'

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

=over 4

=item call example #2

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

=back

=cut

=head2 chain

  chain(Str | Tuple[Str, Any] @steps) : Any

The chain method chains one or more method calls and returns the result.

=over 4

=item chain example #1

  package Chu::Chu0;

  sub import;

  package main;

  my $space = Data::Object::Space->new('Chu::Chu0');

  $space->chain('bless');

=back

=over 4

=item chain example #2

  package Chu::Chu1;

  sub import;

  sub new {
    bless pop;
  }

  sub frame {
    [@_]
  }

  package main;

  my $space = Data::Object::Space->new('Chu::Chu1');

  $space->chain(['bless', {1..4}], 'frame');

  # [ bless( { '1' => 2, '3' => 4 }, 'Chu::Chu1' ) ]

=back

=over 4

=item chain example #3

  package Chu::Chu2;

  sub import;

  sub new {
    bless pop;
  }

  sub frame {
    [@_]
  }

  package main;

  my $space = Data::Object::Space->new('Chu::Chu2');

  $space->chain('bless', ['frame', {1..4}]);

  # [ bless( {}, 'Chu::Chu2' ), { '1' => 2, '3' => 4 } ]

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

=head2 data

  data() : Str

The data method attempts to read and return any content stored in the C<DATA>
section of the package namespace.

=over 4

=item data example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo');

  $space->data; # ''

=back

=cut

=head2 destroy

  destroy() : Object

The destroy method attempts to wipe out a namespace and also remove it and its
children from C<%INC>. B<NOTE:> This can cause catastrophic failures if used
incorrectly.

=over 4

=item destroy example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/dumper');

  $space->load; # Data/Dumper

  $space->destroy;

=back

=cut

=head2 eval

  eval(Str @args) : Any

The eval method takes a list of strings and evaluates them under the namespace
represented by the instance.

=over 4

=item eval example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo');

  $space->eval('our $VERSION = 0.01');

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

=head2 included

  included() : Str

The included method returns the path of the namespace if it exists in C<%INC>.

=over 4

=item included example #1

  package main;

  my $space = Data::Object::Space->new('Data/Object/Space');

  $space->included;

  # lib/Data/Object/Space.pm

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

=head2 init

  init() : Str

The init method ensures that the package namespace is loaded and, whether
created in-memory or on-disk, is flagged as being loaded and loadable.

=over 4

=item init example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('kit');

  $space->init

  # Kit

=back

=cut

=head2 inject

  inject(Str $name, Maybe[CodeRef] $coderef) : Any

The inject method monkey-patches the package namespace, installing a named
subroutine into the package which can then be called normally, returning the
fully-qualified subroutine name.

=over 4

=item inject example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('kit');

  $space->inject('build', sub { 'finished' });

  # *Kit::build

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

=head2 loaded

  loaded() : Int

The loaded method checks whether the package namespace is already loaded
returns truthy or falsy.

=over 4

=item loaded example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/dumper');

  $space->loaded;

  # 0

=back

=over 4

=item loaded example #2

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/dumper');

  $space->load;

  $space->loaded;

  # 1

=back

=cut

=head2 locate

  locate() : Str

The locate method checks whether the package namespace is available in
C<@INC>, i.e. on disk. This method returns the file if found or an empty
string.

=over 4

=item locate example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('brianne_spinka');

  $space->locate;

  # ''

=back

=over 4

=item locate example #2

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/dumper');

  $space->locate;

  # /path/to/Data/Dumper.pm

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

=head2 rebase

  rebase(Str @args) : Object

The rebase method returns an object by prepending the package namespace
specified to the base of the current object's namespace.

=over 4

=item rebase example #1

  # given: synopsis

  $space->rebase('zoo');

  # Zoo/Bar

=back

=cut

=head2 reload

  reload() : Str

The reload method attempts to delete and reload the package namespace using the
L</load> method. B<Note:> Reloading is additive and will overwrite existing
symbols but does not remove symbols.

=over 4

=item reload example #1

  package main;

  use Data::Object::Space;

  # Foo::Gen is generate with $VERSION as 0.01

  my $space = Data::Object::Space->new('foo/gen');

  $space->reload;

  # Foo::Gen
  # Foo::Gen->VERSION is 0.01

=back

=over 4

=item reload example #2

  package main;

  use Data::Object::Space;

  # Foo::Gen is regenerated with $VERSION as 0.02

  my $space = Data::Object::Space->new('foo/gen');

  $space->reload;

  # Foo::Gen
  # Foo::Gen->VERSION is 0.02

=back

=cut

=head2 require

  require(Str $target) : Any

The require method executes a C<require> statement within the package namespace
specified.

=over 4

=item require example #1

  # given: synopsis

  $space->require('Moo');

  # 1

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

  $space->root;

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

=head2 tryload

  tryload() : Bool

The tryload method attempt to C<load> the represented package using the
L</load> method and returns truthy/falsy based on whether the package was
loaded.

=over 4

=item tryload example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('c_p_a_n');

  $space->tryload

  # 1

=back

=over 4

=item tryload example #2

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('brianne_spinka');

  $space->tryload

  # 0

=back

=cut

=head2 use

  use(Str | Tuple[Str, Str] $target, Any @params) : Object

The use method executes a C<use> statement within the package namespace
specified.

=over 4

=item use example #1

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/goo');

  $space->use('Moo');

  # $self

=back

=over 4

=item use example #2

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/hoo');

  $space->use('Moo', 'has');

  # $self

=back

=over 4

=item use example #3

  package main;

  use Data::Object::Space;

  my $space = Data::Object::Space->new('foo/ioo');

  $space->use(['Moo', 9.99], 'has');

  # $self

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
