package DBIO::Oracle::Diff::Column;
# ABSTRACT: Diff operations for Oracle columns

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Diff::Compare qw(changed_fields);
use DBIO::Oracle::Type;

__PACKAGE__->mk_diff_accessors(qw(table_name column_name old_info new_info));


# Canonical comparison key for a column default_value. Introspection stores
# expression defaults as SCALAR refs (e.g. \'current_timestamp') and literal
# defaults as plain strings; a naive string compare stringifies the ref to
# SCALAR(0x...) and reports a phantom diff on every expression default. This
# mirrors the rendering in as_sql so comparison and emission cannot diverge.
#
# Returns undef for the "no default" cases (undef input, literal "null", or
# the \'null' expression ref), so the core's desired_state semantics still
# treat a target-undef as "don't care" and skip the field.
sub _default_key {
  my ($dv) = @_;
  return undef unless defined $dv;
  if (ref $dv eq 'SCALAR') {
    my $expr = lc $$dv;
    $expr =~ s/^\s+//;
    $expr =~ s/\s+\z//;
    return undef if $expr eq 'null';
    return $expr;
  }
  return undef if $dv eq 'null';
  return "'$dv'";
}


sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;
  my @ops;

  for my $table_name (sort keys %$target_cols) {
    next unless exists $source_tables->{$table_name}
             && exists $target_tables->{$table_name};

    my %src_by_name = map { $_->{column_name} => $_ } @{ $source_cols->{$table_name} // [] };
    my %tgt_by_name = map { $_->{column_name} => $_ } @{ $target_cols->{$table_name} // [] };

    for my $col_name (sort keys %tgt_by_name) {
      my $tgt = $tgt_by_name{$col_name};

      if (!exists $src_by_name{$col_name}) {
        push @ops, $class->new(
          action      => 'add',
          table_name  => $table_name,
          column_name => $col_name,
          new_info    => $tgt,
        );
        next;
      }

      my $src = $src_by_name{$col_name};
      my @changed = _changed_column_fields($src, $tgt);
      next unless @changed;

      push @ops, $class->new(
        action      => 'alter',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $src,
        new_info    => $tgt,
      );
    }

    for my $col_name (sort keys %src_by_name) {
      next if exists $tgt_by_name{$col_name};
      push @ops, $class->new(
        action      => 'drop',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $src_by_name{$col_name},
      );
    }
  }

  return @ops;
}

# Run the canonical changed_fields over data_type / not_null / default_value.
# Pre-normalise default_value through _default_key so SCALAR-ref expression
# defaults compare by content (the core would stringify refs to SCALAR(0x..)).
sub _changed_column_fields {
  my ($src, $tgt) = @_;
  return changed_fields(
    { %$src, default_value => _default_key($src->{default_value}) },
    { %$tgt, default_value => _default_key($tgt->{default_value}) },
    type   => ['data_type'],
    bool   => ['not_null'],
    scalar => ['default_value'],
    desired_state => 1,
  );
}


sub as_sql {
  my ($self) = @_;

  my $tbl = _quote_ident($self->table_name);
  my $col = _quote_ident($self->column_name);

  if ($self->action eq 'add') {
    my $info = $self->new_info;
    my $type = DBIO::Oracle::Type::map_dbio_type_to_oracle($info->{data_type}, size => $info->{size});
    my $sql = sprintf 'ALTER TABLE %s ADD (%s %s', $tbl, $col, $type;
    if (defined $info->{default_value}) {
      my $dv = $info->{default_value};
      if (ref $dv eq 'SCALAR') {
        $sql .= " DEFAULT $$dv";
      }
      elsif (defined $dv && $dv ne 'null') {
        $sql .= " DEFAULT '$dv'";
      }
    }
    $sql .= ' NOT NULL' if $info->{not_null};
    $sql .= ')';
    return "$sql;";
  }

  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP COLUMN %s;', $tbl, $col;
  }

  if ($self->action eq 'alter') {
    my $old = $self->old_info;
    my $new = $self->new_info;
    my @stmts;

    my @mods;
    if (DBIO::Oracle::Type::normalize_type($old->{data_type})
        ne DBIO::Oracle::Type::normalize_type($new->{data_type})) {
      push @mods, DBIO::Oracle::Type::map_dbio_type_to_oracle($new->{data_type}, size => $new->{size});
    }
    if (defined $new->{default_value}) {
      my $dv = $new->{default_value};
      if (ref $dv eq 'SCALAR') {
        push @mods, "DEFAULT $$dv";
      }
      elsif (defined $dv && $dv ne 'null') {
        push @mods, "DEFAULT '$dv'";
      }
    }
    elsif (!defined $new->{default_value} && defined $old->{default_value}) {
      push @mods, 'DEFAULT NULL';
    }
    if (($old->{not_null} // 0) != ($new->{not_null} // 0)) {
      push @mods, $new->{not_null} ? 'NOT NULL' : 'NULL';
    }

    if (@mods) {
      push @stmts, sprintf 'ALTER TABLE %s MODIFY (%s %s);',
        $tbl, $col, join(' ', @mods);
    }

    return join "\n", @stmts;
  }
}


sub summary {
  my ($self) = @_;
  my $type = $self->new_info ? " ($self->{new_info}{data_type})" : '';
  return sprintf '  %scolumn: %s.%s%s',
    $self->summary_prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Diff::Column - Diff operations for Oracle columns

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Column-level diff operations for Oracle. Oracle supports:

=over 4

=item * C<ALTER TABLE ... ADD column datatype [DEFAULT value]>

=item * C<ALTER TABLE ... DROP COLUMN column>

=item * C<ALTER TABLE ... MODIFY column datatype [DEFAULT value] [NULL|NOT NULL]>

=back

Note: Oracle does not support renaming columns via standard SQL. This class
emits ADD + DROP for rename operations.

=head1 METHODS

=head2 diff

=head2 as_sql

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
