package DBIO::Firebird::DDL;
# ABSTRACT: Generate Firebird DDL from DBIO Result classes

use strict;
use warnings;

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Firebird::Type qw(ddl_type_from_info);


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

    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = ddl_type_from_info($info);
      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;
      $def .= ' NOT NULL' if defined $info->{is_nullable} && !$info->{is_nullable};
      if (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        $def .= ref $dv eq 'SCALAR' ? " DEFAULT $$dv" : " DEFAULT '$dv'";
      }
      push @col_defs, $def;
    }

    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _quote_ident($_) } @pk_cols);
    }

    my $qualified = _quote_ident($table_name);
    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);", $qualified, join(",\n", @col_defs);

    # Unique indexes
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      if ($info->{is_unique} || $info->{is_single_unique_key}) {
        push @stmts, sprintf 'CREATE UNIQUE INDEX %s ON %s (%s);',
          _quote_ident("${table_name}_${col_name}_idx"),
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

DBIO::Firebird::DDL - Generate Firebird DDL from DBIO Result classes

=head1 VERSION

version 0.900000

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::Firebird::DDL->install_ddl($schema);

Returns the full installation DDL as a single string.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
