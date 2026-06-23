package DBIO::Oracle::Introspect::Keys;
# ABSTRACT: Introspect Oracle primary key and unique constraints

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;

  my %primary;
  my %unique;

  my $sth = $dbh->prepare_cached(q{
    SELECT c.constraint_name, c.constraint_type, c.table_name,
           cc.column_name, cc.position
    FROM all_constraints c
    JOIN all_cons_columns cc
      ON c.constraint_name = cc.constraint_name
     AND c.owner = cc.owner
    WHERE c.owner = ?
      AND c.constraint_type IN ('P', 'U')
      AND c.table_name NOT LIKE 'BIN$%'
    ORDER BY c.table_name, c.constraint_type, c.constraint_name, cc.position
  });
  $sth->execute($schema);

  my %pk_cols;       # table => [cols] in position order
  my %uniq_cols;     # table => { constraint => [cols] }

  while (my $row = $sth->fetchrow_hashref) {
    my $tbl = $row->{table_name};
    next unless exists $tables->{$tbl};

    if ($row->{constraint_type} eq 'P') {
      push @{ $pk_cols{$tbl} }, $row->{column_name};
    }
    else {
      push @{ $uniq_cols{$tbl}{ $row->{constraint_name} } }, $row->{column_name};
    }
  }
  $sth->finish;

  for my $tbl (keys %$tables) {
    $primary{$tbl} = $pk_cols{$tbl} // [];

    my $by_name = $uniq_cols{$tbl} // {};
    $unique{$tbl} = [ map { [ $_ => $by_name->{$_} ] } sort keys %$by_name ];
  }

  return {
    primary => \%primary,
    unique  => \%unique,
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Introspect::Keys - Introspect Oracle primary key and unique constraints

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches Oracle primary key (C<P>) and unique (C<U>) constraint metadata via
C<all_constraints> and C<all_cons_columns>. The L<DBIO::Oracle::Introspect::Indexes>
submodule deliberately excludes constraint-backed indexes, so this module is
the source of primary/unique key information for the normalized generation
contract in L<DBIO::Introspect::Base>.

=head1 METHODS

=head2 fetch

    my $keys = DBIO::Oracle::Introspect::Keys->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::Oracle::Introspect::Tables>, returns a
hashref:

    {
        primary => { $table => [ @ordered_pk_columns ] },
        unique  => { $table => [ [ $constraint_name, [ @columns ] ], ... ] },
    }

Both sub-hashes contain an entry for every known table (empty arrayref when
the table has no such constraint).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
