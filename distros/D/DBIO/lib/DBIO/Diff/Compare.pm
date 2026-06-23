package DBIO::Diff::Compare;
# ABSTRACT: Engine-agnostic comparison helpers for DBIO diff operations

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
  norm norm_type arr_differ changed_fields
  changed_column_fields changed_index_fields changed_fk_fields
);


sub norm {
  my ($v) = @_;
  return defined $v ? $v : '';
}


sub norm_type {
  my ($t) = @_;
  return '' unless defined $t;
  $t =~ s/\s+/ /g;
  $t =~ s/^\s+//;
  $t =~ s/\s+$//;
  return uc $t;
}


sub arr_differ {
  my ($a, $b) = @_;
  $a = ref($a) eq 'ARRAY' ? $a : [];
  $b = ref($b) eq 'ARRAY' ? $b : [];
  return 1 if scalar(@$a) != scalar(@$b);
  my @sa = sort @$a;
  my @sb = sort @$b;
  for my $i (0 .. $#sa) {
    return 1 if $sa[$i] ne $sb[$i];
  }
  return 0;
}

# Internal: stringify a scalar-or-arrayref into an ORDER-PRESERVING key, for
# 'dim' fields where order is significant ([precision, scale], ordered columns).
sub _dim_key {
  my ($v) = @_;
  return join ',', map { defined $_ ? $_ : "\0" } @$v if ref($v) eq 'ARRAY';
  return norm($v);
}


