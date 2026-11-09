package DBIO::Firebird::Introspect::Tables;
# ABSTRACT: Introspect Firebird tables and views via rdb$relations

use strict;
use warnings;

our $VERSION = '0.900004';



sub fetch {
  my ($class, $dbh) = @_;

  my $sth = $dbh->prepare(q{
    SELECT rdb$relation_name, rdb$view_source
    FROM rdb$relations
    WHERE rdb$system_flag = 0
      AND rdb$relation_type IN (0, 1)
    ORDER BY rdb$relation_name
  });
  $sth->execute;

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $name = $row->{'rdb$relation_name'};
    $name =~ s/\s+$//;
    my $kind = defined $row->{'rdb$view_source'} ? 'view' : 'table';
    $tables{$name} = {
      table_name => $name,
      kind       => $kind,
      ( $kind eq 'view' ? ( view_source => "$row->{'rdb$view_source'}" ) : () ),
    };
  }

  my $pk = $dbh->prepare(q{
    SELECT rdb$relation_name, rdb$constraint_name
    FROM rdb$relation_constraints
    WHERE rdb$constraint_type = 'PRIMARY KEY'
  });
  $pk->execute;
  while (my $row = $pk->fetchrow_hashref) {
    my ($table, $name) = map { my $v = $row->{$_}; $v =~ s/\s+$//; $v }
      'rdb$relation_name', 'rdb$constraint_name';
    $tables{$table}{primary_key_name} = $name if exists $tables{$table};
  }

  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Introspect::Tables - Introspect Firebird tables and views via rdb$relations

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches Firebird table and view metadata via C<rdb$relations>.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::Firebird::Introspect::Tables->fetch($dbh);

Returns a hashref keyed by table name. Each value has: C<table_name>,
C<kind> (C<table> or C<view>) and, for a view, C<view_source>, the text of
C<rdb$relations.rdb$view_source> as the server holds it (the query after
C<AS>, no trailing semicolon). A table with a primary key has its
constraint name as C<primary_key_name> (C<INTEG_E<lt>nE<gt>> unless it was
named), which the diff needs to drop the key.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
