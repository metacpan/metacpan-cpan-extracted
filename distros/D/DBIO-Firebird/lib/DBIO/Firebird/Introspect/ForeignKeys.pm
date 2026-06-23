package DBIO::Firebird::Introspect::ForeignKeys;
# ABSTRACT: Introspect Firebird foreign keys via rdb$relation_constraints

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $tables) = @_;
  my %fks;

  my $sth = $dbh->prepare(q{
    SELECT rc.rdb$constraint_name, rc.rdb$relation_name,
           ri.rdb$relation_name AS to_table,
           iseg.rdb$field_name  AS from_column,
           iseg.rdb$field_position,
           ri.rdb$foreign_key,
           refc.rdb$update_rule, refc.rdb$delete_rule, refc.rdb$match_option
    FROM rdb$relation_constraints rc
    JOIN rdb$indices ix ON rc.rdb$index_name = ix.rdb$index_name
    JOIN rdb$index_segments iseg ON ix.rdb$index_name = iseg.rdb$index_name
    JOIN rdb$indices ri ON ix.rdb$foreign_key = ri.rdb$index_name
    JOIN rdb$ref_constraints refc ON refc.rdb$constraint_name = rc.rdb$constraint_name
    WHERE rc.rdb$constraint_type = 'FOREIGN KEY'
    ORDER BY rc.rdb$relation_name, rc.rdb$constraint_name, iseg.rdb$field_position
  });
  $sth->execute;

  my %by_constraint;
  while (my $row = $sth->fetchrow_hashref) {
    my $table = $row->{'rdb$relation_name'};
    $table =~ s/\s+$//;
    my $to_table = $row->{to_table};
    $to_table =~ s/\s+$//;
    next unless exists $tables->{$table};

    my $cname = $row->{'rdb$constraint_name'};
    $cname =~ s/\s+$//;

    $by_constraint{$cname} //= {
      fk_id        => $cname,
      from_table   => $table,
      from_columns => [],
      to_table     => $to_table,
      to_columns   => [],
      on_update    => _trim($row->{'rdb$update_rule'}),
      on_delete    => _trim($row->{'rdb$delete_rule'}),
      match        => _trim($row->{'rdb$match_option'}),
    };
    my $col = $row->{from_column};
    $col =~ s/\s+$//;
    push @{ $by_constraint{$cname}{from_columns} }, $col;
  }

  # Resolve the "to" columns by looking up the referenced index segments
  for my $cname (sort keys %by_constraint) {
    my $fk = $by_constraint{$cname};
    # The referenced (parent) columns are the segments of the index the FK
    # points AT -- ix.rdb$foreign_key -- not the FK's own index (which holds
    # the local/child columns).
    my $to_sth = $dbh->prepare(q{
      SELECT iseg.rdb$field_name
      FROM rdb$index_segments iseg
      WHERE iseg.rdb$index_name = (
        SELECT ix.rdb$foreign_key
        FROM rdb$relation_constraints rc
        JOIN rdb$indices ix ON rc.rdb$index_name = ix.rdb$index_name
        WHERE rc.rdb$constraint_name = ?
          AND rc.rdb$constraint_type = 'FOREIGN KEY'
      )
      ORDER BY iseg.rdb$field_position
    });
    $to_sth->execute($cname);
    while (my ($col) = $to_sth->fetchrow_array) {
      $col =~ s/\s+$//;
      push @{ $fk->{to_columns} }, $col;
    }
    push @{ $fks{ $fk->{from_table} } }, $fk;
  }

  return \%fks;
}

# Trim trailing whitespace from a (possibly undef) CHAR-padded rdb$ value.
sub _trim {
  my ($value) = @_;
  return undef unless defined $value;
  $value =~ s/\s+$//;
  return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Introspect::ForeignKeys - Introspect Firebird foreign keys via rdb$relation_constraints

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches foreign-key metadata via C<rdb$relation_constraints> joined
against C<rdb$index_segments> and C<rdb$indices>. Composite FKs are
grouped by constraint name.

=head1 METHODS

=head2 fetch

    my $fks = DBIO::Firebird::Introspect::ForeignKeys->fetch($dbh, $tables);

Returns a hashref keyed by table name, each value an arrayref of FK
hashrefs with: C<fk_id>, C<from_columns>, C<to_table>, C<to_columns>,
C<on_update>, C<on_delete>, C<match>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
