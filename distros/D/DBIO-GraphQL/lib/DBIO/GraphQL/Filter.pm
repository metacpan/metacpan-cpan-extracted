package DBIO::GraphQL::Filter;
# ABSTRACT: Per-source GraphQL filter InputObject with adapter seam
use strict;
use warnings;

use base 'Class::Accessor::Grouped';
use GraphQL::Type::InputObject;
use GraphQL::Type::List;
use GraphQL::Type::Scalar qw($Int $String $Float $Boolean);

use DBIO::GraphQL::ScalarMap;

# Adapter interface — two concrete adapters live in this distribution:
#
#   DBIO::GraphQL::Filter::Search  - per-source nested-DBIO-style filter
#                                    (the default)
#   DBIO::GraphQL::Filter::Null    - no-op; exposes an empty filter type
#
# Subclasses must implement (or inherit) type_for($moniker) and
# to_search($args, $moniker). The seam is real because Null and Search
# produce different GraphQL surfaces AND different DBIO search
# conditions for the same source moniker.

# schema is the connected DBIO::Schema; required at construction.
# _type_cache is a per-instance cache of { $moniker => $filter_type }.
# Shared scalar InputObjects (IntFilter, StringFilter, ...) are cached
# at the class level (see %_SCALAR_INPUT) so two filter instances cannot
# accidentally produce two IntFilter types with the same name.
__PACKAGE__->mk_group_accessors(simple => qw(schema _type_cache));

sub new {
  my ($class, %args) = @_;
  die "DBIO::GraphQL::Filter: 'schema' is required\n"
    unless exists $args{schema};
  my $self = bless {}, $class;
  $self->schema($args{schema});
  $self->_type_cache({});
  return $self;
}

# Class-level cache of shared scalar InputObjects. Keyed by GraphQL
# scalar name (Int/Float/String/Boolean).
my %_SCALAR_INPUT;

# Operator spec per GraphQL scalar. Each entry is a list of operator
# descriptors with:
#   name => 'gt'                          (GraphQL field name)
#   type => $GraphQL::Type::Scalar        (input arg type)
#   op   => '>' | 'like' | '-in' | '_null' (DBIO op key, or special)
#   wrap => sub { ... }                   (optional: value transformer)
#
# The 'wrap' lets us express 'contains' / 'startsWith' / 'endsWith'
# without inventing new DBIO operators: we just wrap the value with
# SQL wildcards before handing it to { like => ... }.
sub _ops_for {
  return {
    Int => [
      { name => 'eq',     type => $Int,    op => '='  },
      { name => 'not',    type => $Int,    op => '!=' },
      { name => 'gt',     type => $Int,    op => '>'  },
      { name => 'gte',    type => $Int,    op => '>=' },
      { name => 'lt',     type => $Int,    op => '<'  },
      { name => 'lte',    type => $Int,    op => '<=' },
      { name => 'in',     type => GraphQL::Type::List->new(of => $Int),     op => '-in'  },
      { name => 'isNull', type => $Boolean, op => '_null'                  },
    ],
    Float => [
      { name => 'eq',     type => $Float,  op => '='  },
      { name => 'not',    type => $Float,  op => '!=' },
      { name => 'gt',     type => $Float,  op => '>'  },
      { name => 'gte',    type => $Float,  op => '>=' },
      { name => 'lt',     type => $Float,  op => '<'  },
      { name => 'lte',    type => $Float,  op => '<=' },
      { name => 'in',     type => GraphQL::Type::List->new(of => $Float),   op => '-in'  },
      { name => 'isNull', type => $Boolean, op => '_null'                  },
    ],
    String => [
      { name => 'eq',         type => $String, op => '='  },
      { name => 'not',        type => $String, op => '!=' },
      { name => 'like',       type => $String, op => 'like' },
      { name => 'contains',   type => $String, op => 'like',
        wrap => sub { '%' . $_[0] . '%' } },
      { name => 'startsWith', type => $String, op => 'like',
        wrap => sub { $_[0] . '%'        } },
      { name => 'endsWith',   type => $String, op => 'like',
        wrap => sub { '%' . $_[0]        } },
      { name => 'in',         type => GraphQL::Type::List->new(of => $String), op => '-in' },
      { name => 'isNull',     type => $Boolean, op => '_null' },
    ],
    Boolean => [
      { name => 'eq',     type => $Boolean, op => '='  },
      { name => 'not',    type => $Boolean, op => '!=' },
      { name => 'isNull', type => $Boolean, op => '_null' },
    ],
  };
}

