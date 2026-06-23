package DBIO::SQLite::Introspect::Columns;
# ABSTRACT: Introspect SQLite columns

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $tables) = @_;
  my %columns;

  # Prefer table_xinfo (SQLite 3.26+) -- it knows about hidden/generated cols.
  my $use_xinfo = _has_xinfo($dbh);

  for my $table_name (sort keys %$tables) {
    my $pragma = $use_xinfo ? 'table_xinfo' : 'table_info';
    my $sth = $dbh->prepare(qq{PRAGMA $pragma("$table_name")});
    $sth->execute;

    my @cols;
    while (my $row = $sth->fetchrow_hashref) {
      push @cols, {
        column_name   => $row->{name},
        data_type     => $row->{type},
        not_null      => $row->{notnull} ? 1 : 0,
        default_value => $row->{dflt_value},
        is_pk         => $row->{pk} ? 1 : 0,
        pk_position   => $row->{pk} // 0,
        hidden        => $row->{hidden} // 0,
      };
    }
    $columns{$table_name} = \@cols;
  }

  return \%columns;
}

sub _has_xinfo {
  my ($dbh) = @_;
  my $ok = eval {
    $dbh->selectrow_array(q{PRAGMA table_xinfo("sqlite_master")});
    1;
  };
  return $ok ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Introspect::Columns - Introspect SQLite columns

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches column metadata via C<PRAGMA table_info()> (or C<table_xinfo>
when available, which also reports hidden/generated columns).

=head1 METHODS

=head2 fetch

    my $columns = DBIO::SQLite::Introspect::Columns->fetch($dbh, $tables);

Given the tables hashref produced by L<DBIO::SQLite::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs (in declaration order) with keys: C<column_name>,
C<data_type>, C<not_null>, C<default_value>, C<is_pk>, C<pk_position>,
C<hidden> (xinfo only).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
