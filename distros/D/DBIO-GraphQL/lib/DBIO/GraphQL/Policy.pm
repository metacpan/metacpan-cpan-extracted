package DBIO::GraphQL::Policy;
# ABSTRACT: What DBIO::GraphQL exposes and who may use it (the trust model)
use strict;
use warnings;

our $VERSION = '0.900004';

use base 'Class::Accessor::Grouped';
use DBIO::GraphQL::Error qw(client_error);

# The policy is the one place that knows the trust model of a generated
# schema: which sources and columns leave the boundary, which of them a
# client may write, which sources have mutations and what the authorize
# hook says about an operation. Filter, Mutation, Relationship and
# DBIO::GraphQL itself ask it; none of them decides on its own.

# schema is the connected DBIO::Schema; required at construction.
__PACKAGE__->mk_group_accessors(simple => qw(
  schema introspection _included _mutations _hide _readonly _authorize on_error
  default_rows max_rows max_in max_depth max_cost
));

sub new {
  my ($class, %args) = @_;
  die "DBIO::GraphQL::Policy: 'schema' is required\n"
    unless exists $args{schema};
  my $self = bless {}, $class;
  my $schema = $args{schema};
  $self->schema($schema);

  my %known = map { $_ => 1 } $schema->sources;

  die "DBIO::GraphQL: 'sources' and 'except' cannot be combined\n"
    if defined $args{sources} && defined $args{except};
  my @all = sort keys %known;
  my @included = @all;
  if (defined $args{sources}) {
    $self->_check_monikers(sources => $args{sources}, \%known);
    my %want = map { $_ => 1 } @{ $args{sources} };
    @included = grep { $want{$_} } @all;
  }
  elsif (defined $args{except}) {
    $self->_check_monikers(except => $args{except}, \%known);
    my %skip = map { $_ => 1 } @{ $args{except} };
    @included = grep { !$skip{$_} } @all;
  }
  $self->_included({ map { $_ => 1 } @included });

  my $mutations = $args{mutations};
  if (!$mutations) {
    $self->_mutations({});
  }
  elsif (ref $mutations eq 'ARRAY') {
    $self->_check_monikers(mutations => $mutations, $self->_included);
    $self->_mutations({ map { $_ => 1 } @$mutations });
  }
  else {
    $self->_mutations({ %{ $self->_included } });
  }

  for my $opt (qw(hide readonly)) {
    my $map = $args{$opt} // {};
    die "DBIO::GraphQL: '$opt' must be a hashref of source => [columns]\n"
      unless ref $map eq 'HASH';
    my %set;
    for my $moniker (keys %$map) {
      die "DBIO::GraphQL: '$opt' names unknown source '$moniker'\n"
        unless $known{$moniker};
      die "DBIO::GraphQL: '$opt' for source '$moniker' must be an arrayref of columns\n"
        unless ref $map->{$moniker} eq 'ARRAY';
      my $source = $schema->source($moniker);
      for my $col (@{ $map->{$moniker} }) {
        die "DBIO::GraphQL: '$opt' names unknown column '$col' on source '$moniker'\n"
          unless $source->has_column($col);
        $set{$moniker}{$col} = 1;
      }
    }
    $self->{"_$opt"} = \%set;
  }

  if (defined $args{authorize}) {
    die "DBIO::GraphQL: 'authorize' must be a code reference\n"
      unless ref $args{authorize} eq 'CODE';
    $self->_authorize($args{authorize});
  }

  if (defined $args{on_error}) {
    die "DBIO::GraphQL: 'on_error' must be a code reference\n"
      unless ref $args{on_error} eq 'CODE';
    $self->on_error($args{on_error});
  }

  my %limit = (default_rows => 100, max_rows => 1000, max_in => 500,
                max_depth => 10, max_cost => 10000);
  for my $opt (sort keys %limit) {
    my $value = exists $args{$opt} ? $args{$opt} : $limit{$opt};
    die "DBIO::GraphQL: '$opt' must be a positive integer\n"
      unless defined $value && !ref $value && $value =~ /\A[1-9][0-9]*\z/;
    $self->$opt($value + 0);
  }
  die sprintf("DBIO::GraphQL: 'default_rows' (%d) must not exceed 'max_rows' (%d)\n",
    $self->default_rows, $self->max_rows)
    if $self->default_rows > $self->max_rows;

  $self->introspection(exists $args{introspection} ? ($args{introspection} ? 1 : 0) : 1);

  return $self;
}