# Return the shared scalar InputObject (e.g. IntFilter) for a given
# GraphQL scalar name. Memoized at the class level.
sub _scalar_input {
  my ($class, $scalar_name) = @_;
  return $_SCALAR_INPUT{$scalar_name} ||= do {
    my $ops = $class->_ops_for->{$scalar_name}
      or die "DBIO::GraphQL::Filter: no operators for scalar '$scalar_name'\n";
    my %fields = map { $_->{name} => { type => $_->{type} } } @$ops;
    GraphQL::Type::InputObject->new(
      name   => "${scalar_name}Filter",
      fields => \%fields,
    );
  };
}

# Build the per-source filter InputObject. The forward-declaration
# trick lets AND/OR reference the same type recursively.
sub type_for {
  my ($self, $moniker) = @_;
  my $cache = $self->_type_cache;
  return $cache->{$moniker} if $cache->{$moniker};

  my $source = $self->schema->source($moniker);

  my $filter_type = GraphQL::Type::InputObject->new(
    name   => "${moniker}Filter",
    fields => sub { {} },
  );

  my %fields;
  for my $col ($source->columns) {
    my $scalar = DBIO::GraphQL::ScalarMap::for_column($source, $col);
    $fields{$col} = { type => $self->_scalar_input($scalar->name) };
  }

  $fields{AND} = { type => GraphQL::Type::List->new(of => $filter_type) };
  $fields{OR}  = { type => GraphQL::Type::List->new(of => $filter_type) };

  $filter_type->{fields} = sub { \%fields };

  return $cache->{$moniker} = $filter_type;
}

# Translate a filter args hashref (as received from a GraphQL resolver)
# into a DBIO search condition. Returns undef for empty / inert input.
#
# The output shape mirrors the GraphQL input shape:
#
#   { name: { like: "%Perl%" }, author_id: { gt: 3 } }
#   => { name => { like => '%Perl%' }, author_id => { '>' => 3 } }
#
# AND / OR propagate naturally: each combinator becomes a -and / -or
# at the top level of the resulting hashref.
sub to_search {
  my ($self, $args, $moniker) = @_;
  return undef unless $args && ref $args eq 'HASH' && %$args;
  my $source = $self->schema->source($moniker);
  return $self->_compile($args, $source);
}

sub _compile {
  my ($self, $filter, $source) = @_;
  my @clauses;

  if (my $and = $filter->{AND}) {
    my @sub = map { $self->_compile($_, $source) } @$and;
    my @defined_sub = grep { defined } @sub;
    push @clauses, { -and => \@defined_sub } if @defined_sub;
  }
  if (my $or = $filter->{OR}) {
    my @sub = map { $self->_compile($_, $source) } @$or;
    my @defined_sub = grep { defined } @sub;
    push @clauses, { -or  => \@defined_sub } if @defined_sub;
  }

  for my $col (keys %$filter) {
    next if $col eq 'AND' || $col eq 'OR';
    my $col_filter = $filter->{$col};
    next unless ref $col_filter eq 'HASH';
    my $clause = $self->_compile_column($col, $col_filter, $source);
    push @clauses, $clause if $clause;
  }

  return undef unless @clauses;
  return $clauses[0] if @clauses == 1;
  return { -and => \@clauses };
}

sub _compile_column {
  my ($self, $col, $ops, $source) = @_;
  unless ($source->has_column($col)) {
    die "DBIO::GraphQL::Filter: unknown column '$col' on source '"
      . $source->source_name . "'\n";
  }

  my $scalar_name = DBIO::GraphQL::ScalarMap::for_column($source, $col)->name;
  my $spec_list   = $self->_ops_for->{$scalar_name}
    or die "DBIO::GraphQL::Filter: no operators for scalar '$scalar_name'\n";
  my %op_map = map { $_->{name} => $_ } @$spec_list;

  my @parts;
  for my $op_name (keys %$ops) {
    next unless defined $ops->{$op_name};
    my $spec = $op_map{$op_name}
      or die "DBIO::GraphQL::Filter: unknown operator '$op_name' on column "
           . "'$col' (scalar: $scalar_name)\n";

    my $dbio_op = $spec->{op};
    my $val     = $ops->{$op_name};

    if ($dbio_op eq '_null') {
      # isNull: true  => col => undef           (IS NULL)
      # isNull: false => col => { '!=' => undef } (IS NOT NULL)
      if ($val) {
        push @parts, { $col => undef };
      } else {
        push @parts, { $col => { '!=' => undef } };
      }
    }
    elsif ($op_name eq 'eq') {
      # eq: emit the bare "col => val" form (DBIO's implicit '=')
      push @parts, { $col => $val };
    }
    else {
      my $final_val = $spec->{wrap} ? $spec->{wrap}->($val) : $val;
      push @parts, { $col => { $dbio_op => $final_val } };
    }
  }

  return undef unless @parts;
  return $parts[0] if @parts == 1;
  return { -and => \@parts };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL::Filter - Per-source GraphQL filter InputObject with adapter seam

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
