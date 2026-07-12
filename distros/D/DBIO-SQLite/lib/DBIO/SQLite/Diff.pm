package DBIO::SQLite::Diff;
# ABSTRACT: Compare two introspected SQLite models

use strict;
use warnings;

use base 'DBIO::Diff::Base';

use DBIO::SQLite::Diff::Table;
use DBIO::SQLite::Diff::Column;
use DBIO::SQLite::Diff::Index;
use DBIO::SQLite::Diff::Rebuild;



sub target_from_compiled {
  my ($class, $compiled) = @_;
  my (%tables, %columns);
  for my $tname (keys %{ $compiled->{tables} // {} }) {
    my $t = $compiled->{tables}{$tname};
    $tables{$tname} = { table_name => $tname };
    my @cols;
    for my $c (@{ $t->{columns} // [] }) {
      my $not_null = $c->{not_null} ? 1 : 0;
      $not_null = 0 if $c->{is_pk};            # SQLite reports PK columns as notnull=0
      push @cols, {
        column_name   => $c->{column_name},
        data_type     => $c->{native_type},
        not_null      => $not_null,
        default_value => $c->{default},
        is_pk         => ($c->{is_pk} ? 1 : 0),
        pk_position   => 0,
      };
    }
    $columns{$tname} = \@cols;
  }
  return { tables => \%tables, columns => \%columns, indexes => {}, foreign_keys => {} };
}

sub _build_operations {
  my ($self) = @_;
  my @ops;

  push @ops, DBIO::SQLite::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns}, $self->target->{foreign_keys},
  );

  my @col_ops = DBIO::SQLite::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );

  # SQLite cannot ALTER a column's type / nullability / default in place. A
  # table carrying any such change must be rebuilt wholesale (create-new /
  # copy / drop / rename), which also subsumes that table's add / drop column
  # ops. We can only rebuild faithfully when the target table's original
  # CREATE statement is available (the introspect path provides it; the
  # compiled-model path does not) -- otherwise the per-column ops stand and
  # render their explanatory comment.
  my %needs_rebuild;
  for my $op (grep { $_->action eq 'alter' } @col_ops) {
    my $table = $op->table_name;
    my $tinfo = $self->target->{tables}{$table};
    $needs_rebuild{$table} = 1 if $tinfo && $tinfo->{sql};
  }

  push @ops, grep { !$needs_rebuild{ $_->table_name } } @col_ops;

  for my $table (sort keys %needs_rebuild) {
    my %src_names = map { $_->{column_name} => 1 }
      @{ $self->source->{columns}{$table} // [] };
    my @copy = grep { $src_names{$_} }
      map { $_->{column_name} } @{ $self->target->{columns}{$table} // [] };

    push @ops, DBIO::SQLite::Diff::Rebuild->new(
      table_name   => $table,
      table_sql    => $self->target->{tables}{$table}{sql},
      copy_columns => \@copy,
    );

    # The rebuild drops the table and with it every index; re-create the
    # table's explicit (non-auto) target indexes afterwards.
    my $tgt_idx = $self->target->{indexes}{$table} // {};
    for my $name (sort keys %$tgt_idx) {
      my $info = $tgt_idx->{$name};
      next if DBIO::SQLite::Diff::Index::_is_auto($info);
      push @ops, DBIO::SQLite::Diff::Index->new(
        action     => 'create',
        table_name => $table,
        index_name => $name,
        index_info => $info,
      );
    }
  }

  # Normal index diff for every table that is NOT being rebuilt (rebuilt
  # tables' indexes are handled above). The full tables sections are threaded
  # through so Diff::Index can suppress a standalone DROP INDEX for any index
  # whose owning table is itself being dropped this pass -- SQLite's DROP TABLE
  # already removes those indexes (karr #14).
  my %src_idx = %{ $self->source->{indexes} // {} };
  my %tgt_idx = %{ $self->target->{indexes} // {} };
  delete @src_idx{ keys %needs_rebuild };
  delete @tgt_idx{ keys %needs_rebuild };
  push @ops, DBIO::SQLite::Diff::Index->diff(
    \%src_idx, \%tgt_idx,
    $self->source->{tables}, $self->target->{tables},
  );

  return \@ops;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff - Compare two introspected SQLite models

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::SQLite::Diff> compares two introspected SQLite database models
(as produced by L<DBIO::SQLite::Introspect>) and produces a list of
structured diff operations. These operations can then be rendered to SQL
or a human-readable summary.

    my $diff = DBIO::SQLite::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in dependency order: tables first (so new tables
exist before columns/indexes reference them), then columns, then
indexes. Drop ops come last for each layer.

=head1 METHODS

=head2 target_from_compiled

    my $target = DBIO::SQLite::Diff->target_from_compiled($compiled_model);

Translates the neutral model from L<DBIO::Schema::ModelCompiler> into the
SQLite introspect-shaped model that C<diff> consumes: native types land in
C<data_type>, and primary-key columns are reported as nullable to match how
SQLite's C<PRAGMA table_info> reports them (PK columns are notnull=0 unless
explicitly declared NOT NULL).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
