package DBIO::GraphQL::Mutation;
# ABSTRACT: Build createX / updateX / deleteX GraphQL field per source
use strict;
use warnings;

our $VERSION = '0.900004';

use base 'Class::Accessor::Grouped';
use GraphQL::Type::NonNull;
use GraphQL::Type::Scalar qw($Boolean);

use DBIO::GraphQL::ScalarMap;
use DBIO::GraphQL::Policy;
use DBIO::GraphQL::Error qw(client_error);

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
# rewriting the rest. This is the seam that future SoftDelete / Audit
# variants plug into.

# schema is the connected DBIO::Schema; required at construction.
__PACKAGE__->mk_group_accessors(simple => qw(schema policy));

sub new {
  my ($class, %args) = @_;
  die "DBIO::GraphQL::Mutation: 'schema' is required\n"
    unless exists $args{schema};
  my $self = bless {}, $class;
  $self->schema($args{schema});
  $self->policy($args{policy}
    // DBIO::GraphQL::Policy->new(schema => $args{schema}));
  return $self;
}

sub fields_for {
  my ($self, $source, $moniker, $gql_type) = @_;
  my %fields = (
    'create' . ucfirst($moniker) => $self->build_create($source, $moniker, $gql_type),
  );
  # A source without a primary key has no row identity to update or delete
  # by: only createX is generated for it.
  if ($source->primary_columns) {
    $fields{'update' . ucfirst($moniker)} =
      $self->build_update($source, $moniker, $gql_type);
    $fields{'delete' . ucfirst($moniker)} =
      $self->build_delete($source, $moniker);
  }
  return \%fields;
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
  for my $col ($self->policy->writable_columns($moniker)) {
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
      my $restriction = $self->policy->authorize('create', $moniker, $args, $ctx);
      my %data = map  { $_ => $args->{$_} }
                 grep { defined $args->{$_} } keys %$args;
      $self->_apply_create_restriction(\%data, $restriction) if $restriction;
      my $row  = eval { $ctx->resultset($moniker)->create(\%data) };
      die $@ if $@;
      return { $row->get_columns };
    },
  };
}

# updateX - lookup by PK or any unique constraint; data args are all
# non-key columns, all optional (sparse update: only defined args written).
sub build_update {
  my ($self, $source, $moniker, $gql_type) = @_;
  my @pk_cols   = $source->primary_columns;
  my %is_pk     = map { $_ => 1 } @pk_cols;
  my @data_cols = grep { !$is_pk{$_} } $self->policy->writable_columns($moniker);
  my %is_data   = map { $_ => 1 } @data_cols;

  my %lookup_args = %{ $self->_build_lookup_args($source, $moniker) };
  my %data_args   = map {
    $_ => { type => $self->_scalar_for($source, $_) }
  } @data_cols;

  return {
    type        => $gql_type,
    args        => { %lookup_args, %data_args },
    description => "Update an existing $moniker row identified by its primary key "
                 . "or by one complete unique constraint, never both and never "
                 . "several constraints. Non-key columns are optional; only supplied ones are updated.",
    resolve     => sub {
      my ($root, $args, $ctx) = @_;
      my $restriction = $self->policy->authorize('update', $moniker, $args, $ctx);
      my $row = $self->_resolve_row($ctx, $moniker, $args);
      die client_error "No $moniker row found for the supplied key(s)\n" unless $row;
      my %data = map  { $_ => $args->{$_} }
                 grep { $is_data{$_} && defined $args->{$_} } keys %$args;
      if ($restriction) {
        # The restriction stands in the writing statement itself: a row
        # outside it is not touched, whatever the lookup found.
        my $ident = { map { $_ => $row->get_column($_) } @pk_cols };
        my $rs    = $ctx->resultset($moniker)->search($restriction)->search($ident);
        my $n = eval { %data ? $rs->update(\%data) : $rs->count };
        die $@ if $@;
        die client_error "No $moniker row found for the supplied key(s)\n" unless $n && $n + 0;
        $row = $ctx->resultset($moniker)->find($ident);
      }
      else {
        $row = eval { $row->update(\%data); $row->discard_changes; $row };
        die $@ if $@;
      }
      return { $row->get_columns };
    },
  };
}

