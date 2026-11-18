package API::Docker::Role::Filters;
# ABSTRACT: The filters query parameter, normalised into the one shape the engine reads
our $VERSION = '0.006';
use Moo::Role;
use Carp qw( croak );
use namespace::clean;


# The boolean classes JSON::MaybeXS hands back across its backends. Named
# rather than duck-typed: a blessed object that merely overloads bool is not
# a claim of being a JSON boolean.
my %BOOLEAN_CLASS = map { $_ => 1 } qw(
  JSON::PP::Boolean
  Types::Serialiser::Boolean
);

sub _normalise_filters {
  my ($self, $filters) = @_;

  croak __PACKAGE__ . '->_normalise_filters filters must be a HashRef of '
    . 'filter name to value, e.g. { dangling => [\'true\'] }'
    unless ref $filters eq 'HASH';

  my %normalised;
  for my $name (sort keys %$filters) {
    croak __PACKAGE__ . '->_normalise_filters filter name must not be empty'
      unless length $name;
    my $value = $filters->{$name};
    # A bare value is one value, not a mistake worth refusing -- the engine
    # is the one that insists on the list.
    my @values = ref $value eq 'ARRAY' ? @$value : ($value);
    $normalised{$name} = [ map { $self->_normalise_filter_value($name, $_) } @values ];
  }

  return \%normalised;
}

