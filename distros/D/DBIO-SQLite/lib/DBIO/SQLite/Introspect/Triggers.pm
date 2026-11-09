package DBIO::SQLite::Introspect::Triggers;
# ABSTRACT: Introspect SQLite triggers

use strict;
use warnings;

our $VERSION = '0.900004';



sub fetch {
  my ($class, $dbh, $tables) = @_;

  # SQLite matches a name whatever its letter case.
  my %table_name = map { lc $_ => $_ } keys %$tables;

  my $rows = $dbh->selectall_arrayref(
    q{SELECT name, tbl_name, sql FROM sqlite_master WHERE type = 'trigger'},
    { Slice => {} },
  );

  my %triggers;
  for my $row (@$rows) {
    my $table = $table_name{ lc $row->{tbl_name} } // next;
    $triggers{$table}{ $row->{name} } = {
      trigger_name => $row->{name},
      table_name   => $table,
      sql          => $row->{sql},
    };
  }

  return \%triggers;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Introspect::Triggers - Introspect SQLite triggers

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches the triggers of a database from C<sqlite_master>, each with the
statement it was created by.

The model carries them so that an operation that removes a table and puts it
back can put its triggers back as well -- SQLite drops a table's triggers with
the table, and L<DBIO::SQLite::Diff::Rebuild> is such an operation. They are
B<not compared>: L<DBIO::SQLite::DDL/install_ddl> has no way to declare a
trigger, so the model of a schema never holds one, and a diff that compared
them would drop every trigger a database has.

=head1 METHODS

=head2 fetch

    my $triggers = DBIO::SQLite::Introspect::Triggers->fetch($dbh, $tables);

Given the tables hashref produced by L<DBIO::SQLite::Introspect::Tables>,
returns a hashref keyed by the name of the table or view a trigger is on --
a view for an C<INSTEAD OF> trigger. Each value is a hashref keyed by trigger
name. Each trigger entry has: C<trigger_name>, C<table_name>, C<sql> (the
C<CREATE TRIGGER> statement from C<sqlite_master>, without a closing
semicolon). A table without triggers has no entry.

C<table_name>, and the key, is the name the table has in C<$tables>.
C<sqlite_master> itself holds the name as the trigger's statement spells it:
C<CREATE TRIGGER ... ON item> for a table created as C<Item> is listed under
C<item> there, and under C<Item> here.

Only C<sqlite_master> is read. A C<TEMP> trigger lives in
C<sqlite_temp_master>, belongs to the connection that created it and is not in
the model. A trigger on something that is not in C<$tables> -- a shadow table
of a virtual table -- is left out with it.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
