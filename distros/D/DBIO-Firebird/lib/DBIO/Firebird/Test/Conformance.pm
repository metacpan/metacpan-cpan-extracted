package DBIO::Firebird::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the Firebird driver

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::Conformance';

use DBIO::Exception ();
use DBIO::Firebird::Deploy ();
use DBIO::Firebird::DDL ();
use DBIO::Firebird::Introspect ();



sub conformance_live_available {
  return 0 unless length($ENV{DBIO_TEST_FIREBIRD_DSN} // '');
  return eval { require DBD::Firebird; 1 } ? 1 : 0;
}


sub conformance_connect {
  my ($class, $schema_class) = @_;
  $schema_class->load_components('Firebird');
  return $schema_class->connect(
    @ENV{qw(DBIO_TEST_FIREBIRD_DSN DBIO_TEST_FIREBIRD_USER DBIO_TEST_FIREBIRD_PASS)},
    { quote_names => 1, on_connect_call => [ 'use_softcommit' ],
      AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0,
      LongReadLen => 1_000_000 },
  );
}

# A connection of the conformance run's own, apart from the case's.
sub _own_dbh {
  require DBI;
  return DBI->connect(
    @ENV{qw(DBIO_TEST_FIREBIRD_DSN DBIO_TEST_FIREBIRD_USER DBIO_TEST_FIREBIRD_PASS)},
    { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1,
      ib_dialect => 3 },
  );
}

sub _trim { my ($s) = @_; $s =~ s/\s+\z// if defined $s; return $s }

# [ [ name, 'TABLE' | 'VIEW' ], ... ] of the user relations
sub _relations {
  my ($dbh) = @_;
  my $rows = $dbh->selectall_arrayref(
    'SELECT rdb$relation_name, rdb$view_blr FROM rdb$relations '
    . 'WHERE COALESCE(rdb$system_flag, 0) = 0');
  return [ map { [ _trim($_->[0]), defined $_->[1] ? 'VIEW' : 'TABLE' ] } @$rows ];
}


sub conformance_namespace {
  my ($class, $schema, $case) = @_;
  my $dbh = _own_dbh();
  my $there = eval { _relations($dbh) };
  my $err = $@;
  $dbh->disconnect;
  DBIO::Exception->throw("conformance: cannot look at the database: $err") if $err;
  DBIO::Exception->throw('conformance: the database holds '
    . join(', ', map { "$_->[1] $_->[0]" } @$there)
    . ' already; a case needs an empty database and it is not the run\'s to drop them')
    if @$there;

  my (%tables, %views);
  for my $source_name ($schema->sources) {
    my $source = $schema->source($source_name);
    my $name   = $source->name;
    next if ref $name;
    if ($source->isa('DBIO::ResultSource::View')) { $views{$name} = 1 }
    else                                          { $tables{$name} = 1 }
  }
  # A Diff case upgrades to a second declaration, whose sources create more
  # objects: the cleanup has to find them as well.
  for my $spec (@{ $case->{input}{to}{sources} || [] }) {
    next if !defined $spec->{table} or ref $spec->{table};
    if ($spec->{view}) { $views{ $spec->{table} } = 1 }
    else               { $tables{ $spec->{table} } = 1 }
  }
  return { tables => [ sort keys %tables ], views => [ sort keys %views ] };
}


sub conformance_install {
  my ($class, $schema, $case) = @_;
  $schema->deploy;
  return;
}


sub conformance_cleanup {
  my ($class, $schema, $case, $namespace) = @_;
  eval { $schema->storage->disconnect };

  return unless ref $namespace eq 'HASH';
  my %want_table = map { $_ => 1 } @{ $namespace->{tables} || [] };
  my %want_view  = map { $_ => 1 } @{ $namespace->{views}  || [] };
  return unless %want_table or %want_view;

  my $dbh = _own_dbh();
  my $ok = eval {
    my @rel    = @{ _relations($dbh) };
    my @views  = grep { $_->[1] eq 'VIEW'  and $want_view{ $_->[0] } }  @rel;
    my @tables = grep { $_->[1] eq 'TABLE' and $want_table{ $_->[0] } } @rel;

    my $fks = $dbh->selectall_arrayref(
      'SELECT rdb$relation_name, rdb$constraint_name FROM rdb$relation_constraints '
      . q{WHERE rdb$constraint_type = 'FOREIGN KEY'});
    for my $fk (@$fks) {
      my ($table, $constraint) = map { _trim($_) } @$fk;
      next unless $want_table{$table};
      $dbh->do(sprintf 'ALTER TABLE %s DROP CONSTRAINT %s',
        map { DBIO::Firebird::DDL::_firebird_quote_ident($_) } $table, $constraint);
    }
    $dbh->do('DROP VIEW ' . DBIO::Firebird::DDL::_firebird_quote_ident($_->[0]))
      for @views;
    $dbh->do('DROP TABLE ' . DBIO::Firebird::DDL::_firebird_quote_ident($_->[0]))
      for @tables;
    1;
  };
  my $err = $@;
  $dbh->disconnect;
  DBIO::Exception->throw("conformance: cleanup failed: $err") unless $ok;
  return;
}


sub conformance_diff_is_empty {
  my ($class, $schema, $case) = @_;
  my $diff = DBIO::Firebird::Deploy->new(schema => $schema)->diff;
  return $diff->has_changes ? 0 : 1;
}


sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  # The case's own connection holds a transaction and statements on its
  # tables; the DDL of the upgrade and the DROP TABLE of the cleanup (each on
  # a connection of their own) wait for them for ever. Nothing reads through
  # the old schema once the upgrade starts.
  eval { $schema->storage->disconnect };
  my $to = $class->conformance_connect($to_class);
  DBIO::Firebird::Deploy->new(schema => $to)->upgrade(allow_destructive => 1);
  eval { $to->storage->disconnect };
  return $to;
}


sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  eval { $schema->storage->disconnect };
  my $to = $class->conformance_connect($to_class);
  return DBIO::Firebird::Deploy->new(schema => $to);
}


