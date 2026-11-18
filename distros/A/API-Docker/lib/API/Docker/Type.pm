package API::Docker::Type;
# ABSTRACT: The DSL and attribute registry behind the generated Docker types
our $VERSION = '0.006';
our %REGISTRY;
use Moo ();
use Moo::Role ();
use Carp qw( croak );
use Import::Into;
use Module::Runtime qw( use_module );
use Package::Stash;
use Scalar::Util qw( blessed );
use Types::Standard qw( Any ArrayRef Bool HashRef InstanceOf Int Maybe Num Str );
use API::Docker::Role::Type ();
use JSON::MaybeXS ();
use namespace::clean;


my %SCALAR_TYPE = (
  Str  => Str,
  Int  => Int,
  Num  => Num,
  Bool => Bool,
);

# Names API::Docker::Role::Type already occupies. A generated attribute that
# collided with one of these would silently replace it, so it is refused
# instead -- the generator has to pick another Perl name and say so with an
# explicit `wire`.
my %RESERVED = map { ($_ => 1) } qw(
  new BUILDARGS unknown_fields rejected_fields from_data from_json TO_JSON to_json
  docker_attributes docker_attribute_order docker docker_extends
);

sub import {
  my ($class) = @_;
  $class->_setup_class(scalar caller);
  return;
}

# Per-class state that has to outlive the class's own compilation, because a
# generated class ends its body with `use namespace::clean`. That pragma takes
# a snapshot of the package's subs when it is reached and strips every one of
# them at the end of the class's compilation -- the imported Moo and type
# sugar, the two DSL keywords, AND anything a role composed at that point had
# already installed. Two consequences shape the setup below.
#
#   has / extends -- The runtime `docker ...;` and `docker_extends ...;` lines
#     fire after that cleanup, so by then `has` and `extends` are gone from the
#     class and `$target->can('has')` returns undef. The `docker` keyword and
#     the `Str`/`Int`/... it is handed survive the same cleanup only because
#     Perl bound their CV into the call site at compile time; a name the DSL
#     looks up by string at runtime has no such binding, so the two it resolves
#     that way are captured here while they are still imported.
#
#   the role -- API::Docker::Role::Type is NOT composed here. Composed at
#     import (a BEGIN action) its methods and its two attributes would sit in
#     namespace::clean's snapshot and be stripped with the sugar. So it is
#     composed on the first `docker`/`docker_extends` call instead -- at
#     runtime, after the cleanup, exactly as a `with 'Role'` line in a Moo
#     class body would run. Every generated class issues at least one such
#     call, and the composition lands before any object of the class is built.
my %CLASS_SUGAR;

sub _setup_class {
  my ($class, $target) = @_;
  Moo->import::into($target);
  Types::Standard->import::into($target, qw( Any Bool Int Num Str ));
  $CLASS_SUGAR{$target} = {
    has     => $target->can('has'),
    extends => $target->can('extends'),
  };
  my $stash = Package::Stash->new($target);
  $stash->add_symbol('&docker'         => sub { $class->_docker($target, @_) });
  $stash->add_symbol('&docker_extends' => sub { $class->_docker_extends($target, @_) });
  return;
}

# Compose API::Docker::Role::Type once, on the first DSL call the class makes.
# Runtime, so it outlasts the class's `use namespace::clean`; idempotent, so
# the second and later DSL calls are a cheap flag check.
sub _ensure_role {
  my ($target) = @_;
  return if $CLASS_SUGAR{$target}{role_composed};
  $CLASS_SUGAR{$target}{role_composed} = 1;
  Moo::Role->apply_roles_to_package($target, 'API::Docker::Role::Type');
  return;
}

# The one place a short class name becomes a full one. 'Mount' is
# API::Docker::Type::Mount; a name that already starts with the prefix is
# left alone; a leading + means "this is the full name, take it as it is".
# Docker's definitions are flat -- there are no groups to map, which is why
# there is no prefix table here and only this one rule.
sub _expand_class {
  my ($short) = @_;
  return substr($short, 1) if $short =~ /\A\+/;
  return $short if $short =~ /\AAPI::Docker::Type::/;
  return 'API::Docker::Type::' . $short;
}

# PortBindings <- port_bindings. One direction only; see the POD above.
sub _wire_from_perl {
  my ($name) = @_;
  return join '', map { ucfirst } split /_/, $name;
}

sub _is_type_tiny { return blessed($_[0]) && $_[0]->isa('Type::Tiny') }