# deleteX - lookup by PK or any unique constraint; returns Boolean.
sub build_delete {
  my ($self, $source, $moniker) = @_;
  return {
    type        => $Boolean,
    args        => $self->_build_lookup_args($source, $moniker),
    description => "Delete a $moniker row identified by its primary key "
                 . "or by one complete unique constraint, never both and never "
                 . "several constraints. Returns true on success, false if "
                 . "no row matches; a failing DELETE is reported as an error.",
    resolve     => sub {
      my ($root, $args, $ctx) = @_;
      my $restriction = $self->policy->authorize('delete', $moniker, $args, $ctx);
      my $row = $self->_resolve_row($ctx, $moniker, $args);
      return 0 unless $row;
      if ($restriction) {
        # The restriction stands in the DELETE itself; false when it
        # matches no row.
        my $ident = { map { $_ => $row->get_column($_) } $source->primary_columns };
        my $n = eval { $ctx->resultset($moniker)->search($restriction)
                            ->search($ident)->delete };
        die $@ if $@;
        return ($n && $n + 0) ? 1 : 0;
      }
      # A failing DELETE dies like create/update, so the database error
      # reaches the top-level errors array; false is only "not found".
      eval { $row->delete; 1 } or die $@;
      return 1;
    },
  };
}

# Lookup arg shape: PK columns first, then each unique-constraint's
# columns (deduped).
# The primary key is always an identity. A unique-constraint column is an
# identity only while it may also be written: a hidden or readonly column
# is no argument, so its constraint can never be complete.
sub _build_lookup_args {
  my ($self, $source, $moniker) = @_;
  my %args;
  for my $col ($source->primary_columns) {
    $args{$col} = { type => $self->_scalar_for($source, $col) };
  }
  my %writable = map { $_ => 1 } $self->policy->writable_columns($moniker);
  my %unique = $source->unique_constraints;
  for my $name (keys %unique) {
    next if $name eq 'primary';
    for my $col (@{ $unique{$name} }) {
      next unless $writable{$col};
      $args{$col} //= { type => $self->_scalar_for($source, $col) };
    }
  }
  return \%args;
}

# The equality values of an authorize restriction become column values of
# the new row; a value from the client that differs from one is refused
# (core k381: the client does not choose what the policy fixes).
sub _apply_create_restriction {
  my ($self, $data, $restriction) = @_;
  for my $col (sort keys %$restriction) {
    my $want = $restriction->{$col};
    die client_error "DBIO::GraphQL: authorize restriction on column '$col' is not an "
      . "equality value and cannot be applied to a create\n"
      if ref $want;
    if (defined $data->{$col}) {
      die client_error "DBIO::GraphQL: column '$col' conflicts with the authorize restriction\n"
        unless defined $want && $data->{$col} eq $want;
    }
    $data->{$col} = $want if defined $want;
  }
}

sub _resolve_row {
  my ($self, $ctx, $moniker, $args) = @_;
  my $source = $ctx->source($moniker);
  my $rs     = $ctx->resultset($moniker);

  # A complete primary key alone names the row: no fallback to a unique
  # constraint, whose columns are data arguments of updateX at the same time.
  my @pk_cols = $source->primary_columns;
  my @pk_vals = map { $args->{$_} } @pk_cols;
  if (@pk_cols && !grep { !defined } @pk_vals) {
    return $rs->find({ map { $pk_cols[$_] => $pk_vals[$_] }
                           0 .. $#pk_cols });
  }

  # No complete primary key. A partial primary key names no row, and it
  # must not be dropped silently while a constraint finds some other one,
  # nor may one of several complete constraints be guessed.
  my @given_pk = grep { defined $args->{$_} } @pk_cols;

  my %unique   = $source->unique_constraints;
  my @complete = grep {
    my $n = $_;
    $n ne 'primary' && !grep { !defined $args->{$_} } @{ $unique{$n} };
  } sort keys %unique;

  die client_error "DBIO::GraphQL: $moniker key is ambiguous: the complete unique "
    . "constraints " . join(', ', @complete) . " were supplied together; "
    . "pass one\n"
    if @complete > 1;
  die client_error "DBIO::GraphQL: $moniker key is ambiguous: a partial primary key ("
    . join(', ', @given_pk) . ") was supplied beside unique constraint "
    . "$complete[0]; pass the complete primary key or the constraint alone\n"
    if @given_pk && @complete;

  return undef unless @complete;
  return $rs->find({ map { $_ => $args->{$_} } @{ $unique{ $complete[0] } } });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL::Mutation - Build createX / updateX / deleteX GraphQL field per source

=head1 VERSION

version 0.900004

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
