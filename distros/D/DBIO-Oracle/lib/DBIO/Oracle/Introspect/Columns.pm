package DBIO::Oracle::Introspect::Columns;
# ABSTRACT: Introspect Oracle columns

use strict;
use warnings;

use Try::Tiny;
use DBIO::Oracle::Type;



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;

  my %columns;
  my @table_names = sort keys %$tables;

  # Old DBD::Oracle reports size in (UTF-16) bytes, not characters
  my $nchar_size_factor = $DBD::Oracle::VERSION >= 1.52 ? 1 : 2;

  for my $table_name (@table_names) {
    my @col_list;

    my $col_sth = $dbh->prepare_cached(q{
      SELECT column_name, data_type, data_length, data_precision, data_scale,
             nullable, data_default, column_id
      FROM all_tab_columns
      WHERE table_name = ? AND owner = ?
      ORDER BY column_id
    });
    $col_sth->execute($table_name, $schema);

    while (my $row = $col_sth->fetchrow_hashref) {
      my $col = DBIO::Oracle::Type::map_dbd_type_to_dbio(
        $row->{data_type},
        data_length    => $row->{data_length},
        data_precision => $row->{data_precision},
        data_scale     => $row->{data_scale},
        nchar_size_factor => $nchar_size_factor,
      );
      $col->{column_name} = $row->{column_name};
      $col->{not_null} = (uc($row->{nullable} // 'Y') eq 'N') ? 1 : 0;

      # Handle default value
      my $default = $row->{data_default};
      if (defined $default) {
        $default =~ s/^\s+|\s+\z//g;
        if ($default eq 'NULL') {
          $col->{default_value} = \'null';
        }
        elsif ($default =~ /^'(.*)'\z/) {
          $col->{default_value} = $1;
        }
        elsif ($default =~ /^(-?[\d.]+)\z/) {
          $col->{default_value} = $1;
        }
        elsif (lc($default) eq 'sysdate') {
          my $ts = 'current_timestamp';
          $col->{default_value} = \$ts;
        }
        elsif ($default ne '') {
          $col->{default_value} = \$default;
        }
      }

      push @col_list, $col;
    }
    $col_sth->finish;

    # Detect sequences from BEFORE INSERT triggers
    my $trig_sth = $dbh->prepare_cached(q{
      SELECT trigger_body
      FROM all_triggers
      WHERE table_name = ? AND table_owner = ?
        AND status = 'ENABLED'
        AND UPPER(trigger_type) LIKE '%BEFORE EACH ROW%'
        AND LOWER(triggering_event) LIKE '%insert%'
    });
    $trig_sth->execute($table_name, $schema);

    my %seq_for_col;
    while (my ($body) = $trig_sth->fetchrow_array) {
      if (my ($seq_schema, $seq_name) = $body =~ /(?:"?(\w+)"?\.)?"?(\w+)"?\.nextval/i) {
        if (my ($col_name) = $body =~ /:new\.(\w+)/i) {
          $col_name = lc($col_name);
          $seq_schema = lc($seq_schema || $schema);
          $seq_name = lc($seq_name);
          $seq_for_col{$col_name} = "$seq_schema.$seq_name";
        }
      }
    }
    $trig_sth->finish;

    # Attach sequence info to columns
    for my $col (@col_list) {
      my $col_lc = lc($col->{column_name});
      if (my $seq = $seq_for_col{$col_lc}) {
        $col->{is_auto_increment} = 1;
        $col->{sequence} = $seq;
      }
    }

    $columns{$table_name} = \@col_list if @col_list;
  }

  return \%columns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Introspect::Columns - Introspect Oracle columns

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches Oracle column metadata via C<all_tab_columns> and C<all_triggers>.
Handles Oracle-specific data types (NUMBER, CHAR, DATE, LOB, etc.) and
detects sequences via trigger inspection.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::Oracle::Introspect::Columns->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::Oracle::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs in C<column_id> order.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
