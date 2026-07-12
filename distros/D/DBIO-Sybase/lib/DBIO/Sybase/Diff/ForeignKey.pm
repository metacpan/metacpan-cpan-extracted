package DBIO::Sybase::Diff::ForeignKey;
# ABSTRACT: Diff Sybase ASE foreign keys

use strict;
use warnings;

use DBIO::Diff::Compare qw(changed_fk_fields);
use DBIO::SQL::Util ();


# Stable identity for a per-constraint FK entry: the relationship tuple.
# on_update / on_delete are attributes, not identity.
sub _fk_key {
  my ($fk) = @_;
  return join "\0",
    join(',', @{ $fk->{from_columns} // [] }),
    ($fk->{to_table} // ''),
    join(',', @{ $fk->{to_columns} // [] });
}

# Constraint name to emit for an FK entry. Prefers the real, server-assigned
# name carried on the entry (present on source/introspected entries, absent on
# desired/target entries), so DROP/ALTER target a foreign key by its actual
# name even when it was created out-of-band. Falls back to a deterministic name
# derived from the relationship tuple when no live name is present (every
# CREATE, plus any DROP whose source entry lacks a name).
sub _fk_name {
  my ($table, $fk) = @_;
  return $fk->{constraint_name}
    if defined $fk->{constraint_name} && length $fk->{constraint_name};
  return sprintf 'fk_%s_%s', $table, join('_', @{ $fk->{from_columns} // [] });
}

sub diff {
  my ($class, $source, $target) = @_;
  $source //= {};
  $target //= {};
  my @ops;

  # FK adds (and the create half of an alter) go in the target's tables.
  for my $table (sort keys %$target) {
    # Tables present only in the target are created (with their FKs) elsewhere.
    next unless exists $source->{$table};

    my %s_idx = map { _fk_key($_) => $_ } @{ $source->{$table} // [] };
    my %t_idx = map { _fk_key($_) => $_ } @{ $target->{$table} // [] };

    for my $key (sort keys %t_idx) {
      if (exists $s_idx{$key}) {
        # Same relationship, possibly different ON UPDATE/DELETE: drop+create.
        push @ops,
          DBIO::Sybase::Diff::ForeignKey::Drop->new(
            action => 'drop', table => $table, fk => $s_idx{$key},
          ),
          DBIO::Sybase::Diff::ForeignKey::Create->new(
            action => 'create', table => $table, fk => $t_idx{$key},
          )
          if changed_fk_fields($s_idx{$key}, $t_idx{$key});
      }
      else {
        push @ops, DBIO::Sybase::Diff::ForeignKey::Create->new(
          action => 'create', table => $table, fk => $t_idx{$key},
        );
      }
    }

    for my $key (sort keys %s_idx) {
      push @ops, DBIO::Sybase::Diff::ForeignKey::Drop->new(
        action => 'drop', table => $table, fk => $s_idx{$key},
      ) unless exists $t_idx{$key};
    }
  }

  return @ops;
}

package DBIO::Sybase::Diff::ForeignKey::Create;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table fk));

sub as_sql {
  my $self = shift;
  my $fk   = $self->fk;
  my $tbl  = DBIO::SQL::Util::_quote_ident($self->table);
  my $name = DBIO::SQL::Util::_quote_ident(
    DBIO::Sybase::Diff::ForeignKey::_fk_name($self->table, $fk));
  my $from = join ', ', map { DBIO::SQL::Util::_quote_ident($_) } @{ $fk->{from_columns} };
  my $to   = join ', ', map { DBIO::SQL::Util::_quote_ident($_) } @{ $fk->{to_columns} };
  my $ref  = DBIO::SQL::Util::_quote_ident($fk->{to_table});

  my $sql = sprintf
    'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s (%s)',
    $tbl, $name, $from, $ref, $to;
  $sql .= " ON UPDATE $fk->{on_update}"
    if $fk->{on_update} && uc($fk->{on_update}) ne 'NO ACTION';
  $sql .= " ON DELETE $fk->{on_delete}"
    if $fk->{on_delete} && uc($fk->{on_delete}) ne 'NO ACTION';
  return $sql;
}
sub summary {
  my $self = shift;
  'ADD FK ' . DBIO::Sybase::Diff::ForeignKey::_fk_name($self->table, $self->fk)
    . ' ON ' . $self->table;
}

package DBIO::Sybase::Diff::ForeignKey::Drop;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table fk));

sub as_sql {
  my $self = shift;
  my $tbl  = DBIO::SQL::Util::_quote_ident($self->table);
  my $name = DBIO::SQL::Util::_quote_ident(
    DBIO::Sybase::Diff::ForeignKey::_fk_name($self->table, $self->fk));
  return "ALTER TABLE $tbl DROP CONSTRAINT $name";
}
sub summary {
  my $self = shift;
  'DROP FK ' . DBIO::Sybase::Diff::ForeignKey::_fk_name($self->table, $self->fk)
    . ' ON ' . $self->table;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Diff::ForeignKey - Diff Sybase ASE foreign keys

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Compares two foreign-key sets and generates FK-level diff operations for
tables that exist on both sides. FKs on a brand-new table are the table's
own concern; FKs on a dropped table vanish with it. This module only
reconciles FK changes on tables retained across the diff.

The introspected per-constraint FK shape (produced by
L<DBIO::Sybase::Introspect/_group_fks_by_constraint>) is
C<{ constraint_name, from_columns, to_table, to_columns, on_update,
on_delete }>. FK identity here is the relationship tuple
C<< from_columns -> to_table(to_columns) >> (B<not> the name, since the
desired/target model built from a schema definition has no live name); the
alterable attributes are C<on_update> / C<on_delete>.

C<DROP> (and the drop-half of an alter) prefers the B<real, server-assigned>
C<constraint_name> carried on the source (live/introspected) entry, so a
foreign key created out-of-band under any name is dropped by its actual name.
C<CREATE> (and the create-half of an alter) targets the desired model, which
has no live name, so it falls back to a B<deterministic generated> name
derived from the relationship tuple (C<fk_E<lt>tableE<gt>_E<lt>colsE<gt>>,
the same approach the DDL emitter uses for unnamed unique indexes). When the
source entry also lacks a name, C<DROP> falls back to the same generated name.

Sybase ASE cannot alter an FK constraint in place, so an attribute change
becomes a drop-then-add pair.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
