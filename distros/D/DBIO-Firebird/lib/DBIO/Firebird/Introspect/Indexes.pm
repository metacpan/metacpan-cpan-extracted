package DBIO::Firebird::Introspect::Indexes;
# ABSTRACT: Introspect Firebird indexes via rdb$indices / rdb$index_segments

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $tables) = @_;
  my %indexes;

  my $sth = $dbh->prepare(q{
    SELECT i.rdb$index_name, i.rdb$relation_name, i.rdb$unique_flag,
           iseg.rdb$field_name, iseg.rdb$field_position,
           i.rdb$index_type
    FROM rdb$indices i
    JOIN rdb$index_segments iseg ON i.rdb$index_name = iseg.rdb$index_name
    WHERE i.rdb$system_flag = 0
      AND i.rdb$foreign_key IS NULL
    ORDER BY i.rdb$relation_name, i.rdb$index_name, iseg.rdb$field_position
  });
  $sth->execute;

  my %idx_info;
  while (my $row = $sth->fetchrow_hashref) {
    my $table = $row->{'rdb$relation_name'};
    $table =~ s/\s+$//;
    next unless exists $tables->{$table};

    my $name = $row->{'rdb$index_name'};
    $name =~ s/\s+$//;

    $idx_info{$name} //= {
      index_name => $name,
      table_name => $table,
      is_unique  => $row->{'rdb$unique_flag'} ? 1 : 0,
      columns    => [],
    };

    my $col = $row->{'rdb$field_name'};
    $col =~ s/\s+$//;
    push @{ $idx_info{$name}{columns} }, $col;
  }

  # Filter out PK/UNIQUE-backed indexes by checking rdb$relation_constraints
  my $constr_sth = $dbh->prepare(q{
    SELECT ix.rdb$index_name
    FROM rdb$relation_constraints rc
    JOIN rdb$indices ix ON rc.rdb$index_name = ix.rdb$index_name
    WHERE rc.rdb$constraint_type IN ('PRIMARY KEY', 'UNIQUE')
  });
  $constr_sth->execute;
  my %skip_idx;
  while (my ($idx) = $constr_sth->fetchrow_array) {
    $idx =~ s/\s+$//;
    $skip_idx{$idx} = 1;
  }

  for my $name (sort keys %idx_info) {
    next if $skip_idx{$name};
    my $info = $idx_info{$name};
    $indexes{ $info->{table_name} }{ $name } = {
      index_name => $name,
      is_unique  => $info->{is_unique},
      columns    => $info->{columns},
    };
  }

  return \%indexes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Introspect::Indexes - Introspect Firebird indexes via rdb$indices / rdb$index_segments

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches index metadata via C<rdb$indices> joined against C<rdb$index_segments>.
Primary-key and unique-constraint indexes are filtered out -- they belong
to the table definition, not explicit CREATE INDEX.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::Firebird::Introspect::Indexes->fetch($dbh, $tables);

Returns a hashref keyed by table name, each value a hashref keyed by
index name with: C<index_name>, C<is_unique>, C<columns> (arrayref).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