sub changed_fields {
  my ($old, $new, %spec) = @_;
  # desired_state is the always-on contract now (any non-bool field the target
  # leaves undef is ignored); the key is accepted but vestigial. See DESCRIPTION.
  delete $spec{desired_state};
  $old ||= {};
  $new ||= {};

  my @changed;

  # Desired-state contract: a non-bool field the target ($new) leaves undef is a
  # "don't care" -- the desired state did not prescribe it, so whatever the live
  # database reports for it is left alone. Skip it from comparison entirely.
  my $skip = sub {
    my ($field) = @_;
    return !defined $new->{$field};
  };

  for my $field (@{ $spec{scalar} || [] }) {
    next if $skip->($field);
    push @changed, $field if norm($old->{$field}) ne norm($new->{$field});
  }
  for my $field (@{ $spec{type} || [] }) {
    next if $skip->($field);
    push @changed, $field if norm_type($old->{$field}) ne norm_type($new->{$field});
  }
  for my $field (@{ $spec{bool} || [] }) {
    push @changed, $field if (($old->{$field} // 0) <=> ($new->{$field} // 0));
  }
  for my $field (@{ $spec{dim} || [] }) {
    next if $skip->($field);
    push @changed, $field if _dim_key($old->{$field}) ne _dim_key($new->{$field});
  }
  for my $field (@{ $spec{array} || [] }) {
    next if $skip->($field);
    push @changed, $field if arr_differ($old->{$field}, $new->{$field});
  }

  return @changed;
}


sub changed_column_fields {
  my ($old, $new) = @_;
  return changed_fields($old, $new,
    type   => ['data_type'],
    scalar => ['not_null', 'default_value'],
    dim    => ['size'],
    desired_state => 1,
  );
}


sub changed_index_fields {
  my ($old, $new) = @_;
  return changed_fields($old, $new,
    bool  => ['is_unique'],
    array => ['columns'],
  );
}


sub changed_fk_fields {
  my ($old, $new) = @_;
  return changed_fields($old, $new,
    scalar => ['to_table', 'on_update', 'on_delete'],
    array  => ['from_columns', 'to_columns'],
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Diff::Compare - Engine-agnostic comparison helpers for DBIO diff operations

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Shared "is this the same?" comparison logic for driver diff operations.
Every DBIO driver that generates a migration diff has to answer the same
question for each candidate change -- "did this column / index / foreign key
actually change, or is it identical to what's already deployed?" -- and the
mechanics of that answer (normalize C<undef>, collapse type whitespace, compare
column lists order-independently, walk a list of fields) are identical across
engines. Only the I<set of fields> a given engine cares about is engine-specific.

This module provides the mechanism. L</changed_fields> is the generic
field-walk; L</norm>, L</norm_type> and L</arr_differ> are the primitives it is
built on and are exported for drivers that need to compose their own checks.
L</changed_column_fields>, L</changed_index_fields> and L</changed_fk_fields> are ready-made
comparators keyed to the canonical model shape documented in
L<DBIO::Introspect::Base/CANONICAL MODEL> -- a single-schema driver whose model
follows that shape can use them directly; a driver with extra attributes
(e.g. MySQL's C<column_type> / C<collation>) calls L</changed_fields> with its
own field spec instead.

Nothing here is exported by default; import what you need:

    use DBIO::Diff::Compare qw(changed_column_fields changed_fields);

=func norm

    my $s = norm($value);

Normalizes a scalar for string comparison: C<undef> becomes the empty string,
everything else is returned unchanged.

=func norm_type

    my $t = norm_type($data_type);

Normalizes a SQL type string for comparison: collapses internal whitespace to
single spaces and upper-cases the result (so C<'character  varying'> and
C<'CHARACTER VARYING'> compare equal). C<undef> becomes the empty string.
Engine-specific type I<aliasing> (e.g. C<int> vs C<integer>) is not done here --
layer it on top in the driver.

=func arr_differ

    if (arr_differ($old_cols, $new_cols)) { ... }

Order-I<independent> comparison of two array references (treated as sets).
Returns true if they differ. C<undef> and non-array values are treated as the
empty array. Use this for collections where membership matters but order does
not; for ordered collections (composite-key column lists, C<[precision, scale]>
pairs) use a C<dim> field in L</changed_fields> instead.

=func changed_fields

    my @changed = changed_fields($old, $new,
      type   => ['data_type'],
      scalar => ['default_value'],
      bool   => ['not_null'],
      dim    => ['size'],
      array  => ['columns'],
    );

The generic field-walk. C<$old> is the live/introspected side, C<$new> is the
target/desired side. Compares two info hashrefs and returns the list of field
names that differ, in declared order (deterministic). Each field is compared
according to which group it is declared in:

=over 4

=item * C<scalar> -- string comparison via L</norm> (C<undef> equals C<undef>,
but C<undef> differs from C<0>).

=item * C<type> -- SQL-type comparison via L</norm_type> (whitespace-collapsed,
case-insensitive).

=item * C<bool> -- numeric comparison with C<undef> treated as C<0>, so an
absent flag and an explicit C<0> compare equal.

=item * C<array> -- order-independent set comparison via L</arr_differ>.

=item * C<dim> -- order-I<preserving> comparison of a scalar or arrayref
(stringified), for ordered lists and C<[precision, scale]> pairs.

=back

B<Desired-state contract (always on).> Any C<scalar>/C<type>/C<dim>/C<array>
field whose value in the target C<$new> is C<undef> is skipped -- "the desired
state did not prescribe this, so leave whatever the live database reports for it
alone." This is unconditional: a portable DBIO schema does not prescribe
server-assigned attributes (charset, collation, server-default expressions),
so the target leaves them C<undef> and they must not be diffed against the live
introspect -- otherwise every upgrade emits a phantom C<ALTER>. The rule fires
B<only> when the target side is C<undef>: if both sides are set and differ it is
a real change, and if the target prescribes a value the live DB lacks
(target set, live C<undef>) it is also a real change. C<bool> fields are never
skipped (C<undef> there is a real value: C<0>).

A C<< desired_state => 1 >> key is still accepted for back-compat but is now
B<vestigial> -- the contract is always on, so passing it has no effect.

=func changed_column_fields

    my @changed = changed_column_fields($old_info, $new_info);
    if (@changed) { ... column changed ... }

Compares two column info hashrefs from the canonical model shape and returns
the list of changed field names (empty list = identical). The desired-state
contract of L</changed_fields> applies: a field the target C<$new> leaves
C<undef> is treated as "don't care". Compares C<data_type> as a type,
C<not_null> and C<default_value> as scalars, and C<size> order-preservingly
(it may be a scalar length or a C<[precision, scale]> pair).

=func changed_index_fields

    my @changed = changed_index_fields($old_info, $new_info);

Compares two index info hashrefs from the canonical model shape: C<is_unique>
(as a bool) and the C<columns> list (order-independently, matching the
historical MySQL behaviour). A driver for which index column I<order> is
significant should compare C<columns> as a C<dim> field via L</changed_fields>
instead.

=func changed_fk_fields

    my @changed = changed_fk_fields($old_info, $new_info);

Compares two foreign-key info hashrefs from the canonical model shape:
C<to_table>, C<on_update> and C<on_delete> as scalars, and the C<from_columns>
/ C<to_columns> lists order-independently.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