sub _normalise_filter_value {
  my ($self, $name, $value) = @_;

  my $where = __PACKAGE__ . '->_normalise_filters filter \'' . $name . '\' ';

  croak $where . 'has an undefined value; the engine reads a JSON null into '
    . 'a string as the empty string and rejects it there'
    unless defined $value;

  my $ref = ref $value;
  return $value ? 'true' : 'false' if $BOOLEAN_CLASS{$ref};

  if ($ref eq 'SCALAR') {
    croak $where . 'is a ScalarRef to something other than 1 or 0; \\1 and '
      . '\\0 are read as the booleans \'true\' and \'false\''
      unless $$value eq '1' || $$value eq '0';
    return $$value ? 'true' : 'false';
  }

  croak $where . 'has a ' . $ref . ' reference as a value; filter values are '
    . 'strings, or an ArrayRef of them' if $ref;

  croak $where . 'has an empty value; the engine rejects it. A Perl boolean '
    . 'stringifies to \'\' when false -- the engine wants the string '
    . '\'false\''
    unless length $value;

  # Stringify a copy: a scalar carrying a number would otherwise be
  # JSON-encoded as one, and the engine's filter values are strings.
  return "$value";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::Filters - The filters query parameter, normalised into the one shape the engine reads

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    package API::Docker::API::Whatever;
    use Moo;
    with 'API::Docker::Role::Filters';

    sub list {
      my ($self, %opts) = @_;
      my %params;
      $params{filters} = $self->_normalise_filters($opts{filters})
        if defined $opts{filters};
      return $self->client->get('/whatever', params => \%params);
    }

=head1 DESCRIPTION

Every C<list> and C<prune> endpoint of the Engine API takes a C<filters>
query parameter, and every one of them wants the same thing: a JSON B<map of
string to array of string>.

    filters => { dangling => ['true'] }        correct
    filters => { dangling => 'true'   }        wrong -- not an array
    filters => { dangling => 1        }        wrong -- not an array
    filters => { dangling => [1]      }        wrong -- a number, not a string
    filters => { dangling => [\1]     }        wrong -- a JSON boolean

The transport JSON-encodes a HashRef C<params> value on its own, so the
I<encoding> was never the problem. The I<shape> is, and it is the thing
clients get wrong, because Perl has no notion of "array of string" and a
HashRef literal will happily hold whatever the caller typed.

This role normalises that shape in one place, so the twelve methods that
accept C<filters> agree on it and document it by pointing here.

=head2 What it does

=over

=item * A value that is not an ArrayRef is wrapped into a one-element one, so
C<< { dangling => 'true' } >> means what it looks like it means.

=item * Each element is stringified, so C<< { stars => [3] } >> reaches the
wire as C<"3"> rather than as the number C<3>.

=item * A JSON boolean object (C<< JSON->true >>, C<< JSON->false >>) and the
ScalarRef form this distribution uses for JSON request bodies (C<\1>, C<\0>)
become the strings C<'true'> and C<'false'>.

=item * Anything else -- another ref, C<undef>, an empty string -- croaks.

=back

The result is a fresh HashRef; the caller's is never modified.

=head2 Why the boolean rewrite is bound to the type and not to the value

A helper that rewrote every true-ish value to C<'true'> would be wrong more
often than it was right. C<< { exited => [0] } >> asks for containers that
exited with status 0, C<< { stars => [0] } >> for images with no stars, and
C<< { label => [1] } >> for a label whose value is C<1> -- rewriting any of
those to C<'false'>/C<'true'> would silently ask a different question.

Binding it to the filter I<name> instead would need a table of which names
are boolean, per endpoint, kept in step with the daemon -- see
L</"What it deliberately does not do">.

So the rewrite is bound to the value's B<type>: a plain Perl C<1> carries no
claim of being a boolean and becomes the string C<"1">, while
C<< JSON->true >> and C<\1> carry exactly that claim, and are also the two
forms C<encode_json> would otherwise turn into a JSON C<true> -- which the
daemon rejects outright.

That leaves one form this role cannot recognise: perl 5.36's core booleans,
where C<< !!1 >> and C<< $x == $y >> produce a boolean the JSON encoder also
writes as C<true>. Stringified, those are C<"1"> and C<""> -- and C<"1"> is a
value the daemon reads as true, so only the false one needs help. It is the
reason an empty string croaks here rather than travelling on.

=head2 What it deliberately does not do

It does not check filter B<names>. Doing so would need one accepted-name
table per endpoint, and the daemon already has them: measured against Podman
5.x (API 1.41), an unknown name is refused with HTTP 500 by
C</containers/json> (C<bogusname is an invalid filter>), C</images/json>
(C<invalid image filter "danglin">), C</volumes>, C</networks> and
C</events>, and Docker validates C</plugins> the same way -- which is how the
Engine API reference's documented C<enable> turns out to be a hard error
where the daemon wants C<enabled> (see
L<API::Docker::API::Plugins/list>). A client-side table would duplicate that
check, and the first time it lagged the daemon it would refuse a filter the
daemon accepts. That is a worse failure than the one it prevents.

It also does not check that a value makes sense for its filter. C<'yes'> for
C<dangling> is a well-formed filter that the daemon rejects
(C<strconv.ParseBool: parsing "yes">), and C<< { label => ['nope'] } >> is a
well-formed filter that simply matches nothing. Both are the caller's
question to get right.

=head2 The daemon's side of each rule

Every rule above is a measured response, not a reading of the reference.
Against Podman on API 1.41, C<< GET /images/json >>:

    {"dangling":["true"]}   200, the dangling images
    {"dangling":"true"}     500 json: cannot unmarshal string into Go value
                                of type []string
    {"dangling":true}       500 json: cannot unmarshal bool into Go value of
                                type []string
    {"dangling":[true]}     500 json: cannot unmarshal bool into Go value of
                                type string
    {"dangling":[1]}        500 json: cannot unmarshal number into Go value
                                of type string
    {"dangling":[null]}     500 non-boolean value for filter:
                                strconv.ParseBool: parsing ""
    {"dangling":[""]}       500 the same -- Go reads a JSON null into a
                                string as ""
    {"dangling":["1"]}      200, and so do "0", "true" and "false"

So a wrong shape is not silent on this engine -- it is a 500 carrying a Go
type error, one round trip later, naming neither the option nor the key the
caller got wrong. What this role changes is where that is said: at the call,
in terms of the argument, and for the recoverable shapes not at all, because
they are repaired instead.

=head1 METHODS

C<_normalise_filters($filters)> is private and composed into the resource
classes. It takes what the caller passed as C<filters> and returns the
HashRef to hand to the transport as a query parameter; it croaks rather than
sending a shape the daemon will refuse.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Containers> - C<list>, C<prune>

=item * L<API::Docker::API::Images> - C<list>, C<search>, C<prune>,
C<build_prune>

=item * L<API::Docker::API::Networks> - C<list>, C<prune>

=item * L<API::Docker::API::Volumes> - C<list>, C<prune>

=item * L<API::Docker::API::System> - C<events>

=item * L<API::Docker::API::Secrets> - C<list>

=item * L<API::Docker::API::Configs> - C<list>

=item * L<API::Docker::API::Plugins> - C<list>, whose filter names the daemon
validates

=back

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
