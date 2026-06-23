package DBIO::SQLite::Diff::Index;
# ABSTRACT: Diff operations for SQLite indexes

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_fields);
use DBIO::SQL::Util qw(_quote_ident);
use namespace::clean;


__PACKAGE__->mk_diff_accessors(qw/table_name index_name index_info/);


sub diff {
  my ($class, $source, $target) = @_;

  # Index members are already keyed by name, so no index_by. scope 'all'
  # because an index drop must be emitted even for source-only tables (the
  # generic walk handles that trailing pass). _is_auto skips PK / UNIQUE
  # auto-indexes on both sides. SQLite has no ALTER INDEX, so a changed index
  # is rendered as a drop-then-create pair.
  return $class->diff_nested($source, $target,
    scope        => 'all',
    skip         => \&_is_auto,
    changed_when => sub {
      my ($src, $tgt) = @_;
      my @changed = changed_fields($src, $tgt,
        bool => ['is_unique'],
        dim  => ['columns'],
      );
      # SQLite-specific: also diff the original CREATE INDEX sql (partial
      # / expression indexes) when both sides carry it.
      if (!@changed && (defined $src->{sql} && defined $tgt->{sql})
          && $src->{sql} ne $tgt->{sql}) {
        push @changed, 'sql';
      }
      scalar @changed;
    },
    on_new => sub {
      my ($table, $name, $new) = @_;
      $class->new(
        action     => 'create',
        table_name => $table,
        index_name => $name,
        index_info => $new,
      );
    },
    on_changed => sub {
      my ($table, $name, $old, $new) = @_;
      (
        $class->new(
          action => 'drop', table_name => $table,
          index_name => $name, index_info => $old,
        ),
        $class->new(
          action => 'create', table_name => $table,
          index_name => $name, index_info => $new,
        ),
      );
    },
    on_gone => sub {
      my ($table, $name, $old) = @_;
      $class->new(
        action     => 'drop',
        table_name => $table,
        index_name => $name,
        index_info => $old,
      );
    },
  );
}

sub _is_auto {
  my ($info) = @_;
  return 0 unless defined $info->{origin};
  return $info->{origin} eq 'u' || $info->{origin} eq 'pk';
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'create') {
    if (my $sql = $self->index_info->{sql}) {
      $sql .= ';' unless $sql =~ /;\s*$/;
      return $sql;
    }
    my $unique = $self->index_info->{is_unique} ? 'UNIQUE ' : '';
    my $cols = join ', ',
      map { _quote_ident($_) } @{ $self->index_info->{columns} // [] };
    return sprintf 'CREATE %sINDEX %s ON %s (%s);',
      $unique,
      _quote_ident($self->index_name),
      _quote_ident($self->table_name),
      $cols;
  }
  return sprintf 'DROP INDEX %s;', _quote_ident($self->index_name);
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %sindex: %s on %s', $prefix, $self->index_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff::Index - Diff operations for SQLite indexes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents an index-level diff operation: C<CREATE INDEX> or
C<DROP INDEX>. SQLite has no C<ALTER INDEX>, so changed definitions
become a drop-then-create pair.

Auto-generated indexes (origin C<u> for UNIQUE constraints, C<pk> for
primary keys) are skipped -- they belong to the table itself, not to
explicit C<CREATE INDEX> statements.

=head1 METHODS

=head2 diff

    my @ops = DBIO::SQLite::Diff::Index->diff($source, $target);

C<$source> and C<$target> are the C<indexes> sub-models from
L<DBIO::SQLite::Introspect>: C<< { $table_name => { $idx_name => $info } } >>.

=head2 as_sql

Returns C<CREATE INDEX> (preferring the original C<sql> from
C<sqlite_master> if available) or C<DROP INDEX>.

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
