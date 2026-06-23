package DBIO::Introspect::Base;
# ABSTRACT: Base class for DBIO driver introspectors

use strict;
use warnings;


sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
}


sub dbh { $_[0]->{dbh} }


sub model { $_[0]->{model} //= $_[0]->_build_model }

sub _build_model {
  my ($self) = @_;
  die ref($self) . '::_build_model not implemented';
}


sub _aggregate_by {
  my ($class, $rows, $key_field) = @_;
  my %result;
  for my $row (@{ $rows // [] }) {
    my $key = $row->{$key_field} // next;
    push @{ $result{$key} }, $row;
  }
  return \%result;
}


sub _aggregate_by_ordered {
  my ($class, $rows, $key_field) = @_;
  my @order;
  my %index;
  for my $row (@{ $rows // [] }) {
    my $key = $row->{$key_field} // next;
    unless (exists $index{$key}) {
      $index{$key} = scalar @order;   # 0-based slot for this key
      push @order, [ $key, [] ];
    }
    push @{ $order[ $index{$key} ][1] }, $row;
  }
  return \@order;
}


sub table_keys {
  my ($self) = @_;
  return [ sort keys %{ $self->model->{tables} || {} } ];
}


sub table_columns {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} || [];
  return [ map { $_->{column_name} } @$cols ];
}


sub table_columns_info {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} || [];
  my %info;
  for my $col (@$cols) {
    $info{ $col->{column_name} } = {
      data_type     => $col->{data_type},
      is_nullable   => $col->{not_null} ? 0 : 1,
      default_value => $col->{default_value},
      (defined $col->{size} ? (size => $col->{size}) : ()),
      (exists $col->{is_auto_increment}
        ? (is_auto_increment => $col->{is_auto_increment}) : ()),
    };
  }
  return \%info;
}


sub table_pk_info {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} || [];
  return [
    map  { $_->{column_name} }
    sort { ($a->{pk_position} || 0) <=> ($b->{pk_position} || 0) }
    grep { $_->{is_pk} } @$cols
  ];
}


sub table_uniq_info {
  my ($self, $key) = @_;
  my $model = $self->model;

  if (exists $model->{unique_constraints}) {
    return $model->{unique_constraints}{$key} || [];
  }

  my $indexes = $model->{indexes}{$key} || {};
  my @uniq;
  for my $name (sort keys %$indexes) {
    my $idx = $indexes->{$name};
    next unless $idx->{is_unique};
    next if ($idx->{origin} || '') eq 'pk';
    next if uc($name) eq 'PRIMARY';
    push @uniq, [ $name => $idx->{columns} ];
  }
  return \@uniq;
}


sub table_fk_info {
  my ($self, $key) = @_;
  my $fks = $self->model->{foreign_keys}{$key} || [];
  return [
    map {
      +{
        local_columns  => $_->{from_columns},
        remote_table   => $_->{to_table},
        remote_schema  => undef,
        remote_columns => $_->{to_columns},
        attrs          => {
          on_delete => $_->{on_delete},
          on_update => $_->{on_update},
        },
      }
    } @$fks
  ];
}


sub table_is_view {
  my ($self, $key) = @_;
  my $tbl = $self->model->{tables}{$key} || {};
  return ($tbl->{kind} || '') eq 'view' ? 1 : 0;
}


sub view_definition { return undef }


sub table_comment { return undef }


sub column_comment { return undef }


sub result_class_extra_statements { return () }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Introspect::Base - Base class for DBIO driver introspectors

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Base class for the driver-specific introspectors
(L<DBIO::PostgreSQL::Introspect>, L<DBIO::SQLite::Introspect>,
L<DBIO::MySQL::Introspect>). Provides C<new>, the C<dbh> accessor, and the
lazy C<model> builder. Subclasses must implement C<_build_model>.

=head1 ATTRIBUTES

=head2 dbh

The connected C<DBI> database handle. Required.

=head1 METHODS

=head2 model

The introspected database model hashref. Built lazily on first access via
L</_build_model>. The shape varies by driver.

=head2 _aggregate_by

    my $by_table = $class->_aggregate_by(\@rows, 'table_name');

Groups a flat array of row hashrefs into C<{ $key_value => [\%row, ...] }>.
Preserves row order within each group. The C<\@rows> arrayref is consumed
(rows are shifted off); pass a copy if you need the original.

=head2 _aggregate_by_ordered

    my $groups = $class->_aggregate_by_ordered(\@rows, 'constraint_name');
    for my $pair (@$groups) {
      my ($key, $group_rows) = @$pair;
      ...
    }

Like L</_aggregate_by>, but returns an ArrayRef of C<[ $key, [\%row, ...] ]>
pairs in B<first-seen key order>, so callers that need deterministic group
ordering (e.g. composite foreign-key columns, which must keep their declared
local/remote pairing) do not have to reimplement the grouping. Row order
within each group is preserved. Rows whose key field is C<undef> are skipped.

=head2 table_keys

