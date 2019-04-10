package Data::Object::Space;

use Carp;

use Data::Object::Class;

our $VERSION = '0.96'; # VERSION

# BUILD

sub BUILD {
  my ($self, $data) = @_;

  my @attrs = qw(root parts type);

  for my $attr (grep { defined $data->{$_} } @attrs) {
    $self->{$attr} = $data->{$attr};
  }

  if (defined $data->{root}) {
    $self->{root} = $self->parse($data->{root});
  } else {
    $self->{root} = [];
  }

  if (defined $data->{parts}) {
    $self->{parts} = $self->parse($data->{parts});
  } else {
    $self->{parts} = [];
  }

  if (defined $self->{parts}->[-1]) {
    ($self->{parts}->[-1], $self->{type}) = split /\./, $self->{parts}->[-1];
  }

  unless (defined $self->{type}) {
    $self->{type} = $data->{type} || 'pm';
  }

  return $self;
}

sub BUILDARGS {
  my ($class, @args) = @_;

  return { @args < 2 ? ('parts', $args[0]) : @args };
}

# METHODS

sub id {
  my ($self) = @_;

  return join '_', split /::/, $self->name;
}

sub parse {
  my ($self, $space) = @_;

  if (! defined $space || ref $space) {
    return $space;
  }
  return [
    map ucfirst,
    map join('', map(ucfirst, split /[-_]/)),
    split /[^-_a-zA-Z0-9.]+/, $space
  ];
}