# A type spec becomes a descriptor, recursively:
#   { kind => 'scalar', scalar => 'Str' }
#   { kind => 'object', class  => 'API::Docker::Type::PortBinding' }
#   { kind => 'array',  inner  => <descriptor> }
#   { kind => 'hash',   inner  => <descriptor> }   keys are caller data
#   { kind => 'any' }
# One recursive shape rather than a flag per combination, so { Str,
# ['PortBinding'] } and [[Str]] need no cases of their own anywhere.
sub _parse_type {
  my ($spec, $where) = @_;
  if (_is_type_tiny($spec)) {
    my $name = $spec->name;
    return { kind => 'any' } if $name eq 'Any';
    return { kind => 'scalar', scalar => $name } if $SCALAR_TYPE{$name};
    croak __PACKAGE__ . ": $where has unsupported type " . $name;
  }
  if (ref $spec eq 'ARRAY') {
    croak __PACKAGE__ . ": $where is an array type with "
      . scalar(@$spec) . ' element types, it needs exactly one'
      unless @$spec == 1;
    return { kind => 'array', inner => _parse_type($spec->[0], $where) };
  }
  if (ref $spec eq 'HASH') {
    my @keys = keys %$spec;
    croak __PACKAGE__ . ": $where is a hash type; write it as { Str, \$value_type }"
      unless @keys == 1 && $keys[0] eq 'Str';
    return { kind => 'hash', inner => _parse_type($spec->{Str}, $where) };
  }
  if (!ref $spec) {
    return { kind => 'any' } if $spec eq 'Any';
    return { kind => 'scalar', scalar => $spec } if $SCALAR_TYPE{$spec};
    return { kind => 'object', class => _expand_class($spec) };
  }
  croak __PACKAGE__ . ": $where has an unreadable type spec (" . ref($spec) . ')';
}


sub describe_type {
  my ($d) = @_;
  my $kind = $d->{kind};
  return lc $d->{scalar} if $kind eq 'scalar';
  return 'object<' . $d->{class} . '>' if $kind eq 'object';
  return 'array<' . describe_type($d->{inner}) . '>' if $kind eq 'array';
  return 'hash<' . describe_type($d->{inner}) . '>' if $kind eq 'hash';
  return 'any';
}

# Nothing is required, so every attribute is Maybe[...]. Hash values and
# array elements are Maybe[...] too: the daemon really does answer
# "2377/tcp": null inside a PortMap, and croaking while inflating a response
# we could otherwise use is not an improvement.
sub _isa_for {
  my ($d) = @_;
  my $kind = $d->{kind};
  return undef if $kind eq 'any';
  return $SCALAR_TYPE{ $d->{scalar} } if $kind eq 'scalar';
  return InstanceOf[ $d->{class} ] if $kind eq 'object';
  my $inner = _isa_for($d->{inner});
  return $kind eq 'array' ? ArrayRef : HashRef unless $inner;
  return $kind eq 'array' ? ArrayRef[ Maybe[$inner] ] : HashRef[ Maybe[$inner] ];
}

# The boolean normalisation, borrowed from IO::K8s::Resource (../io-k8s-p5),
# which documents the two traps: every reference is true in Perl, so \0 and a
# JSON::PP::Boolean have to be dereferenced rather than tested; and 'false'
# is a non-empty string and therefore true, so the strings are spelled out.
#
# undef stays undef rather than becoming 0. Docker tells an absent flag apart
# from a false one, TO_JSON omits undef, and "no value" must not turn into an
# explicit false on the wire.
sub _normalize_bool {
  my ($value) = @_;
  if (ref $value) {
    my $reftype = Scalar::Util::reftype($value);
    croak __PACKAGE__ . ': a Bool wants a scalar or a scalar ref, got ' . $reftype
      unless $reftype eq 'SCALAR' || $reftype eq 'REF';
    $value = $$value;
    croak __PACKAGE__ . ': a Bool scalar ref dereferenced to another reference ('
      . ref($value) . '), not a boolean' if ref $value;
  }
  return undef unless defined $value;
  return 0 if lc($value) eq 'false';
  return $value ? 1 : 0;
}

