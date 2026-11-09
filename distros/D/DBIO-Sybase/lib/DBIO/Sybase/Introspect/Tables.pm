package DBIO::Sybase::Introspect::Tables;
# ABSTRACT: Introspect Sybase ASE tables and views

use strict;
use warnings;

our $VERSION = '0.900004';



sub fetch {
  my ($class, $dbh, $schema) = @_;
  $schema //= 'dbo';

  my $rows = $dbh->selectall_arrayref(q{
    SELECT o.name AS table_name, o.type AS object_type
    FROM sysobjects o
    JOIN sysusers   u ON u.uid = o.uid
    WHERE o.type IN ('U', 'V')
      AND u.name = ?
      AND o.name <> 'sysquerymetrics'
    ORDER BY o.name
  }, { Slice => {} }, $schema);

  my %tables;
  for my $row (@$rows) {
    # sysobjects.type is char(2): 'U ' / 'V '.
    (my $type = $row->{object_type} // '') =~ s/\s+//g;
    $tables{ $row->{table_name} } = {
      table_name => $row->{table_name},
      kind       => $type eq 'V' ? 'view' : 'table',
      schema     => $schema,
    };
  }

  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Introspect::Tables - Introspect Sybase ASE tables and views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches Sybase ASE table and view metadata from the system catalog
(C<sysobjects> type C<U> / C<V>, joined to C<sysusers> for the owner). SAP ASE
has no C<INFORMATION_SCHEMA> views. System tables are type C<S> and
never match; the one system B<view> ASE installs into every database,
C<sysquerymetrics> (owned by C<dbo>), is excluded by name.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::Sybase::Introspect::Tables->fetch($dbh, $schema);

Returns a hashref keyed by table name. Each value has: C<table_name>,
C<kind> (C<table> or C<view>), C<schema>. C<$schema> is the owner name
(default C<dbo>).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
