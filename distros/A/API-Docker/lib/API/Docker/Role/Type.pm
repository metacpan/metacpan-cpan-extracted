package API::Docker::Role::Type;
# ABSTRACT: Instance behaviour of a generated API::Docker::Type class
our $VERSION = '0.006';
use Moo::Role;
use Carp qw( croak );
use JSON::MaybeXS ();
use namespace::clean;


# The merged views are rebuilt whenever API::Docker::Type registers a new
# attribute (it calls _invalidate_docker_cache), so they can be cached. Keyed
# by class name, one entry each.
my %ATTR_CACHE;    # class -> { perl_name => info }
my %ORDER_CACHE;   # class -> [ perl_name, ... ]
my %WIRE_CACHE;    # class -> { wire_name => perl_name }
my %ENTITY_CACHE;  # class -> { perl_name => 1 }  (not daemon fields)


has unknown_fields => (
  is      => 'ro',
  default => sub { {} },
);


has rejected_fields => (
  is      => 'ro',
  default => sub { {} },
);

# True while `from_data` is inflating a decoded engine response, so that the
# hashref coercion in API::Docker::Type reads a nested literal the same way
# the outermost one was read. Dynamically scoped: `local`ised around the
# whole construction, which is what a nested from_data sees.
our $RESPONSE = 0;


# Constructor-side name resolution for `new`, and one of the two places
# unknown fields are collected. A key is taken as a Perl attribute name
# first and as a wire name second, because `new` assembles a REQUEST out of
# what a caller wrote and both spellings are the caller's to choose. The
# response path does not come through here -- see L</from_data>.
#
# Two keys resolving to one attribute is refused rather than decided by hash
# order, and refused whether or not the two values agree: values that happen
# to match are not the same thing as an unambiguous call, and the caller
# should see the mistake instead of the luck (karr k85).
#
# Idempotent on purpose: where one generated class extends another (the
# `allOf` shape, see API::Docker::Type) the role is composed into both, so
# this modifier runs twice on the same arguments. The second pass sees every
# key already resolved and merges an empty set into unknown_fields.
around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  my $known = $class->_docker_attr_registry;
  my $wire  = $class->_docker_wire_index;
  my $mine  = $class->_entity_attribute_index;
  my %unknown  = %{ delete($args->{unknown_fields})  || {} };
  my %rejected = %{ delete($args->{rejected_fields}) || {} };
  my (%out, %from);
  for my $key (keys %$args) {
    my $attr = $known->{$key}           ? $key
             : defined $wire->{$key}    ? $wire->{$key}
             : $mine->{$key}            ? $key
             :                            undef;
    unless (defined $attr) { $unknown{$key} = $args->{$key}; next }
    croak __PACKAGE__ . ": $class got '"
      . join("' and '", sort($from{$attr}, $key))
      . "' for the same field '$attr'; pass one spelling, not both"
      if exists $out{$attr};
    $out{$attr}  = $args->{$key};
    $from{$attr} = $key;
  }
  $out{unknown_fields}  = \%unknown;
  $out{rejected_fields} = \%rejected;
  return \%out;
};


sub from_data {
  my ($class, $data, %extra) = @_;
  $class = ref($class) if ref($class);
  croak __PACKAGE__ . '->from_data needs a HashRef'
    unless ref $data eq 'HASH';
  my $reg  = $class->_docker_attr_registry;
  my $wire = $class->_docker_wire_index;
  # Lifted out of the loop rather than handled in it, so that what the loop
  # files never depends on the order the keys came out in -- the same reason
  # the BUILDARGS above deletes them before it starts.
  my %args;
  my %unknown  = %{ $data->{unknown_fields}  || {} };
  my %rejected = %{ $data->{rejected_fields} || {} };
  # In effect for the coercions _fits runs below as well as for the
  # constructor at the end: a nested hashref is part of the same response
  # and has to be read as one.
  local $RESPONSE = 1;
  for my $key (keys %$data) {
    next if $key eq 'unknown_fields' || $key eq 'rejected_fields';
    my $attr = $wire->{$key};
    # A decoded response is a map of wire names and nothing else, so a key
    # that is not one is a field we have not heard of -- even where it spells
    # an entity attribute such as `client`. Those never come from the daemon:
    # the resource API injects them as the %extra above, kept apart from $data
    # on purpose, so a key of that name in the response cannot overwrite ours
    # and is forwarded verbatim like any other unknown field (karr k104).
    unless (defined $attr) {
      $unknown{$key} = $data->{$key};
      next;
    }
    my ($fits, $value) = _fits($reg->{$attr}, $data->{$key});
    if ($fits) { $args{$attr} = $value; next }
    # A value the model cannot use costs that one field, not the response it
    # arrived in. It is kept under its wire name exactly as an unknown field
    # is, and named in rejected_fields so the caller can tell it apart from a
    # field the engine never sent (karr k83).
    $unknown{$key}  = $data->{$key};
    $rejected{$key} = $attr;
  }
  # Resolved to Perl names already, so the BUILDARGS above is a no-op over
  # them and stays idempotent across the two passes the `allOf` shape makes.
  return $class->new(%args, %extra,
    unknown_fields  => \%unknown,
    rejected_fields => \%rejected,
  );
}

