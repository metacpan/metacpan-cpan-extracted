package DBIO::Oracle::DDL;
# ABSTRACT: Generate Oracle DDL from DBIO Result classes

use strict;
use warnings;

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Oracle::Type;
use DBIO::Oracle::Identifier;



sub install_ddl {
  my ($class, $schema) = @_;
  my @stmts;
  my @view_stmts;
  my %seen_table;
  my %seen_view;

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    my $table_name = $source->name;

    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = ref $table_name eq 'SCALAR' ? $$table_name : $table_name;
      next if ref $vname || $seen_view{$vname}++;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      push @view_stmts, sprintf 'CREATE VIEW %s AS %s;', _quote_ident($vname), $def;
      next;
    }

    # A scalar-ref name is either a literal table name (\'cd', emitted
    # unquoted) or an inline subquery source; deref the former, skip the latter.
    if (ref $table_name eq 'SCALAR') {
      $table_name = $$table_name;
      next if $table_name =~ /\s|\(/;
    }
    next if ref $table_name;

    # Several result sources can map to one physical table; emit it once.
    next if $seen_table{$table_name}++;

    # Detect autoincrement columns
    my @autoinc_cols;
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      push @autoinc_cols, $col_name if $info->{is_auto_increment};
    }

    # Column definitions
    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = DBIO::Oracle::Type::map_dbio_type_to_oracle($info->{data_type}, size => $info->{size});
      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;

      if ($info->{is_auto_increment}) {
        # SERIAL/BIGSERIAL mapped to NUMBER + sequence (type already set)
      }

      $def .= ' NOT NULL' if defined $info->{is_nullable} && !$info->{is_nullable};

      if (defined $info->{default_value} && !$info->{is_auto_increment}) {
        my $dv = $info->{default_value};
        if (ref $dv eq 'SCALAR') {
          $def .= " DEFAULT $$dv";
        }
        else {
          $def .= " DEFAULT '$dv'";
        }
      }

      push @col_defs, $def;
    }

    # Primary key constraint
    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _quote_ident($_) } @pk_cols);
    }

    my $qualified = _quote_ident($table_name);
    my $sql = sprintf "CREATE TABLE %s (\n%s\n);", $qualified, join(",\n", @col_defs);
    push @stmts, $sql;

    # Sequences for autoincrement columns
    for my $col_name (@autoinc_cols) {
      my $seq_name = DBIO::Oracle::Identifier::shorten("${table_name}_${col_name}_seq");
      push @stmts, sprintf "CREATE SEQUENCE %s;", _quote_ident($seq_name);
    }

    # Indexes for unique constraints
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      if ($info->{is_unique} || $info->{is_single_unique_key}) {
        push @stmts, sprintf 'CREATE UNIQUE INDEX %s ON %s (%s);',
          _quote_ident(DBIO::Oracle::Identifier::shorten("${table_name}_${col_name}_idx")),
          $qualified,
          _quote_ident($col_name);
      }
    }
  }

  return join "

", @stmts, @view_stmts;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::DDL - Generate Oracle DDL from DBIO Result classes

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::Oracle::DDL> generates Oracle DDL from the DBIO schema class hierarchy.
It is the desired-state side of the test-deploy-and-compare strategy used by
L<DBIO::Oracle::Deploy>.

    my $ddl = DBIO::Oracle::DDL->install_ddl($schema);
    # CREATE TABLE ...; CREATE SEQUENCE ...; CREATE INDEX ...;

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::Oracle::DDL->install_ddl($schema);

Returns the full installation DDL as a single string. C<$schema> may be
a connected schema instance or a schema class name.

=seealso

=over

=item * L<DBIO::Oracle> - schema component

=item * L<DBIO::Oracle::Deploy> - uses this to generate DDL for deployment

=item * L<DBIO::PostgreSQL::DDL> - reference implementation

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
