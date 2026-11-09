package DBIO::SQLite::Introspect::Columns;
# ABSTRACT: Introspect SQLite columns

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::SQLite::Util qw(
  column_is_nullable pk_is_rowid_alias quote_identifier split_type_size
);



sub fetch {
  my ($class, $dbh, $tables) = @_;
  my %columns;

  # Prefer table_xinfo (SQLite 3.26+) -- it knows about hidden/generated cols.
  my $use_xinfo = _has_xinfo($dbh);

  for my $table_name (sort keys %$tables) {
    my $pragma = $use_xinfo ? 'table_xinfo' : 'table_info';
    my $sth = $dbh->prepare(
      sprintf 'PRAGMA %s(%s)', $pragma, quote_identifier($table_name));
    $sth->execute;

    my @cols;
    while (my $row = $sth->fetchrow_hashref) {
      my ($type, $size) = split_type_size($row->{type});
      push @cols, {
        column_name   => $row->{name},
        data_type     => $type,
        (defined $size ? (size => $size) : ()),
        not_null      => $row->{notnull} ? 1 : 0,
        default_value => $row->{dflt_value},
        is_pk         => $row->{pk} ? 1 : 0,
        pk_position   => $row->{pk} // 0,
        hidden        => $row->{hidden} // 0,
      };
    }

    # The extra PRAGMA is only worth running where the answer can change
    # anything: a table with no key column has no alias to find.
    my $alias = (grep { $_->{is_pk} } @cols)
      ? pk_is_rowid_alias($dbh, $table_name)
      : 0;
    $_->{not_null} = column_is_nullable($_->{not_null}, $_->{is_pk}, $alias) ? 0 : 1
      for @cols;

    # The rowid alias assigns its own keys: that is what is_auto_increment
    # says, whether or not the AUTOINCREMENT keyword is there (it is not,
    # ADR 0004). Only the single-column key of declared type INTEGER on a
    # rowid table qualifies; a composite key, INT, or WITHOUT ROWID does not.
    if ($alias) {
      my @pk = grep { $_->{is_pk} } @cols;
      $pk[0]{is_auto_increment} = 1
        if @pk == 1 && uc($pk[0]{data_type} // '') eq 'INTEGER';
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

version 0.900004

=head1 DESCRIPTION

Fetches column metadata via C<PRAGMA table_info()> (or C<table_xinfo>
when available, which also reports hidden/generated columns).

=head1 METHODS

=head2 fetch

    my $columns = DBIO::SQLite::Introspect::Columns->fetch($dbh, $tables);

Given the tables hashref produced by L<DBIO::SQLite::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs (in declaration order) with keys: C<column_name>,
C<data_type>, C<size> (present only on a column whose declared type has one),
C<not_null>, C<default_value>, C<is_pk>, C<pk_position>, C<hidden> (xinfo
only), and C<is_auto_increment> (1, present only on the column that has it).

The size of a column is read out of its declared type, which is where SQLite
keeps it: C<CHARACTER(10)> is C<data_type> C<CHARACTER> with C<size> 10,
C<NUMERIC(10, 2)> is C<NUMERIC> with C<[ 10, 2 ]>
(L<DBIO::SQLite::Util/split_type_size>). A type without a size, or with
something else in the parentheses, is C<data_type> as declared and has no
C<size>.

C<is_auto_increment> is set for the B<rowid alias> and nothing else: the
single primary key column of a rowid table whose declared type is exactly
C<INTEGER>. That column assigns its own keys with or without the
C<AUTOINCREMENT> keyword, which the DDL does not write (ADR 0004); the
keyword only adds the never-reuse guarantee and is not what is reported. A
composite key, an C<INT> key and a C<WITHOUT ROWID> table do not assign keys
and carry no such key.

C<not_null> is the negation of L<DBIO::SQLite::Util/column_is_nullable>, the
single nullability rule this driver has, and not the raw C<notnull> flag of
the C<PRAGMA>. The two differ for exactly one column shape, the B<rowid alias>
(C<INTEGER PRIMARY KEY> on a rowid table): it cannot hold NULL whatever it was
declared as, because there C<NULL> is the "assign a rowid" input token rather
than a value that gets stored. The C<PRAGMA> reports the declaration, so the
same alias reads C<notnull = 0> written one way and C<notnull = 1> written the
other -- and a model that passed that difference on made two spellings of one
table look like two different tables. Every other column keeps the
C<PRAGMA>'s answer unchanged, including a non-alias key column that really can
hold NULL.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