# Does a value an engine sent fit the attribute the wire name resolved to?
# Answers with the coerced value where it does. The coercion runs here rather
# than being left to the constructor because it is what turns a nested
# hashref into an object and what refuses a Bool that is neither -- both have
# to happen before the value can be judged at all. Every coercion the DSL
# builds is idempotent, so the constructor running it again on the result
# changes nothing.
#
# The leniency is this sub and its one caller. `new` never comes through
# here, so a caller who writes a value the swagger does not allow is still
# croaked at by Moo: that is a typo in a request, not an engine being itself.
sub _fits {
  my ($info, $value) = @_;
  local $@;
  my $coerced = $info->{coerce} ? eval { $info->{coerce}->($value) } : $value;
  return (0) if $@;
  return (0) if $info->{isa} && !$info->{isa}->check($coerced);
  return (1, $coerced);
}


sub from_json {
  my ($class, $json) = @_;
  return $class->from_data(JSON::MaybeXS->new(utf8 => 1)->decode($json));
}


sub TO_JSON {
  my ($self) = @_;
  my %out = %{ $self->unknown_fields };
  my $reg = $self->_docker_attr_registry;
  for my $attr (@{ $self->_docker_attr_order }) {
    my $value = $self->$attr;
    next unless defined $value;
    $out{ $reg->{$attr}{wire} }
      = API::Docker::Type::_encode_value($reg->{$attr}{type}, $value);
  }
  return \%out;
}


sub to_json {
  my ($self) = @_;
  return JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1)
    ->encode($self->TO_JSON);
}


sub docker_attributes { return $_[0]->_docker_attr_registry }


sub docker_attribute_order { return $_[0]->_docker_attr_order }

# --- attributes that are not the daemon's ----------------------------------
#
# API::Docker::Role::Entity puts `client` on a generated class so the
# convenience methods have something to delegate through. It arrives at the
# same constructor as the daemon's fields, and without being named here it is
# neither a registry entry nor a wire name, so BUILDARGS would file it under
# unknown_fields -- where TO_JSON would faithfully offer the client object to
# the engine and JSON::MaybeXS would die trying to encode it. A class that
# composes such a role answers _entity_attributes with their names.

sub _entity_attribute_index {
  my $class = ref($_[0]) || $_[0];
  return $ENTITY_CACHE{$class} //= do {
    my %mine = $class->can('_entity_attributes')
      ? (map { ($_ => 1) } $class->_entity_attributes)
      : ();
    my $reg  = _docker_attr_registry($class);
    my $wire = _docker_wire_index($class);
    # Both sets reach the same constructor, so a name in both is an ambiguity
    # nobody can resolve at runtime -- say so instead of picking one.
    for my $name (sort keys %mine) {
      croak __PACKAGE__ . ": $class has '$name' as an entity attribute and as "
        . 'a daemon field; one of the two has to be renamed'
        if $reg->{$name} || defined $wire->{$name};
    }
    \%mine;
  };
}

# --- merged views over @ISA ------------------------------------------------
#
# A generated class that resolves an `allOf` inherits its parent's fields
# (see API::Docker::Type), so every lookup below is the class's own registry
# entry merged with its ancestors'. Nearest declaration wins.

sub _docker_attr_registry {
  my $class = ref($_[0]) || $_[0];
  return $ATTR_CACHE{$class} //= _merge_registry($class);
}