sub conformance_answered_through { { DDL => 2, Diff => 4, Bind => 1 } }


sub conformance_refusals {
  return {
  'diff-column-added-not-null-populated' => {
    kind   => 'server',
    reason => qr/added NOT NULL without a default, and the table holds rows/,
  },
  'diff-not-null-over-nulls' => {
    kind   => 'server',
    reason => qr/becomes NOT NULL, and the table holds rows where it is NULL/,
  },
  'bind-long-string' => {
    kind   => 'server',
    reason => qr/compared as a VARCHAR, which holds 8191 characters at most \(32765 bytes/,
  },
  'bind-numeric-exact' => {
    kind   => 'server',
    reason => qr/more than 18 digits is an INT128.*cannot bind or read an INT128/s,
  },
  'ddl-type-size-bit' => {
    kind   => 'server',
    reason => qr/no type for a bit string of a fixed width/,
  },
  'ddl-enum-value-apostrophe' => {
    kind   => 'server',
    reason => qr/no enumerated type/,
  },
  'ddl-qualified-source-name' => {
    kind   => 'server',
    reason => qr/no schemas before version 6/,
  },
  'ddl-default-digit-string' => {
    kind   => 'deviation',
    fact   => qr/expected '007', read back '007  '/,
    reason => 'Firebird pads a CHAR(n) value with blanks to its length; that is the type\'s definition and the driver does not trim',
  },
  };
}


sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  my $table = $args->{table};
  my $dbh   = $schema->storage->dbh;

  # Firebird has no schemas: no table is in any namespace but the database's
  return 0 if $name eq 'table_in_namespace';

  my $model   = DBIO::Firebird::Introspect->new(dbh => $dbh)->model;
  my $entry   = $model->{tables}{$table};
  my @cols    = @{ $args->{columns} || [] };
  my $columns = $model->{columns}{$table} || [];

  if ($name eq 'object_kind') {
    return undef unless $entry;
    return $entry->{kind} eq 'view' ? 'view' : 'table';
  }
  if ($name eq 'table_name') {
    return $entry ? $entry->{table_name} : undef;
  }
  if ($name eq 'column_names') {
    return [ map { $_->{column_name} } @$columns ];
  }
  if ($name eq 'column_size') {
    my ($col) = grep { $_->{column_name} eq $args->{column} } @$columns;
    return undef unless $col;
    return ref $col->{size} ? $col->{size}[0] : $col->{size};
  }
  if ($name eq 'column_auto_increment') {
    my ($col) = grep { $_->{column_name} eq $args->{column} } @$columns;
    return $col && $col->{is_auto_increment} ? 1 : 0;
  }
  if ($name eq 'primary_key_columns') {
    return [ map { $_->{column_name} }
             sort { $a->{pk_position} <=> $b->{pk_position} }
             grep { $_->{is_pk} } @$columns ];
  }
  if ($name eq 'unique_exists') {
    my $want = join "\0", @cols;
    return (grep { join("\0", @{ $_->[1] }) eq $want }
            @{ $model->{unique_constraints}{$table} || [] }) ? 1 : 0;
  }
  if ($name eq 'foreign_key_count') {
    return scalar @{ $model->{foreign_keys}{$table} || [] };
  }
  if ($name eq 'index_count') {
    # every index of the table over exactly these columns, the ones behind a
    # unique constraint or a foreign key included, the primary key's excluded
    my $rows = $dbh->selectall_arrayref(q{
      SELECT i.rdb$index_name, s.rdb$field_name
      FROM rdb$indices i
      JOIN rdb$index_segments s ON s.rdb$index_name = i.rdb$index_name
      WHERE i.rdb$relation_name = ?
        AND NOT EXISTS (SELECT 1 FROM rdb$relation_constraints c
                        WHERE c.rdb$index_name = i.rdb$index_name
                          AND c.rdb$constraint_type = 'PRIMARY KEY')
      ORDER BY i.rdb$index_name, s.rdb$field_position
    }, undef, $table);
    my (%by_index, @order);
    for my $r (@$rows) {
      my $i = _trim($r->[0]);
      push @order, $i unless $by_index{$i};
      push @{ $by_index{$i} }, _trim($r->[1]);
    }
    my $want = join "\0", @cols;
    return scalar grep { join("\0", @{ $by_index{$_} }) eq $want } @order;
  }

  DBIO::Exception->throw("unknown conformance fact '$name'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Test::Conformance - Answers the shared conformance case table for the Firebird driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::Firebird::Test::Conformance;
  DBIO::Firebird::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says how to
reach a Firebird server, how to install a declaration into it through
L<DBIO::Firebird::Deploy>, and how to read a fact back through
L<DBIO::Firebird::Introspect> and the C<rdb$*> tables.

The server is the one C<DBIO_TEST_FIREBIRD_DSN>, C<DBIO_TEST_FIREBIRD_USER>
and C<DBIO_TEST_FIREBIRD_PASS> name; without the DSN (or without
L<DBD::Firebird>) only the declarations are checked. The user needs the right
to create and drop databases: L<DBIO::Firebird::Deploy/diff> builds its
target in a temporary database next to the live one.

B<The namespace of a case is the test database itself.> Firebird has no
schemas before version 6, so a case cannot be given a schema of its own, and
the diff compares the whole visible database. L</conformance_namespace> therefore
refuses to run in a database that holds a table or view already (it is not
this run's to drop), and otherwise returns the mark of the case: the names of
the tables and views its sources will create. L</conformance_cleanup> removes
those objects and nothing else (their foreign keys, then the views, then the
tables, where they exist), through a connection of its own, after the
case's connection is closed. The core runner calls the cleanup also when the
namespace seam threw, with no mark; then it disconnects and drops nothing, so
a database that was refused is left exactly as it was. The class names no
storage class: the schema component declares the driver.

=head1 METHODS

=head2 conformance_live_available

True when C<DBIO_TEST_FIREBIRD_DSN> is set and L<DBD::Firebird> loads.

=head2 conformance_connect

Loads the C<Firebird> schema component into the case's schema class and
connects with the connection attributes the driver's own live tests use. It
asks for no C<datetime_setup>: the storage puts every connection into the ISO
date and timestamp formats itself
(L<DBIO::Firebird::Storage::InterBase/connect_call_datetime_setup>). It sets
C<LongReadLen> to one million bytes, as the driver's live tests do for the
BLOBs they read whole: DBD::Firebird dies on a longer value otherwise.

=head2 conformance_namespace

Checks that the database holds no user table or view and returns the mark of
the case: C<< { tables => [ ... ], views => [ ... ] } >>, the names of the
tables and views the sources of the schema will create, and, for a Diff
case, the ones its second declaration adds (a literal name,
C<< table(\'x') >>, and a subquery source are not named; a source twice over
one name once). A database that holds a relation already is not the run's to
use or clean: the case ends with the names of what is there, and there is no
mark.

=head2 conformance_install

Installs the declaration with C<< $schema->deploy >>, the public entry point,
which hands over to L<DBIO::Firebird::Deploy/install>.

C<ddl-view-declared> runs like the other cases: core's runner builds the view
definition through the hook C<conformance_quote_ident>, whose default quotes
with the quote character of the SQL maker (C<">), so the definition names the
base table the way the driver created it (quoted, lower case). This class
needs no hook of its own.

=head2 conformance_cleanup

Disconnects the case's connection, then removes the objects of the mark
C<conformance_namespace> returned -- first their foreign keys, then the
views, then the tables, each where it exists -- through a connection of its
own. Without a mark (the namespace seam threw: the database was not empty) it
only disconnects. It never drops "everything in the database": what is there
and not named by the mark is somebody else's.

=head2 conformance_diff_is_empty

True when L<DBIO::Firebird::Deploy/diff> of the installed schema against the
same declaration has no changes.

=head2 conformance_upgrade

Loads the C<Firebird> component into the target schema class, connects it
with the parameters of L</conformance_connect> and runs
L<DBIO::Firebird::Deploy/upgrade> -- the public entry point -- through it.
The connected target schema is returned. A refusal of the diff
(L<DBIO::Firebird::Diff::Column/COLUMN CHANGES THE SERVER REFUSES>,
L<DBIO::Firebird::Diff::Table/refusal>) is thrown from here as it came.

=head2 conformance_deploy

The deploy object over the target schema, for the deploy cases of the Diff list
(table version 4): the target class is connected exactly as
L</conformance_upgrade> connects it (the case's own connection closed first,
for the reason given there) and the object is
C<< DBIO::Firebird::Deploy->new(schema => $to) >>. The runner calls C<apply>
and C<upgrade> on it and hands the target schema to L</conformance_cleanup>,
which drops the tables and views of the case's mark; the namespace is the
database, so nothing is handed over.

=head2 conformance_answered_through

The table versions the answers were written against, per area:
C<< { DDL => 2, Diff => 4, Bind => 1 } >> (version 2 of the Diff list
splits U13 into C<diff-constraint-changed> and C<diff-fk-action-changed>).

Version 3 of the Diff list replaces C<diff-column-dropped-with-index> by
C<diff-indexed-column-dropped>; it runs.

Version 4 adds the three deploy cases C<diff-deploy-inherited>,
C<diff-deploy-dry-run> and C<diff-deploy-destructive-guard> (ADR 0080), which
run through L</conformance_deploy>.
L</conformance_upgrade> releases the destructive and lossy operations of its
diff (C<allow_destructive>): the cases of the list state what the database must
look like afterwards, and the guard has its own case.

=head2 conformance_refusals

The declared refusals and deviations:

=over 4

=item C<ddl-type-size-bit> (refusal)

C<bit>: Firebird has no type for a bit string of a fixed width.

C<ddl-type-size-char> is answered, not refused: C<character(10)> reads back
with size 10 and the server rejects an 11-character value (t/84).

=item C<ddl-enum-value-apostrophe> (refusal)

C<enum>: Firebird has no enumerated type.

=item C<ddl-qualified-source-name> (refusal)

A dotted table name: Firebird has no schemas before version 6.

=item C<ddl-default-digit-string> (deviation)

C<char(5)> with the default C<'007'> reads back as C<'007  '>: Firebird pads
a C<CHAR(n)> value with blanks to its length. That is the type's definition;
the driver does not trim.

=item C<diff-column-added-not-null-populated> (refusal)

A C<NOT NULL> column without a default added to a table that holds rows:
Firebird has no value for the rows already there. The driver refuses it
itself, before the first statement, naming table and column
(L<DBIO::Firebird::Deploy/_refuse_unfillable>); the server's own
answer would come half way through the upgrade.

=item C<diff-not-null-over-nulls> (refusal)

A column that becomes C<NOT NULL> over a C<NULL>: the server refuses
(I<Cannot make field NOT NULL because there are NULLs present>). The driver
asks the table first and refuses before the first statement, the same way.

=item C<bind-long-string> (refusal)

A text of 32 769 characters is stored and read back, but it cannot be searched
by its value: Firebird compares a BLOB with a C<VARCHAR>, and a C<VARCHAR>
holds 32 765 bytes (8191 characters of UTF8) at most, so no parameter can
carry the value, and DBD::Firebird takes no BLOB parameter in a C<SELECT>. The
storage refuses the search itself, before the DBD, naming table and column
(L<DBIO::Firebird::Storage::InterBase/A BLOB compared with a bound value>).
The shorter values of the case (4001, 8001 characters) run through.

=item C<bind-numeric-exact> (refusal)

NUMERIC(20,4) is an INT128: the server has it from Firebird 4, but
DBD::Firebird 1.39 can neither bind nor read one. C<install_ddl> refuses the
column on every server, naming table and column
(L<DBIO::Firebird::DDL>; the fact is held by t/97-numeric-int128-dbd-live.t).

=back

The other Bind cases run through: text and BLOB comparisons by a
cast parameter, non-ASCII text by the UTF8 connection, a number for a numeric
column checked before the DBD reads it
(L<DBIO::Firebird::Storage::InterBase/Text is UTF8 on every native connection>).

=head2 conformance_fact

Reads one fact through L<DBIO::Firebird::Introspect> (the index count straight
from C<rdb$indices>); the vocabulary is the one of
L<DBIO::Test::Conformance/Facts>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::Firebird::Deploy> - install and diff, as the cases reach them

=item * L<DBIO::Firebird::Introspect> - what the facts are read through

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