sub call {
  my ($self, $func, @args) = @_;

  my $class = $self->load;

  unless ($func) {
    croak(qq(Attempt to call undefined object method in package "$class"));
  }

  my $next = $class->can($func);

  unless ($next) {
    croak(qq(Can't locate object method "$func" via package "$class"));
  }

  @_ = @args; goto $next;
}

sub cop {
  my ($self, $func, @args) = @_;

  my $class = $self->load;

  unless ($func) {
    croak(qq(Attempt to cop undefined object method from package "$class"));
  }

  my $next = $class->can($func);

  unless ($next) {
    croak(qq(Can't locate object method "$func" via package "$class"));
  }

  my $code = sub { $next->(@args ? (@args, @_) : @_) };

  return $code;
}

sub bless {
  my ($self, $data) = @_;

  my $class = $self->load;

  return CORE::bless($data // {}, $self->name);
}

sub build {
  my ($self, @args) = @_;

  my $class = $self->load;

  return $self->call('new', $class, @args);
}

sub child {
  my ($self, @args) = @_;

  my (@root, @parts);

  if (defined $self->root) {
    @root = @{$self->root};
  }
  if (defined $self->parts) {
    @parts = @{$self->parts};
  }

  my $space = join '/', @args;
  my $class = ref $self || $self;

  my $type = $self->type;

  return $class->new(root => [@root, @parts], parts => $space, type => $type);
}

sub load {
  my ($self) = @_;

  my $class = $self->name;

  return $class if $self->{loaded};

  my $failed = !$class || $class !~ /^\w(?:[\w:']*\w)?$/;
  my $loaded;

  my $error = do {
    local $@;
    no strict 'refs';
    $loaded = !!$class->can('new');
    $loaded = !!$class->can('with') if !$loaded;
    $loaded = !!$class->can('import') if !$loaded;
    $loaded = eval "require $class; 1" if !$loaded;
    $@;
  };

  croak "Error attempting to load $class: $error"
    if $error
    or $failed
    or not $loaded;

  $self->{loaded} = 1;

  return $class;
}

sub used {
  my ($self) = @_;

  my $regexp = quotemeta $self->file;

  for my $item (keys %INC) {
    return [$item, $INC{$item}] if $item =~ /$regexp$/;
  }

  return undef;
}

sub parts {
  my ($self) = @_;

  return $self->{parts};
}

sub parent {
  my ($self) = @_;

  my (@root, @parts);

  if (defined $self->root) {
    @root = @{$self->root};
  }
  if (defined $self->parts) {
    @parts = @{$self->parts};
  }

  pop @parts if @parts > 1 || @root;

  push @parts, shift @root if !@parts;

  my $type = $self->type;

  my $class = ref $self || $self;

  return $class->new(root => \@root, parts => \@parts, type => $type);
}

sub sibling {
  my ($self, @args) = @_;

  my $space = join '/', @args;

  my $parts = $self->parse($space);

  my $sibling = $self->parent;

  push @{$sibling->{parts}}, @{$parts} if $parts;

  return $sibling;
}

sub append {
  my ($self, @args) = @_;

  my $space = join '/', @args;

  my $parts = $self->parse($space);

  push @{$self->{parts}}, @{$parts} if $parts;

  return $self;
}

sub prepend {
  my ($self, @args) = @_;

  my $space = join '/', @args;

  my $parts = $self->parse($space);

  unshift @{$self->{parts}}, @{$parts} if $parts;

  return $self;
}

sub base {
  my ($self) = @_;

  return $self->parts->[-1];
}

sub children {
  my ($self) = @_;

  my %list;
  my $path;
  my $type;

  $path = quotemeta $self->path;
  $type = quotemeta $self->type;

  my $regexp = qr/$path\/[^\/]+\.$type/;

  for my $item (keys %INC) {
    $list{$item}++ if $item =~ /$regexp$/;
  }

  my %seen;

  $path = $self->path;
  $type = $self->type;

  my $expand = join('.', join('/', $path, '*'), $type);

  for my $dir (@INC) {
    next if $seen{$dir}++;

    my $re = quotemeta $dir;

    map { s/^$re\///; $list{$_}++ } grep !$list{$_}, glob "$dir/$expand";
  }

  my $class = ref $self || $self;

  return [map $class->new($_), sort keys %list];
}

sub siblings {
  my ($self) = @_;

  my %list;
  my $path;
  my $type;

  my $parent = $self->parent;

  $path = quotemeta $parent->path;
  $type = quotemeta $parent->type;

  my $regexp = qr/$path\/[^\/]+\.$type/;

  for my $item (keys %INC) {
    $list{$item}++ if $item =~ /$regexp$/;
  }

  my %seen;

  $path = $parent->path;
  $type = $parent->type;

  my $expand = join('.', join('/', $path, '*'), $type);

  for my $dir (@INC) {
    next if $seen{$dir}++;

    my $re = quotemeta $dir;

    map { s/^$re\///; $list{$_}++ } grep !$list{$_}, glob "$dir/$expand";
  }

  my $class = ref $self || $self;

  return [map $class->new($_), sort keys %list];
}

sub name {
  my ($self) = @_;

  my (@root, @parts);

  if (defined $self->root) {
    @root = @{$self->root};
  }
  if (defined $self->parts) {
    @parts = @{$self->parts};
  }

  return join '::', @root, @parts;
}

sub root {
  my ($self) = @_;

  return $self->{root};
}

sub path {
  my ($self, $form, @args) = @_;

  my (@root, @parts, $type);

  if (defined $self->root) {
    @root = @{$self->root};
  }
  if (defined $self->parts) {
    @parts = @{$self->parts};
  }

  $form = '%s' if !defined $form;

  return sprintf $form, join('/', @root, @parts), @args;
}

sub file {
  my ($self, $form, @args) = @_;

  $form = '%s' if !defined $form;

  return sprintf $form, join('.', $self->path, $self->type), @args;
}

sub type {
  my ($self) = @_;

  return $self->{type};
}

sub variables {
  my ($self) = @_;

  my %seen;

  map $seen{$_}++, map @{$self->$_}, qw(
    scalars
    arrays
    hashes
  );

  return [sort keys %seen];
}

sub scalar {
  my ($self, $name) = @_;

  no strict 'refs';

  my $class = $self->name;

  return ${"${class}::${name}"};
}

sub scalars {
  my ($self) = @_;

  no strict 'refs';

  my $class = $self->name;

  my $scalars = [
    sort grep !!${"${class}::$_"},
    grep /^[_a-zA-Z]/, keys %{"${class}::"}
  ];

  return $scalars;
}

sub array {
  my ($self, $name) = @_;

  no strict 'refs';

  my $class = $self->name;

  return (@{"${class}::${name}"});
}

sub arrays {
  my ($self) = @_;

  no strict 'refs';

  my $class = $self->name;

  my $arrays = [
    sort grep !!@{"${class}::$_"},
    grep /^[_a-zA-Z]/, keys %{"${class}::"}
  ];

  return $arrays;
}

sub hash {
  my ($self, $name) = @_;

  no strict 'refs';

  my $class = $self->name;

  return (%{"${class}::${name}"});
}

sub hashes {
  my ($self) = @_;

  no strict 'refs';

  my $class = $self->name;

  my $hashes = [
    sort grep !!%{"${class}::$_"},
    grep /^[_a-zA-Z]/, keys %{"${class}::"}
  ];

  return $hashes;
}

sub routine {
  my ($self, $name) = @_;

  no strict 'refs';

  my $class = $self->name;

  return *{"${class}::${name}"}{"CODE"};
}

sub routines {
  my ($self) = @_;

  no strict 'refs';

  my $class = $self->name;

  my $routines = [
    sort grep *{"${class}::$_"}{"CODE"},
    grep /^[_a-zA-Z]/, keys %{"${class}::"}
  ];

  return $routines;
}

sub methods {
  my ($self) = @_;

  my @methods;

  no strict 'refs';

  require Function::Parameters::Info;

  for my $routine (@{$self->routines}) {
    my $code = $self->can($routine) or next;
    my $data = Function::Parameters::info($code);

    push @methods, $routine if $data && $data->invocant;
  }

  return [sort @methods];
}

sub functions {
  my ($self) = @_;

  my @functions;

  no strict 'refs';

  require Function::Parameters::Info;

  for my $routine (@{$self->routines}) {
    my $code = $self->can($routine) or next;
    my $data = Function::Parameters::info($code);

    push @functions, $routine if $data && !$data->invocant;
  }

  return [sort @functions];
}

1;

=encoding utf8

=head1 NAME

Data::Object::Space

=cut

=head1 ABSTRACT

Data-Object Space Class

=cut

=head1 SYNOPSIS

  use Data::Object::Space;

  my $space = Data::Object::Space->new('data/object');

  "$space"
  # Data::Object

  $space->name;
  # Data::Object

  $space->path;
  # Data/Object

  $space->file;
  # Data/Object.pm

  $space->children;
  # ['Data/Object/Array.pm', ...]

  $space->siblings;
  # ['Data/Dumper.pm', ...]

  $space->load;
  # Data::Object

=cut

=head1 DESCRIPTION

Data::Object::Space provides methods for parsing and manipulating package
namespaces.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 append

  append(Str $arg1) : Object

The append method modifies the object by appending to the package namespace
parts.

=over 4

=item append example

  # given $space (Foo::Bar)

  $space->append('baz');

  "$space"

  # Foo::Bar::Baz

=back

=cut

=head2 array

  array(Str $arg1) : Any

The array method returns the value for the given package array variable name.

=over 4

=item array example

  # given Foo/Bar

  $space->array('EXPORT');

  # (,...)

=back

=cut

=head2 arrays

  arrays() : ArrayRef

The arrays method searches the package namespace for arrays and returns
their names.

=over 4

=item arrays example

  # given Foo/Bar

  $space->arrays();

  # [,...]

=back

=cut

=head2 base

  base() : Str

The base method returns the last segment of the package namespace parts.

=over 4

=item base example

  # given $space (Foo::Bar)

  $space->base();

  # Bar

=back

=cut

=head2 bless

  bless(Any $arg1 = {}) : Object

The bless method blesses the given value into the package namespace and returns
an object. If no value is given, an empty hashref is used.

=over 4

=item bless example

  # given $space (Foo::Bar)

  $space->bless();

  # bless({}, 'Foo::Bar')

=back

=cut

=head2 build

  build(Any @args) : Object

The build method attempts to call C<new> on the package namespace and if
successful returns the resulting object.

=over 4

=item build example

  # given $space (Foo::Bar)

  $space->build(@args);

  # bless(..., 'Foo::Bar')

=back

=cut

=head2 call

  call(Any @args) : Any

The call method attempts to call the given subroutine on the package namespace and if
successful returns the resulting value.

=over 4

=item call example

  # given $space (Foo::Bar)

  $space->call(@args);

  # ...

=back

=cut

=head2 child

  child(Str $arg1) : Object

The child method returns a new L<Data::Object::Space> object for the child
package namespace.

=over 4

=item child example

  # given $space (Foo::Bar)

  $space->child('baz');

  # Foo::Bar::Baz

=back

=cut

=head2 children

  children() : ArrayRef

The children method searches C<%INC> and C<@INC> and retuns a list of
L<Data::Object::Space> objects for each child namespace found (one level deep).

=over 4

=item children example

  # given $space (Foo::Bar)

  $space->children();

  # ['Foo::Bar::Baz', ...]

=back

=cut

=head2 cop

  cop(Any @args) : CodeRef

The cop method attempts to curry the given subroutine on the package namespace and if
successful returns a closure.

=over 4

=item cop example

  # given $space (Foo::Bar)

  $space->cop(@args);

  # ...

=back

=cut

=head2 file

  file(Str $arg1 = '%s') : Str

The file method returns a file string for the package namespace. This method
optionally takes a format string.

=over 4

=item file example

  # given $space (Foo::Bar)

  $space->file();

  # Foo/Bar.pm

  $space->file('lib/%s');

  # lib/Foo/Bar.pm

=back

=cut

=head2 functions

  functions() : ArrayRef

The functions method searches the package namespace for functions and returns
their names.

=over 4

=item functions example

  # given Foo/Bar

  $space->functions();

  # [,...]

=back

=cut

=head2 hash

  hash(Str $arg1) : Any

The hashes method returns the value for the given package hash variable name.

=over 4

=item hash example

  # given Foo/Bar

  $space->hash('EXPORT_TAGS');

  # (,...)

=back

=cut

=head2 hashes

  hashes() : ArrayRef

The hashes method searches the package namespace for hashes and returns
their names.

=over 4

=item hashes example

  # given Foo/Bar

  $space->hashes();

  # [,...]

=back

=cut

=head2 id

  id() : Str

The id method returns the fully-qualified package name as a label.

=over 4

=item id example

  # given $space (Foo::Bar)

  $space->id;

  # Foo_Bar

=back

=cut

=head2 load

  load() : Str

The load method check whether the package namespace is already loaded and if
not attempts to load the package. If the package is not loaded and is not
loadable, this method will throw an exception using C<croak>. If the package is
loadable, this method returns truthy with the package name.

=over 4

=item load example

  # given $space (Foo::Bar)

  $space->load();

  # throws exception, unless Foo::Bar is loadable

=back

=cut

=head2 methods

  methods() : ArrayRef

The methods method searches the package namespace for methods and returns
their names.

=over 4

=item methods example

  # given Foo/Bar

  $space->methods();

  # [,...]

=back

=cut

=head2 name

  name() : Str

The name method returns the fully-qualified package name.

=over 4

=item name example

  # given $space (Foo::Bar)

  $space->name;

  # Foo::Bar

=back

=cut

=head2 parent

  parent() : Str

The parent method returns a new L<Data::Object::Space> object for the parent
package namespace.

=over 4

=item parent example

  # given $space (Foo::Bar)

  $space->parent();

  # Foo

=back

=cut

=head2 parse

  parse(Str $arg1) : ArrayRef

The parse method parses the string argument and returns an arrayref of package
namespace segments (parts) suitable for object construction.

=over 4

=item parse example

  # given Foo::Bar

  $space->parse('Foo::Bar');

  # ['Foo', 'Bar']

  $space->parse('Foo/Bar');

  # ['Foo', 'Bar']

  $space->parse('Foo\Bar');

  # ['Foo', 'Bar']

  $space->parse('foo-bar');

  # ['FooBar']

  $space->parse('foo_bar');

  # ['FooBar']

=back

=cut

=head2 parts

  parts() : ArrayRef

The parts method returns an arrayref of package namespace segments (parts).

=over 4

=item parts example

  # given $space (Foo::Bar)

  $space->parts();

  # ['Foo', 'Bar']

=back

=cut

=head2 path

  path(Str $arg1) : Str

The path method returns a path string for the package namespace. This method
optionally takes a format string.

=over 4

=item path example

  # given $space (Foo::Bar)

  $space->path();

  # Foo/Bar

  $space->path('lib/%s');

  # lib/Foo/Bar

=back

=cut

=head2 prepend

  prepend(Str $arg1) : Object

The prepend method modifies the object by prepending to the package namespace
parts.

=over 4

=item prepend example

  # given $space (Foo::Bar)

  $space->prepend('via');

  "$space"

  # Via::Foo::Bar

=back

=cut

=head2 root

  root() : Str

The root method returns the root package namespace segments (parts). Sometimes
separating the C<root> from the C<parts> helps identify how subsequent child
objects were derived.

=over 4

=item root example

  # given $space (root => 'Foo', parts => 'Bar')

  $space->root();

  # ['Foo']

=back

=cut

=head2 routine

  routine(Str $arg1) : CodeRef

The routine method returns the subroutine reference for the given subroutine
name.

=over 4

=item routine example

  # given Foo/Bar

  $space->routine('import');

  # ...

=back

=cut

=head2 routines

  routines() : ArrayRef

The routines method searches the package namespace for routines and returns
their names.

=over 4

=item routines example

  # given Foo/Bar

  $space->routines();

  # [,...]

=back

=cut

=head2 scalar

  scalar(Str $arg1) : Any

The scalar method returns the value for the given package scalar variable name.

=over 4

=item scalar example

  # given Foo/Bar

  $space->scalar('VERSION');

  # 0.01

=back

=cut

=head2 scalars

  scalars() : ArrayRef

The scalars method searches the package namespace for scalars and returns
their names.

=over 4

=item scalars example

  # given Foo/Bar

  $space->scalars();

  # [,...]

=back

=cut

=head2 sibling

  sibling(Str $arg1) : Object

The sibling method returns a new L<Data::Object::Space> object for the sibling
package namespace.

=over 4

=item sibling example

  # given $space (Foo::Bar)

  $space->sibling('Baz');

  # Foo::Baz

=back

=cut

=head2 siblings

  siblings() : ArrayRef

The siblings method searches C<%INC> and C<@INC> and retuns a list of
L<Data::Object::Space> objects for each sibling namespace found (one level deep).

=over 4

=item siblings example

  # given $space (Foo::Bar)

  $space->siblings();

  # ['Foo::Baz', ...]

=back

=cut

=head2 type

  type() : Str

The type method returns the parsed filetype and defaults to C<pm>. This value
is used when calling the C<file> method.

=over 4

=item type example

  # given $space (Foo/Bar.pod)

  $space->type();

  # pod

=back

=cut

=head2 used

  used() : ArrayRef | Undef

The used method searches C<%INC> for the package namespace and if found returns
the filepath and complete filepath for the loaded package, otherwise returns
undef.

=over 4

=item used example

  # given $space (Foo::Bar)

  $space->used();

  # undef, unless Foo::Bar is in %INC

=back

=cut

=head2 variables

  variables() : ArrayRef

The variables method searches the package namespace for variables and returns
their names.

=over 4

=item variables example

  # given Foo/Bar

  $space->variables();

  # [,...]

=back

=cut