sub _merge_registry {
  my ($class) = @_;
  my %info = %{ $API::Docker::Type::REGISTRY{$class} // {} };
  no strict 'refs';
  for my $parent (@{"${class}::ISA"}) {
    my $up = _merge_registry($parent);
    $info{$_} //= $up->{$_} for keys %$up;
  }
  return \%info;
}

sub _docker_attr_order {
  my $class = ref($_[0]) || $_[0];
  return $ORDER_CACHE{$class} //= _merge_order($class);
}

sub _merge_order {
  my ($class) = @_;
  my (@order, %seen);
  _append_order($class, \@order, \%seen);
  return \@order;
}

sub _append_order {
  my ($class, $order, $seen) = @_;
  no strict 'refs';
  # Parents first: the swagger lists the inherited `$ref` ahead of the
  # class's own properties, and this keeps TO_JSON in that order.
  _append_order($_, $order, $seen) for @{"${class}::ISA"};
  for my $attr (@{"${class}::_docker_attr_order"}) {
    next if $seen->{$attr}++;
    push @$order, $attr;
  }
  return;
}

sub _docker_wire_index {
  my $class = ref($_[0]) || $_[0];
  return $WIRE_CACHE{$class} //= do {
    my $reg = _docker_attr_registry($class);
    +{ map { ($reg->{$_}{wire} => $_) } keys %$reg };
  };
}

