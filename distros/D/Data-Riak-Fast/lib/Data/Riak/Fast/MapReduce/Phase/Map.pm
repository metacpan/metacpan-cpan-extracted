package Data::Riak::Fast::MapReduce::Phase::Map;
use Mouse;
use Mouse::Util::TypeConstraints;

use JSON::XS ();

# ABSTRACT: Map phase of a MapReduce

with ('Data::Riak::Fast::MapReduce::Phase');

=head1 DESCRIPTION

A map/reduce map phase for Data::Riak::Fast

=head1 SYNOPSIS

  my $mp = Data::Riak::Fast::MapReduce::Phase::Map->new(
    language => "javascript", # The default
    source => "function(v) { return [ v ] }",
    keep => 1 # The default
  );

=head2 keep

Flag controlling whether the results of this phase are included in the final
result of the map/reduce. Defaults to true.

=head2 language

The language used with this phase.  One of C<javascript> or C<erlang>. This
attribute is required.

=cut

has language => (
  is => 'ro',
  isa => enum([qw(javascript erlang)]),
  required => 1
);

=head2 name

The name, used with built-in functions provided by Riak such as
C<Riak.mapValues>.

=cut

has name => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_name'
);

has phase => (
  is => 'ro',
  isa => 'Str',
  default => 'map'
);

=head2 arg

The static argument passed to the map function.

=cut

has arg => (
  is => 'ro',
  isa => 'Str|HashRef',
  predicate => 'has_arg'
);

=head2 module

The module name, if you are using a riak built-in function.

=cut

has module => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_module'
);

=head2 function

The function name, if you are using a riak built-in function.

=cut

has function => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_function'
);

=head2 source

The source of the function used in this phase.

=cut

has source => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_source'
);

=head1 METHOD
=head2 pack()

Serialize this map phase.

=cut

sub pack {
  my $self = shift;

  my $href = {};

  $href->{keep} = $self->keep ? JSON::XS::true() : JSON::XS::false() if $self->has_keep;
  $href->{language} = $self->language;
  $href->{name} = $self->name if $self->has_name;
  $href->{source} = $self->source if $self->has_source;
  $href->{module} = $self->module if $self->has_module;
  $href->{function} = $self->function if $self->has_function;
  $href->{arg} = $self->arg if $self->has_arg;

  $href;
}

1;