# A hashref handed to an object-typed field is inflated the way the entry
# point that started the construction reads keys: through from_data while an
# engine response is being inflated, through new otherwise. So a nested
# literal in a request a caller assembled takes both spellings, and a nested
# object in a daemon response resolves wire names only -- the same
# distinction the two entry points draw at the top level, carried one level
# down. The class is loaded on first use rather than at declaration time: the
# registry is the only place its name appears, and loading it while the
# declaring class is still compiling would close a cycle the moment two
# definitions reference each other.
sub _coerce_for {
  my ($d) = @_;
  my $kind = $d->{kind};
  return \&_normalize_bool if $kind eq 'scalar' && $d->{scalar} eq 'Bool';
  if ($kind eq 'object') {
    my $class = $d->{class};
    my $loaded;
    return sub {
      my ($value) = @_;
      return $value unless ref $value eq 'HASH';
      $loaded ||= use_module($class);
      return $API::Docker::Role::Type::RESPONSE
        ? $class->from_data($value)
        : $class->new(%$value);
    };
  }
  my $inner = $kind eq 'array' || $kind eq 'hash' ? _coerce_for($d->{inner}) : undef;
  return undef unless $inner;
  return sub {
    my ($value) = @_;
    return $value unless ref $value eq 'ARRAY';
    return [ map { $inner->($_) } @$value ];
  } if $kind eq 'array';
  return sub {
    my ($value) = @_;
    return $value unless ref $value eq 'HASH';
    # The keys are the caller's data: copied across, never touched.
    return { map { ($_ => $inner->($value->{$_})) } keys %$value };
  };
}

# The serialisation half of a descriptor. Called by
# API::Docker::Role::Type::TO_JSON, which decides what to skip.
sub _encode_value {
  my ($d, $value) = @_;
  return undef unless defined $value;
  my $kind = $d->{kind};
  if ($kind eq 'scalar') {
    my $scalar = $d->{scalar};
    return $value ? JSON::MaybeXS::true() : JSON::MaybeXS::false() if $scalar eq 'Bool';
    return int($value) if $scalar eq 'Int';
    return 0 + $value  if $scalar eq 'Num';
    return "$value";
  }
  return $value->TO_JSON if $kind eq 'object';
  return [ map { _encode_value($d->{inner}, $_) } @$value ] if $kind eq 'array';
  return { map { ($_ => _encode_value($d->{inner}, $value->{$_})) } keys %$value }
    if $kind eq 'hash';
  return [ @$value ] if ref $value eq 'ARRAY';
  return { %$value } if ref $value eq 'HASH';
  return $value;
}

sub _docker {
  my ($class, $target, $name, $type_spec, %opt) = @_;
  _ensure_role($target);
  croak __PACKAGE__ . ": '$name' is not a snake_case attribute name"
    unless defined $name && $name =~ /\A[a-z][a-z0-9_]*\z/;
  croak __PACKAGE__ . ": '$name' in $target is a name this role already uses"
    if $RESERVED{$name};
  croak __PACKAGE__ . ": '$name' is declared twice in $target"
    if $REGISTRY{$target} && $REGISTRY{$target}{$name};

  my $wire     = delete $opt{wire} // _wire_from_perl($name);
  # The Perl-name guard above has a twin: _docker_wire_index maps a wire name
  # to one Perl name, so a second field claiming a wire name would make the
  # first unreachable on inflation while TO_JSON wrote both to that one key.
  # None of the 201 generated classes does this; the generator could emit it
  # the day a hand-picked `wire` collides with a derived one (karr k85).
  if (my ($taken) = sort grep { $REGISTRY{$target}{$_}{wire} eq $wire }
                      keys %{ $REGISTRY{$target} || {} }) {
    croak __PACKAGE__ . ": '$name' in $target asks for the wire name "
      . "'$wire', which '$taken' already has";
  }
  my $since    = delete $opt{since};
  my $enum     = delete $opt{enum};
  my $required = delete $opt{required} ? 1 : 0;
  croak __PACKAGE__ . ": '$name' in $target got unknown option(s): "
    . join(', ', sort keys %opt) if %opt;

  my $descriptor = _parse_type($type_spec, "$target\::$name");
  my $isa    = _isa_for($descriptor);
  my $coerce = _coerce_for($descriptor);
  $REGISTRY{$target}{$name} = {
    name     => $name,
    wire     => $wire,
    type     => $descriptor,
    since    => $since,
    enum     => $enum,
    required => $required,
    # The same two the Moo attribute below is given, kept so the response
    # path can ask whether a value fits before handing it to the constructor
    # rather than finding out by being croaked at (karr k83).
    isa      => $isa ? Maybe[$isa] : undef,
    coerce   => $coerce,
  };
  {
    no strict 'refs';
    push @{"${target}::_docker_attr_order"}, $name;
  }
  API::Docker::Role::Type::_invalidate_docker_cache($target);

  my $has = $CLASS_SUGAR{$target}{has} // $target->can('has');
  my $info = $REGISTRY{$target}{$name};
  $has->($name,
    is => 'rw',
    ($info->{isa}    ? (isa    => $info->{isa})    : ()),
    ($info->{coerce} ? (coerce => $info->{coerce}) : ()),
  );
  return;
}

