package DBIO::Firebird::Introspect::Tables;
# ABSTRACT: Introspect Firebird tables and views via rdb$tables

use strict;
use warnings;



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
    };
  }

  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Introspect::Tables - Introspect Firebird tables and views via rdb$tables

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches Firebird table and view metadata via C<rdb$relations>.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::Firebird::Introspect::Tables->fetch($dbh);

Returns a hashref keyed by table name. Each value has: C<table_name>,
C<kind> (C<table> or C<view>).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
