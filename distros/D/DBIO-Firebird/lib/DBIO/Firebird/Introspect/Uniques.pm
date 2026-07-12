package DBIO::Firebird::Introspect::Uniques;
# ABSTRACT: Introspect Firebird UNIQUE constraints via rdb$relation_constraints

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $tables) = @_;

  my $sth = $dbh->prepare(q{
    SELECT rc.rdb$constraint_name, rc.rdb$relation_name,
           iseg.rdb$field_name, iseg.rdb$field_position
    FROM rdb$relation_constraints rc
    JOIN rdb$index_segments iseg ON rc.rdb$index_name = iseg.rdb$index_name
    WHERE rc.rdb$constraint_type = 'UNIQUE'
    ORDER BY rc.rdb$relation_name, rc.rdb$constraint_name, iseg.rdb$field_position
  });
  $sth->execute;

  my %by_table;
  while (my $row = $sth->fetchrow_hashref) {
    my $table = _trim($row->{'rdb$relation_name'});
    next unless exists $tables->{$table};

    my $cname = _trim($row->{'rdb$constraint_name'});
    my $col   = _trim($row->{'rdb$field_name'});

    push @{ $by_table{$table}{$cname} }, $col;
  }

  my %uniques;
  for my $table (keys %by_table) {
    $uniques{$table} = [
      map { [ $_ => $by_table{$table}{$_} ] }
      sort keys %{ $by_table{$table} }
    ];
  }

  return \%uniques;
}

# Trim trailing whitespace from a CHAR-padded rdb$ value.
sub _trim {
  my ($value) = @_;
  return $value unless defined $value;
  $value =~ s/\s+$//;
  return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Introspect::Uniques - Introspect Firebird UNIQUE constraints via rdb$relation_constraints

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches C<UNIQUE> I<constraint> metadata via C<rdb$relation_constraints>
joined against C<rdb$index_segments>. This is distinct from
L<DBIO::Firebird::Introspect::Indexes>, which deliberately excludes
constraint-backed indexes: a Firebird C<UNIQUE> constraint and a standalone
C<CREATE UNIQUE INDEX> are different objects, and only the former belongs in
the normalized C<table_uniq_info> generation contract.

=head1 METHODS

=head2 fetch

    my $uniques = DBIO::Firebird::Introspect::Uniques->fetch($dbh, $tables);

Given the tables hashref from L<DBIO::Firebird::Introspect::Tables>, returns a
hashref keyed by table name. Each value is an arrayref of
C<[ $constraint_name, \@column_names ]> pairs (columns in
C<rdb$field_position> order), sorted by constraint name.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