Returns an ArrayRef of opaque table-key strings (typically C<schema.table>
or just C<table>). These are passed as C<$key> to all other contract methods.
Default: the sorted bare table names from the canonical C<tables> section.

=head2 table_columns

    my \@names = $intro->table_columns($key);

Ordered list of column names for C<$key>. Default: the C<column_name> of each
entry in the canonical C<columns> section, in declaration order.

=head2 table_columns_info

    my \%info = %{ $intro->table_columns_info($key) };

Hashref C<{ col_name => { data_type, size, is_nullable, default_value,
is_auto_increment, ... } }>. Default: built from the canonical C<columns>
section -- C<is_nullable> is the inverse of C<not_null>; C<size> and
C<is_auto_increment> are included only when present on the column.

=head2 table_pk_info

    my \@pk_cols = @{ $intro->table_pk_info($key) };

Ordered list of primary key column names. Default: the C<is_pk> columns from
the canonical C<columns> section, ordered by C<pk_position> (composite keys
keep their declared order).

=head2 table_uniq_info

    my \@constraints = @{ $intro->table_uniq_info($key) };

List of C<[ $constraint_name, \@col_names ]> pairs. Default: the canonical
C<unique_constraints> section for C<$key> if that section exists; otherwise
derived from the C<indexes> section (unique indexes, skipping primary-key
backed ones and any index literally named C<PRIMARY>).

=head2 table_fk_info

    my \@fks = @{ $intro->table_fk_info($key) };

Each FK is a hashref:

    {
      local_columns  => [qw/author_id/],
      remote_table   => 'authors',
      remote_schema  => 'public',   # may be undef
      remote_columns => [qw/id/],   # may be [] (use remote PK)
      attrs          => {},
    }

Default: built from the canonical C<foreign_keys> section. C<remote_schema> is
always C<undef> (single-schema), and C<attrs> carries C<on_delete> /
C<on_update>.

=head2 table_is_view

Returns true if C<$key> is a view rather than a base table. Default: true when
the canonical C<tables> entry has C<< kind => 'view' >>.

=head2 view_definition

SQL text of the view definition, or C<undef>.

=head2 table_comment

Comment string for the table, or C<undef>.

=head2 column_comment

Comment string for a column, or C<undef>.

=head2 result_class_extra_statements

    my @stmts = $intro->result_class_extra_statements($key);

Optional hook for driver-specific emitter statements. Each element is an
arrayref C<[ $method_name, @args ]> which L<DBIO::Generate> emits verbatim
as C<__PACKAGE__->method_name(@args)>. Defaults to an empty list.

=head1 CANONICAL MODEL

The hashref returned by L</model> is the substrate every contract method reads.
Its shape varies by driver, but there is one B<canonical> shape -- the
un-qualified, single-database shape shared by the single-schema drivers
(MySQL, Firebird, SQLite). The default contract implementations below are
written against it, so any driver whose C<_build_model> produces this shape
inherits a working contract for free. Drivers that diverge (PostgreSQL:
schema-qualified keys, case normalization, enum/identity/generated columns)
override the methods they need.

The canonical model has up to five top-level sections, each a hashref keyed by
B<table name> (bare, un-qualified):

=over 4

=item * C<tables> -- C<< { $table => { table_name => $table, kind => 'table'|'view' } } >>

=item * C<columns> -- C<< { $table => [ \%column, ... ] } >> in declaration
order. Each column: C<column_name>, C<data_type> (bare SQL type), C<size>
(C<undef>, a scalar length, or a C<[precision, scale]> pair), C<not_null>
(C<0>/C<1>), C<default_value> (or C<undef>), C<is_pk> / C<pk_position>
(primary-key membership and 1-based ordinal), and optionally
C<is_auto_increment>.

=item * C<indexes> -- C<< { $table => { $index_name => { is_unique, columns => [...], origin } } } >>.
C<origin> is C<'pk'> for a primary-key-backed index (skipped by
L</table_uniq_info>).

=item * C<unique_constraints> -- (optional) C<< { $table => [ [ $name, \@cols ], ... ] } >>.
When present, it is the authoritative source for L</table_uniq_info>; when
absent, unique constraints are derived from the C<indexes> section.

=item * C<foreign_keys> -- C<< { $table => [ \%fk, ... ] } >>. Each FK:
C<from_columns>, C<to_table>, C<to_columns>, C<on_update>, C<on_delete>, and
optionally C<constraint_name> -- the live, server-assigned constraint name,
carried by drivers that can introspect it so the diff/deploy layer can prefer
the real name for FK C<DROP>/C<ALTER> instead of a generated one. C<constraint_name>
is FK metadata, not a compared attribute. See ADR 0021.

=back

=head1 NORMALIZED CONTRACT

Subclasses that are used as a generation source for L<DBIO::Generate>
implement these methods. The first seven ship B<default implementations> that
read the L</CANONICAL MODEL>; a single-schema driver inherits them unchanged
and a divergent driver overrides what it needs. The remaining four return safe
defaults.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