# Called by API::Docker::Type after every registration: a merged view
# computed before a parent gained an attribute must not survive.
sub _invalidate_docker_cache {
  my ($class) = @_;
  my %sweep;
  @sweep{ keys %ATTR_CACHE, keys %ORDER_CACHE, keys %WIRE_CACHE,
          keys %ENTITY_CACHE } = ();
  for my $cached (keys %sweep) {
    next unless $cached eq $class || $cached->isa($class);
    delete $ATTR_CACHE{$cached};
    delete $ORDER_CACHE{$cached};
    delete $WIRE_CACHE{$cached};
    delete $ENTITY_CACHE{$cached};
  }
  delete $ATTR_CACHE{$class};
  delete $ORDER_CACHE{$class};
  delete $WIRE_CACHE{$class};
  delete $ENTITY_CACHE{$class};
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::Type - Instance behaviour of a generated API::Docker::Type class

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    # composed automatically by `use API::Docker::Type;`
    my $hc = API::Docker::Type::HostConfig->from_data($from_the_daemon);
    my $wire = $hc->TO_JSON;            # CamelCase keys, JSON booleans
    my $bytes = $hc->to_json;

=head1 DESCRIPTION

Every class under C<API::Docker::Type::*> composes this role; it is applied
by L<API::Docker::Type>'s C<import>, so a generated class never names it.

The role reads the attribute registry L<API::Docker::Type> writes -- it never
walks the object's own keys. A field that is an attribute but not in the
registry is invisible here, which is exactly what
C<maint/spec-drift-check.pl> exists to catch.

=head2 The two entry points have different jobs

L</from_data> inflates an engine B<response>: its keys are the daemon's, so
only the registry's wire names are read and everything else is preserved
under the name it arrived with. L</new> assembles a B<request> out of what a
caller wrote: its keys are the caller's, so the Perl spelling is read first
and the wire spelling is an alias for it.

The split is what keeps the passthrough invariant true. Resolving a Perl name
on the response path renames the engine's data -- Docker's swagger spells 114
fields with a lowercase first letter, so a lowercase key off an engine is
ordinary rather than exotic, and reading C<id> as the Perl name of C<Id> both
loses the field it really was and rewrites one we did know.

The same split decides what happens to a value that does not fit its declared
type. L</from_data> keeps it -- unset attribute, raw value in
L</unknown_fields>, name in L</rejected_fields> -- because one divergent field
must not make the rest of a usable response unreachable. L</new> croaks,
because there the value is the caller's and a mistake worth stopping on.

A nested hashref follows whichever entry point started the construction, so
one object graph is read one way throughout.

=head2 unknown_fields

A HashRef of everything that reached this object under a name the model could
not translate, kept under the name it arrived with and handed back out by
L</TO_JSON> unchanged. Two things land here: a name the registry does not know
at all, and -- on the response path only -- a known wire name whose value did
not fit the type the swagger declares for it. L</rejected_fields> is what
tells the two apart.

This is the whole reason a caller whose engine is newer than the swagger this
model was generated from still gets their field to the daemon. Translating
what we know and B<forwarding the rest verbatim> is worth more to this
distribution than a tidy model: a field the caller set must never be dropped
because we have not heard of it.

That promise covers the value as well as the name, C<undef> included: a name
the model does not know has no declared type, so there is no zero value we
could read a null as, and inventing one would be us deciding what the engine
meant. A B<known> field's null is the opposite case and is read as unset --
see L</"A null on a known field is read as unset">.

=head2 rejected_fields

A HashRef naming the fields this object could B<not> use, mapping the wire
name the value arrived under to the Perl attribute it would have filled.

It exists so that "the engine did not send this" and "the engine sent it and
the model could not use it" are two different observations. Both leave the
typed accessor C<undef>; only the second puts the field's wire name in here,
and the value itself in L</unknown_fields> beside it:

    my $c = API::Docker::Type::ContainerInspectResponse->from_data({
      Id => 'x', State => 'exited' });     # the swagger says State is an object

    $c->state                       # undef
    $c->rejected_fields->{State}    # 'state'  -- sent, and refused
    $c->unknown_fields->{State}     # 'exited' -- kept as it arrived
    $c->TO_JSON->{State}            # 'exited' -- and written back out

Only L</from_data> fills it. L</new> is strict and croaks instead, so an
object a caller built has an empty one.

=head2 new

    my $hc = API::Docker::Type::HostConfig->new(privileged => 1);
    my $hc = API::Docker::Type::HostConfig->new(Privileged => 1);   # the same

Builds an object from data a B<caller> wrote, which is what a request payload
is. Keys are matched against the Perl attribute names first and the registry's
wire names second, so either spelling reaches the attribute; anything else is
kept in L</unknown_fields>, exactly as on the response path.

Two keys that resolve to one attribute -- C<privileged> and C<Privileged>
together -- are B<refused>. Which one won was decided by hash order and
nothing else, measured at nine zeroes and eleven ones over twenty
constructions of the same arguments. They are refused even where the two
values agree: values that happen to match are not the same thing as an
unambiguous call, and the caller should be shown the mistake rather than the
luck.

Use L</from_data> for a decoded engine response. That is the other half of
the same split: there the keys are the daemon's, not the caller's, and only
the wire spelling may be read.

=head2 from_data

    my $mount = API::Docker::Type::Mount->from_data($hashref);
    my $c     = $class->from_data($hashref, client => $docker);

Builds an object from a decoded daemon response. Keys are matched against the
registry's B<wire> names; nested objects, arrays of objects and hashes of
objects are inflated the same way. Anything else is kept in
L</unknown_fields> under the name it arrived with.

Pairs after the hashref are attributes that did not come from the engine --
the C<client> a composed entity role declares in C<_entity_attributes> is the
one this distribution has. They are kept apart from C<$hashref> on purpose:
what the daemon sent and what we are adding are two different things, and a
daemon that one day sends a key of that name should not be able to overwrite
ours.

A decoded response is a map of wire names and nothing else, so that is the
only name space this reads. The Perl spelling is B<not> a second chance here,
and deliberately so: Docker's swagger gives 114 fields a wire name whose
first letter is lowercase -- C<BuildInfo.id> is one -- so a lowercase key off
an engine is ordinary. Reading such a key as the Perl name of a field we do
know would rename the engine's data and lose the field it really was. Use
L</new> where both spellings should be accepted; that is where a caller, not
an engine, is the author of the keys.

=head3 A value that does not fit costs one field, not the response

Where a value disagrees with the type the swagger declares -- a C<State> that
is the bare status string rather than the object C<ContainerInspectResponse>
declares -- the field is B<not> set, the response still inflates, and the raw
value is kept in L</unknown_fields> under its wire name with the name
recorded in L</rejected_fields>:

    $c->state                       # undef
    $c->rejected_fields->{State}    # 'state'
    $c->unknown_fields->{State}     # 'exited'
    $c->TO_JSON->{State}            # 'exited', byte for byte

We are not the authority on what an engine answers. Podman announces API 1.44
and Docker 1.55 on the machine this was written on, while the model is
generated from v1.51, and one divergent field making every other field of an
otherwise usable inspect unreachable is not an improvement. The typed
accessor keeps its contract either way: if it is set, it is the declared type.

This leniency is the response path's alone. L</new> croaks on a value that
does not fit, because there the value came from the caller and is a mistake
worth stopping on rather than an engine being itself.

=head3 A null on a known field is read as unset

An engine answering C<"Tags": null> is saying what an engine that omits the
field is saying, and this reads both the same way: the attribute stays
C<undef>, nothing is filed in L</unknown_fields> or L</rejected_fields>, and
L</TO_JSON> writes no key for it. The null is not carried and the key does
not come back.

That is not a convenience, it is the daemon's own resolution. Measured
2026-08-28 against Podman 5.8.4 (API 1.44) on C<POST /containers/create>,
with an image name nothing can resolve so that the body is parsed and no
container is created:

    {}                  500  parsing reference "": repository name must ...
    {"Image":null}      500  parsing reference "": repository name must ...
    {"Image":""}        500  parsing reference "": repository name must ...

Byte-identical, all three. Go's C<encoding/json> unmarshals a null into the
type's zero value, and an absent field leaves that same zero value behind --
C<""> for a string, nil for a map or a slice, false for a bool -- so the
daemon B<cannot> tell an explicit null from an absent field, and collapsing
the two loses no meaning it could have expressed. It holds outbound too,
which is why a null reaches us where a key could simply have been left out:
a nil slice marshals to C<null>, and C<GET /images/{id}/history> answers
C<"Tags": null> for a layer that carries no tag.

Three things that all look like a null therefore behave differently, on
purpose:

    my $n = API::Docker::Type::Network->from_data({
      Options => { 'com.docker.x' => undef },   # a key the caller chose
      IPAM    => { Options      => undef,       # a field we know
                   FutureNested => undef },     # a field we do not
    });

    $n->TO_JSON      # { Options => { 'com.docker.x' => undef },
                     #   IPAM    => { FutureNested => undef } }

The known field's null is a statement the daemon could have made in two ways,
so its key goes. The unknown field's null is data we cannot type, so it
stays. A null under a key the caller chose -- the C<additionalProperties>
shape, see L<API::Docker::Type/"Keys that are the caller's data"> -- is that
caller's value under that caller's key, and stays as well.

F<t/type_fixture_passthrough.t> holds all three against the captured
fixtures, at every depth rather than at the top level only.

=head2 from_json

    my $mount = API::Docker::Type::Mount->from_json($bytes);

L</from_data> on a JSON document. The argument is a UTF-8 encoded byte
string, exactly what L</to_json> produces.

=head2 TO_JSON

    my $struct = $host_config->TO_JSON;

The structure the daemon expects: registry wire names as keys, JSON booleans
for C<Bool>, nested objects serialised by their own C<TO_JSON>.

An attribute that was never set is B<omitted>, not sent as null -- Docker
tells an absent flag apart from a false one, and so does this. A known field
the engine sent as an explicit C<null> is such an attribute, so its key does
not come back either; that is measured rather than assumed, see
L</"A null on a known field is read as unset">. The contents of
L</unknown_fields> are written first and a set field wins over them -- and a
null kept there, under a name the model could not translate, does go out as
a null.

That precedence never costs a value L</from_data> preserved. A field lands in
C<unknown_fields> under a known wire name only when its typed attribute was
B<left unset> -- that is what being rejected means -- and an unset attribute
is one this loop skips, so the two do not meet. They meet only where someone
sets the attribute afterwards, or hands C<new> a C<unknown_fields> entry
beside the field of that name; in both of those the typed value is the later
and more deliberate one, and it is the one that goes out.

=head2 to_json

    my $bytes = $host_config->to_json;

L</TO_JSON> encoded as a UTF-8 byte string, canonical so two equal objects
encode to the same bytes.

=head2 docker_attributes

    my $info = API::Docker::Type::HostConfig->docker_attributes;

The class's merged attribute registry as a HashRef keyed by Perl attribute
name. Each entry carries C<wire>, C<type> (a type descriptor, see
L<API::Docker::Type>), C<since>, C<required> and C<enum>, plus the C<isa>
and C<coerce> the Moo attribute was declared with, which is what L</from_data>
asks before handing a value to the constructor. C<maint/spec-drift-check.pl>
reads the first five.

=head2 docker_attribute_order

    my $names = API::Docker::Type::HostConfig->docker_attribute_order;

The Perl attribute names in declaration order, inherited ones first -- which
is the order the fields appear in the swagger.

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
