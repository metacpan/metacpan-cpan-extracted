package DBIO::Informix::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the Informix driver

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::Conformance';

use DBI ();
use DBIO::Exception ();
use DBIO::Informix::Util ();
use DBIO::Informix::Deploy ();
use DBIO::Informix::Introspect ();



sub conformance_live_available {
  return 0 unless length($ENV{DBIO_TEST_INFORMIX_DSN} // '');
  return eval { require DBD::Informix; 1 } ? 1 : 0;
}

my @CONNECT = qw(DBIO_TEST_INFORMIX_DSN DBIO_TEST_INFORMIX_USER DBIO_TEST_INFORMIX_PASS);


sub conformance_connect {
  my ($class, $schema_class) = @_;
  $schema_class->load_components('Informix');
  return $schema_class->connect(
    @ENV{@CONNECT},
    { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 },
  );
}

# A connection of the conformance run's own, apart from the case's.
# DELIMIDENT is set for the connect: names are quoted like the storage does.
sub _own_dbh {
  local $ENV{DELIMIDENT} = 'y';
  return DBI->connect(
    @ENV{@CONNECT},
    { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 },
  );
}

sub _trim { my ($s) = @_; $s =~ s/\s+\z// if defined $s; return $s }

# [ [ name, 'TABLE' | 'VIEW' ], ... ] of the user tables and views
sub _relations {
  my ($dbh) = @_;
  my $rows = $dbh->selectall_arrayref(
    q{SELECT TRIM(tabname), tabtype FROM systables WHERE tabid >= 100 AND tabtype IN ('T', 'V')});
  return [ map { [ $_->[0], $_->[1] eq 'V' ? 'VIEW' : 'TABLE' ] } @$rows ];
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

  my $q   = sub { DBIO::Informix::Util::_quote_ident($_[0]) };
  my $dbh = _own_dbh();
  my $ok = eval {
    my @rel    = @{ _relations($dbh) };
    # by the name of the mark, whatever kind of object the case left there
    # (a driver that builds a view as a table is a finding of the case, not
    # of the cleanup)
    my %want   = (%want_table, %want_view);
    my @views  = grep { $_->[1] eq 'VIEW'  and $want{ $_->[0] } } @rel;
    my @tables = grep { $_->[1] eq 'TABLE' and $want{ $_->[0] } } @rel;

    my $fks = $dbh->selectall_arrayref(q{
      SELECT TRIM(t.tabname), TRIM(c.constrname)
      FROM sysconstraints c JOIN systables t ON t.tabid = c.tabid
      WHERE c.constrtype = 'R'
    });
    for my $fk (@$fks) {
      my ($table, $constraint) = @$fk;
      next unless $want_table{$table} or $want_view{$table};
      $dbh->do(sprintf 'ALTER TABLE %s DROP CONSTRAINT %s', $q->($table), $q->($constraint));
    }
    $dbh->do('DROP VIEW ' . $q->($_->[0])) for @views;
    $dbh->do('DROP TABLE ' . $q->($_->[0])) for @tables;
    1;
  };
  my $err = $@;
  $dbh->disconnect;
  DBIO::Exception->throw("conformance: cleanup failed: $err") unless $ok;
  return;
}


sub conformance_diff_is_empty {
  my ($class, $schema, $case) = @_;
  my $diff = DBIO::Informix::Deploy->new(schema => $schema)->diff;
  return $diff->has_changes ? 0 : 1;
}


sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  # The case's own connection holds locks on its tables; the DDL of the
  # upgrade and the DROP TABLE of the cleanup (each on a connection of their
  # own) would wait for them. Nothing reads through the old schema once the
  # upgrade starts.
  eval { $schema->storage->disconnect };
  my $to = $class->conformance_connect($to_class);
  DBIO::Informix::Deploy->new(schema => $to)->upgrade(allow_destructive => 1);
  return $to;
}


sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  eval { $schema->storage->disconnect };
  my $to = $class->conformance_connect($to_class);
  return DBIO::Informix::Deploy->new(schema => $to);
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
    reason => qr/Informix allows no TEXT or BYTE in a comparison/,
  },
  'bind-non-ascii' => {
    kind   => 'server',
    reason => qr/Informix allows no TEXT or BYTE in a comparison/,
  },
  'bind-binary' => {
    kind   => 'server',
    reason => qr/Informix allows no TEXT or BYTE in a comparison/,
  },
  'bind-lob-row-operations' => {
    kind   => 'server',
    reason => qr/Informix allows no TEXT or BYTE in a comparison/,
  },
  'bind-lob-empty-and-large' => {
    kind   => 'deviation',
    fact   => qr/Lob\.t create: expected '', read back NULL.*Lob\.b create: expected '', read back NULL/s,
    reason => 'Informix stores an empty TEXT or BYTE as NULL (a zero-length large object is not a value there; an empty LVARCHAR or CHAR is kept as it is); the large values of the case round-trip',
  },
  'ddl-type-size-bit' => {
    kind   => 'server',
    reason => qr/no type for a bit string of a fixed width/,
  },
  'ddl-enum-value-apostrophe' => {
    kind   => 'server',
    reason => qr/no enumerated type/,
  },
  'ddl-index-on-unique-columns' => {
    kind   => 'server',
    reason => qr/Informix holds only one index there \(-350\)/,
  },
  'ddl-qualified-source-name' => {
    kind   => 'server',
    reason => qr/Informix has no schemas/,
  },
  'ddl-type-size-char' => {
    kind   => 'deviation',
    fact   => qr/Sized: the server accepted a row it must reject/,
    reason => 'Informix cuts a CHAR(n) or VARCHAR(n) value that is longer than n silently to n characters (measured on 15.0.1, no error and no warning in a logged database); the size is kept (column_size 10) and the driver does not check lengths itself',
  },
  'ddl-default-digit-string' => {
    kind   => 'deviation',
    fact   => qr/expected '007', read back '007  '/,
    reason => 'Informix pads a CHAR(n) value with blanks to its length; that is the type\'s definition and the driver does not trim',
  },
  };
}


sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  my $table = $args->{table};
  my $dbh   = $schema->storage->dbh;

  # Informix has no schemas: no table is in any namespace but the database's
  return 0 if $name eq 'table_in_namespace';

  my $model   = DBIO::Informix::Introspect->new(dbh => $dbh)->model;
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
  if ($name eq 'foreign_key_count') {
    return scalar @{ $model->{foreign_keys}{$table} || [] };
  }

  my $want = join "\0", @cols;

  if ($name eq 'unique_exists') {
    # a unique constraint (not the primary key) or a unique index over
    # exactly these columns
    return (grep { $_->{unique} and $_->{constraint} ne 'P' and join("\0", @{ $_->{columns} }) eq $want }
            @{ _indexes($dbh, $table) }) ? 1 : 0;
  }
  if ($name eq 'index_count') {
    # every index of the table over exactly these columns, the ones behind a
    # unique constraint or a foreign key included, the primary key's excluded
    return scalar grep { $_->{constraint} ne 'P' and join("\0", @{ $_->{columns} }) eq $want }
                  @{ _indexes($dbh, $table) };
  }

  DBIO::Exception->throw("unknown conformance fact '$name'");
}

# Every index of a table straight from sysindexes, with the constraint type
# that owns it ('P', 'U', 'R', or '' for a plain index).
sub _indexes {
  my ($dbh, $table) = @_;
  my $parts = join ', ', map { "i.part$_" } 1 .. 16;
  my $rows = $dbh->selectall_arrayref(qq{
    SELECT TRIM(i.idxname), i.idxtype, i.tabid, $parts,
           (SELECT MAX(c.constrtype) FROM sysconstraints c
             WHERE c.tabid = i.tabid AND c.idxname = i.idxname)
    FROM sysindexes i JOIN systables t ON t.tabid = i.tabid
    WHERE t.tabname = ?
  }, undef, $table);
  my @out;
  for my $r (@$rows) {
    my ($idx, $type, $tabid, @rest) = @$r;
    my $constraint = _trim(pop @rest) // '';
    my @parts = grep { $_ } @rest;
    my %name = map { @$_ } @{ $dbh->selectall_arrayref(
      'SELECT colno, TRIM(colname) FROM syscolumns WHERE tabid = ?', undef, $tabid) };
    push @out, {
      name       => $idx,
      unique     => ($type eq 'U' ? 1 : 0),
      constraint => $constraint,
      columns    => [ map { $name{ abs $_ } } @parts ],
    };
  }
  return \@out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Test::Conformance - Answers the shared conformance case table for the Informix driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::Informix::Test::Conformance;
  DBIO::Informix::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says how to
reach an Informix server, how to install a declaration into it through
L<DBIO::Informix::Deploy>, and how to read a fact back through
L<DBIO::Informix::Introspect> and the C<sys*> catalog.

The server is the one C<DBIO_TEST_INFORMIX_DSN>, C<DBIO_TEST_INFORMIX_USER>
and C<DBIO_TEST_INFORMIX_PASS> name; without the DSN (or without
L<DBD::Informix>) only the declarations are checked. The user needs the right
to create and drop databases: L<DBIO::Informix::Deploy/diff> builds its target
in a throwaway database next to the live one.

B<The namespace of a case is the test database itself.> Informix has no
schemas, so a case cannot be given one of its own, and the diff compares the
whole visible database. L</conformance_namespace> therefore refuses to run in
a database that holds a table or view already (it is not this run's to drop),
and otherwise returns the mark of the case: the names of the tables and views
its sources will create. L</conformance_cleanup> removes those objects and
nothing else (their foreign keys, then the views, then the tables), through a
connection of its own, after the case's connection is closed. The server is
shared: the class touches nothing server-wide, only objects of the mark in
the database of the DSN.

=head1 METHODS

=head2 conformance_live_available

True when C<DBIO_TEST_INFORMIX_DSN> is set and L<DBD::Informix> loads.

=head2 conformance_connect

Loads the C<Informix> schema component into the case's schema class and
connects with the parameters of the driver's own live tests.

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
which hands over to L<DBIO::Informix::Deploy/install>.

=head2 conformance_cleanup

Disconnects the case's connection, then removes the objects of the mark
C<conformance_namespace> returned -- first their foreign keys, then the
views, then the tables, each where it exists -- through a connection of its
own. Without a mark (the namespace seam threw: the database was not empty) it
only disconnects. It never drops "everything in the database": what is there
and not named by the mark is somebody else's.

=head2 conformance_diff_is_empty

True when L<DBIO::Informix::Deploy/diff> of the installed schema against the
same declaration has no changes.

=head2 conformance_upgrade

Loads the C<Informix> component into the target schema class, connects it
with the parameters of L</conformance_connect> and runs
L<DBIO::Informix::Deploy/upgrade> -- the public entry point -- through it, with
C<< allow_destructive => 1 >> (the upgrade cases drop and change on purpose; the
guard itself is the deploy cases of L</conformance_deploy>).
The connected target schema is returned. A refusal of the diff is thrown from
here as it came.

=head2 conformance_deploy

Same connecting as L</conformance_upgrade>, but returns the deploy object over
the connected target schema, C<< DBIO::Informix::Deploy->new(schema => $to) >>,
for the deploy cases of the Diff list (ADR 0080): C<apply> and C<upgrade> are
those of L<DBIO::Deploy::Base>, C<dry_run> executes nothing, and a diff with a
drop needs C<allow_destructive>.

=head2 conformance_answered_through

The table versions the answers were written against, per area:
C<< { DDL => 2, Diff => 4, Bind => 1 } >>.

=head2 conformance_refusals

The declared refusals and deviations; see the list in the source, each entry
carries its reason.

=head2 conformance_fact

Reads one fact through L<DBIO::Informix::Introspect> (unique constraints and
the index count straight from C<sysconstraints> and C<sysindexes>); the
vocabulary is the one of L<DBIO::Test::Conformance/Facts>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::Informix::Deploy> - install and diff, as the cases reach them

=item * L<DBIO::Informix::Introspect> - what the facts are read through

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