sub _check_monikers {
  my ($self, $opt, $list, $known) = @_;
  die "DBIO::GraphQL: '$opt' must be an arrayref of source names\n"
    unless ref $list eq 'ARRAY';
  for my $moniker (@$list) {
    die "DBIO::GraphQL: '$opt' names unknown source '$moniker'\n"
      unless $known->{$moniker};
  }
}


sub monikers { sort keys %{ $_[0]->_included } }


sub included { $_[0]->_included->{ $_[1] } ? 1 : 0 }


sub has_mutations { $_[0]->_mutations->{ $_[1] } ? 1 : 0 }


sub hidden {
  my ($self, $moniker, $col) = @_;
  return 1 if $self->_hide->{$moniker}{$col};
  my $info = $self->schema->source($moniker)->column_info($col) or return 0;
  return (exists $info->{is_serializable} && !$info->{is_serializable}) ? 1 : 0;
}


sub readonly { $_[0]->_readonly->{ $_[1] }{ $_[2] } ? 1 : 0 }


sub visible_columns {
  my ($self, $moniker) = @_;
  return grep { !$self->hidden($moniker, $_) }
         $self->schema->source($moniker)->columns;
}


sub writable_columns {
  my ($self, $moniker) = @_;
  return grep { !$self->readonly($moniker, $_) } $self->visible_columns($moniker);
}


sub check_depth {
  my ($self, $info) = @_;
  return unless $info && ref $info->{path} eq 'ARRAY';
  my $depth = grep { $_ !~ /\A[0-9]+\z/ } @{ $info->{path} };
  die client_error "DBIO::GraphQL: query depth exceeds max_depth (" . $self->max_depth . ")\n"
    if $depth > $self->max_depth;
  return;
}


sub authorize {
  my ($self, $op, $moniker, $args, $ctx, $relationship) = @_;
  my $hook = $self->_authorize or return undef;
  my $answer = $hook->($op, $moniker, $args, $ctx, $relationship);
  die client_error "DBIO::GraphQL: not authorized\n" unless $answer;
  return (ref $answer eq 'HASH' && %$answer) ? $answer : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL::Policy - What DBIO::GraphQL exposes and who may use it (the trust model)

=head1 VERSION

version 0.900004

=head1 METHODS

=head2 monikers

The sources that are exposed, sorted.

=head2 included

  $policy->included($moniker)

True when the source is part of the generated schema.

=head2 has_mutations

  $policy->has_mutations($moniker)

True when the source gets C<createX> / C<updateX> / C<deleteX>.

=head2 hidden

  $policy->hidden($moniker, $column)

True for a column named in C<hide> and for a column declared
C<< is_serializable => 0 >>. A hidden column is no field, no filter
field, no ordering and no mutation argument. The primary key stays
usable as the identity of get, update and delete.

=head2 readonly

  $policy->readonly($moniker, $column)

True for a column named in C<readonly>: readable, but never a mutation
argument.

=head2 visible_columns

  my @cols = $policy->visible_columns($moniker);

The columns of the source that are not hidden, in source order.

=head2 writable_columns

  my @cols = $policy->writable_columns($moniker);

The visible columns that are not C<readonly>: what a mutation may take
as a value.

=head2 check_depth

  $policy->check_depth($info);

Dies when the field being resolved lies deeper than C<max_depth>. The
depth is the number of field names in the path of the resolve info (list
indices do not count). The relationship resolvers call it, so the depth is
bounded for a caller that executes the schema without the C<execute>
code reference of L<DBIO::GraphQL/to_graphql>.

=head2 authorize

  my $restriction = $policy->authorize($op, $moniker, $args, $context, $relationship);

Asks the C<authorize> hook before a resolver touches the database.
Without a hook everything is allowed. A false answer dies with
C<not authorized>; a true answer returns C<undef>; a hashref returns the
(non-empty) restriction for the caller to apply.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
