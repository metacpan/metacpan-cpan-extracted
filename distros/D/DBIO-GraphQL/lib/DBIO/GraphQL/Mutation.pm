package DBIO::GraphQL::Mutation;
# ABSTRACT: Build createX / updateX / deleteX GraphQL field per source
use strict;
use warnings;

use base 'Class::Accessor::Grouped';
use GraphQL::Type::NonNull;
use GraphQL::Type::Scalar qw($Boolean);

use DBIO::GraphQL::ScalarMap;

# fields_for($source, $moniker, $gql_type) returns:
#
#   {
#     'create' . ucfirst($moniker) => { type, args, description, resolve },
#     'update' . ucfirst($moniker) => { ... },
#     'delete' . ucfirst($moniker) => { ... },
#   }
#
# Each builder is its own method (build_create / build_update /
# build_delete) so subclasses can override a single kind without
# rewriting the rest. This is the seam that future SoftDelete / Audit /
# PartialUpdate variants plug into.

# schema is the connected DBIO::Schema; required at construction.
__PACKAGE__->mk_group_accessors(simple => qw(schema));

sub new {
  my ($class, %args) = @_;
  die "DBIO::GraphQL::Mutation: 'schema' is required\n"
    unless exists $args{schema};
  my $self = bless {}, $class;
  $self->schema($args{schema});
  return $self;
}

sub fields_for {
  my ($self, $source, $moniker, $gql_type) = @_;
  return {
    'create' . ucfirst($moniker) => $self->build_create($source, $moniker, $gql_type),
    'update' . ucfirst($moniker) => $self->build_update($source, $moniker, $gql_type),
    'delete' . ucfirst($moniker) => $self->build_delete($source, $moniker),
  };
}

sub _scalar_for {
  my ($self, $source, $col) = @_;
  return DBIO::GraphQL::ScalarMap::for_column($source, $col);
}

sub _col_is_required {
  my ($self, $source, $col) = @_;
  my $info = $source->column_info($col);
  return 0 if $info->{is_auto_increment};
  return 0 if defined $info->{default_value};
  return 0 if $info->{is_nullable};
  return 1;
}

# createX - all columns are accepted as args; required columns (not
# auto-inc, no default, not nullable) are wrapped in NonNull.
sub build_create {
  my ($self, $source, $moniker, $gql_type) = @_;
  my %args;
  for my $col ($source->columns) {
    my $scalar = $self->_scalar_for($source, $col);
    $args{$col} = {
      type => $self->_col_is_required($source, $col)
                ? GraphQL::Type::NonNull->new(of => $scalar)
                : $scalar,
    };
  }

  return {
    type        => $gql_type,
    args        => \%args,
    description => "Insert a new $moniker row. Required columns are marked non-null.",
    resolve     => sub {
      my ($root, $args, $ctx) = @_;
      my %data = map  { $_ => $args->{$_} }
                 grep { defined $args->{$_} } keys %$args;
      my $row  = eval { $ctx->resultset($moniker)->create(\%data) };
      die $@ if $@;
      return { $row->get_columns };
    },
  };
}

# updateX - lookup by PK or any unique constraint; data args are all
# non-key columns (full update).
sub build_update {
  my ($self, $source, $moniker, $gql_type) = @_;
  my @pk_cols   = $source->primary_columns;
  my %is_pk     = map { $_ => 1 } @pk_cols;
  my @data_cols = grep { !$is_pk{$_} } $source->columns;

  my %lookup_args = %{ $self->_build_lookup_args($source) };
  my %data_args   = map {
    $_ => { type => $self->_scalar_for($source, $_) }
  } @data_cols;

  return {
    type        => $gql_type,
    args        => { %lookup_args, %data_args },
    description => "Update an existing $moniker row identified by its primary key "
                 . "or any unique constraint. Pass all non-key columns.",
    resolve     => sub {
      my ($root, $args, $ctx) = @_;
      my $row = $self->_resolve_row($ctx, $moniker, $args);
      die "No $moniker row found for the supplied key(s)\n" unless $row;
      my %data = map  { $_ => $args->{$_} }
                 grep { !$is_pk{$_} && defined $args->{$_} } keys %$args;
      $row = eval { $row->update(\%data); $row->discard_changes; $row };
      die $@ if $@;
      return { $row->get_columns };
    },
  };
}

# deleteX - lookup by PK or any unique constraint; returns Boolean.
sub build_delete {
  my ($self, $source, $moniker) = @_;
  return {
    type        => $Boolean,
    args        => $self->_build_lookup_args($source),
    description => "Delete a $moniker row identified by its primary key "
                 . "or any unique constraint. Returns true on success.",
    resolve     => sub {
      my ($root, $args, $ctx) = @_;
      my $row = $self->_resolve_row($ctx, $moniker, $args);
      return 0 unless $row;
      eval { $row->delete };
      return $@ ? 0 : 1;
    },
  };
}

# Lookup arg shape: PK columns first, then each unique-constraint's
# columns (deduped).
sub _build_lookup_args {
  my ($self, $source) = @_;
  my %args;
  for my $col ($source->primary_columns) {
    $args{$col} = { type => $self->_scalar_for($source, $col) };
  }
  my %unique = $source->unique_constraints;
  for my $name (keys %unique) {
    next if $name eq 'primary';
    for my $col (@{ $unique{$name} }) {
      $args{$col} //= { type => $self->_scalar_for($source, $col) };
    }
  }
  return \%args;
}

sub _resolve_row {
  my ($self, $ctx, $moniker, $args) = @_;
  my $source = $ctx->source($moniker);
  my $rs     = $ctx->resultset($moniker);

  my @pk_cols = $source->primary_columns;
  my @pk_vals = map { $args->{$_} } @pk_cols;
  unless (grep { !defined } @pk_vals) {
    my $row = $rs->find({ map { $pk_cols[$_] => $pk_vals[$_] }
                              0 .. $#pk_cols });
    return $row if $row;
  }

  my %unique = $source->unique_constraints;
  for my $name (sort grep { $_ ne 'primary' } keys %unique) {
    my @cols = @{ $unique{$name} };
    my @vals = map { $args->{$_} } @cols;
    next if grep { !defined } @vals;
    my $row = $rs->find({ map { $cols[$_] => $vals[$_] } 0 .. $#cols });
    return $row if $row;
  }
  return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL::Mutation - Build createX / updateX / deleteX GraphQL field per source

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