sub _docker_extends {
  my ($class, $target, @parents) = @_;
  _ensure_role($target);
  croak __PACKAGE__ . ": docker_extends in $target needs at least one class"
    unless @parents;
  my @full = map { use_module(_expand_class($_)) } @parents;
  my $extends = $CLASS_SUGAR{$target}{extends} // $target->can('extends');
  $extends->(@full);
  API::Docker::Role::Type::_invalidate_docker_cache($target);
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type - The DSL and attribute registry behind the generated Docker types

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    package API::Docker::Type::Mount;
    use API::Docker::Type;

    docker target => Str;

    =attr target

    Container path.

    =cut

    docker bind_options => 'Mount::BindOptions', since => '1.41';
    docker labels       => { Str, Str };
    docker ulimits      => [ 'Resources::Ulimit' ];
    docker cpu_shares   => Int, wire => 'CPUShares';

=head1 DESCRIPTION

C<API::Docker::Type> is imported, never inherited. Importing it pulls
L<Moo>, the type vocabulary and L<API::Docker::Role::Type> into the calling
package and installs two keywords, C<docker> and C<docker_extends>.

Every class under C<API::Docker::Type::*> is a Perl mirror of one entry
under C<definitions:> in Docker's swagger, which is checked into C<spec/>.
The classes are written from that specification and B<not> from a running
daemon; C<maint/spec-drift-check.pl> is what keeps that claim true.

=head2 What C<docker> does

    docker $perl_name => $type;
    docker $perl_name => $type, wire => 'CPUShares';
    docker $perl_name => $type, since => '1.44';
    docker $perl_name => $type, required => 1;

It declares a Moo attribute B<and> writes an entry into a package-level
registry. Both halves matter: the attribute is what a caller uses, the
registry is what serialisation and the drift checker read. A field that is
an attribute but not in the registry is invisible to the drift checker,
which is the failure mode that would make the whole model untrustworthy.

Attributes are C<rw>. These objects are request payloads a caller assembles
field by field (C<< $host_config->privileged(1) >>), not immutable value
objects.

=head2 The wire name

The swagger's spelling is the truth and the Perl name is derived from it --
never the other way round, because the derivation does not round-trip:
C<PortBindings> and C<port_bindings> map to each other, C<KernelMemoryTCP>
and C<kernel_memory_tcp> do not.

At load time C<docker> derives the wire name back from the Perl name by
upper-casing the first letter of every underscore-separated part, so
C<port_bindings> becomes C<PortBindings>. Where that would not reproduce the
spec's spelling -- C<IP>, C<UTSMode>, C<KernelMemoryTCP>, C<DeviceIDs>,
C<IOMaximumIOps>, C<os.features> -- the declaration carries an explicit
C<< wire => '...' >> and the Perl name is chosen by hand.

A wire name belongs to one field. C<docker> refuses a declaration asking for
a name an earlier field in the same class already has, the way it refuses a
duplicate Perl name: both halves of the pair have to be unique, or inflation
would reach one of the two fields and C<TO_JSON> would write both to that one
key.

=head2 What C<since> can and cannot say

C<spec/> holds v1.41, v1.44, v1.51 and v1.55. The C<--from>/C<--to> mode of
C<maint/spec-drift-check.pl> diffs the first three to produce these values --
the swagger itself carries no per-field version at all. So C<< since =>
'1.51' >> means "not in v1.44, present in v1.51", not "introduced in v1.51":
the field appeared somewhere in v1.45 .. v1.51.

The fields grafted from v1.55 onto the v1.51 base, listed in
C<maint/spec-overlay.yaml>, carry C<< since => '1.55' >> from the overlay
itself. That means "not in v1.51, present in v1.55": the field appeared
somewhere in v1.52 .. v1.55. An attribute with no C<since> is already in
v1.41, the oldest spec checked in here.

=head2 C<since> is documentation

C<since> records which API version introduced a field. Nothing is checked,
warned about or dropped at runtime, ever. Podman serves fields its announced
version does not promise and refuses ones it does; we are not the authority
on what an engine can do. The value is visible in the C<since> key of each
field's declaration in its class's source, and in the registry.

C<required> is recorded from the swagger's C<required:> list and is likewise
not enforced: the same engines omit fields the specification calls required,
and croaking on a response we could otherwise use is not an improvement.

=head2 Keys that are the caller's data

The hash form marks a field whose I<keys> the user chose:

    docker labels        => { Str, Str };
    docker port_bindings => { Str, [ 'PortBinding' ] };

Those keys are passed through byte for byte in both directions. C<Labels>,
C<Annotations>, C<ExposedPorts>, C<PortBindings>, C<Volumes>, C<StorageOpt>,
C<Tmpfs>, C<Sysctls>, C<DriverOpts> and C<Options> are all of this shape --
in the swagger they are the fields carrying C<additionalProperties>, which
is the marker to check before deciding a hash's keys are structure. Turning
a label C<com.example.Some-Label> into something the caller never wrote is
the single most damaging mistake this model could make.

=head2 Unknown fields survive

Anything arriving under a name the registry does not know is kept verbatim
in L<API::Docker::Role::Type/unknown_fields> and written back out unchanged.
A caller whose engine is newer than the swagger we generated from still
reaches the daemon, and so does a field an engine sends that the swagger
does not describe. Which names count as known depends on the entry point --
C<from_data> reads an engine response and takes wire names only, C<new>
builds a request and takes either spelling; see that role for the reasoning.

A null is where the two name spaces part. A field the registry knows that
arrives as C<null> is read as unset and its key does not come back, because
the daemon cannot tell an explicit null from an absent field in either
direction; a field the registry does not know keeps its null, because
without a declared type there is no zero value to read it as. The
measurement and the three shapes it produces are in
L<API::Docker::Role::Type/"A null on a known field is read as unset">.

=head2 C<allOf> becomes inheritance

Two definitions in v1.51 are composed with C<allOf>, and both have the same
shape -- one C<$ref> plus one inline schema:

    HostConfig: allOf [ $ref Resources, { 39 properties } ]
    Swarm:      allOf [ $ref ClusterInfo, { 1 property } ]

The C<$ref> becomes a superclass and only the inline schema's properties are
declared in the child:

    package API::Docker::Type::HostConfig;
    use API::Docker::Type;

    docker_extends 'Resources';

C<allOf> in swagger means composition, and Perl inheritance says exactly
that. Nothing is duplicated: the parent's fields, their POD and the inline
classes declared inside the parent all stay in one place, and the merged
registry in L<API::Docker::Role::Type> presents C<HostConfig> with all ~70
fields. The alternative -- copying the parent's declarations into the child
-- would duplicate 31 attributes and their C<=attr> blocks and force the
inline classes underneath them to be named twice.

An C<allOf> holding a single C<$ref> and nothing else is not composition at
all; it is swagger's way of hanging a description on a C<$ref>
(C<Mount.Type> and C<MountPoint.Type> both do it). Such a field takes the
type of what it references, which for C<MountType> is C<Str>.

=head2 Inline objects become classes

A property whose schema is an object with its own C<properties>, or an array
whose C<items> are such an object, becomes a class named after the
definition that declares it:

    Mount.BindOptions             -> API::Docker::Type::Mount::BindOptions
    Mount.VolumeOptions.DriverConfig
                                  -> API::Docker::Type::Mount::VolumeOptions::DriverConfig
    Resources.Ulimits[]           -> API::Docker::Type::Resources::Ulimit

The last one is the exception to the mechanical rule: an array of inline
objects is named for one element, and turning C<Ulimits> into C<Ulimit> is a
judgement call, not a derivation. Those names live in
C<maint/spec-drift-exceptions.yaml> so the checker and a generator agree on
them.

=head2 A generated class loads what it references

Each class carries a plain C<use> for every other type class it names, so
loading C<API::Docker::Type::HostConfig> brings its whole subtree with it.
The declaration itself does B<not> load anything: a class named in a
C<docker> line is loaded lazily, on the first hashref that has to be
inflated into it. That is deliberate belt and braces -- v1.51's definitions
happen to have no reference cycles, and if a later version grows one the
C<use> for the back edge is what a generator has to leave out, while the
model keeps working either way.

=head1 THE TYPE VOCABULARY

    Str  Int  Num  Bool       scalars
    Any                       untyped; passed through as it arrived
    [Str]                     an array of scalars
    [[Str]]                   an array of arrays of scalars
    ['PortBinding']           an array of typed objects
    'PortBinding'             a single typed object
    '+Some::Other::Class'     the same, without the namespace prefix
    { Str, Str }              a hash whose KEYS ARE CALLER DATA
    { Str, ['PortBinding'] }  the same, with typed values

A bare class name is short: C<'PortBinding'> is
C<API::Docker::Type::PortBinding>, C<'Mount::BindOptions'> is
C<API::Docker::Type::Mount::BindOptions>. The expansion happens in
C<_expand_class> and nowhere else; a leading C<+> escapes it.

=head2 describe_type

    API::Docker::Type::describe_type($info->{type});   # 'hash<array<object>>'

A descriptor as one string, for the drift checker's report. Objects render
as C<< object<Class> >>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
