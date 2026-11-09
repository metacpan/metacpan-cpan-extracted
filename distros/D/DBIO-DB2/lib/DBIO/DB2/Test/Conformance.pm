package DBIO::DB2::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the Db2 driver

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::Conformance';

use DBI ();
use DBIO::Exception ();
use DBIO::DB2::Introspect ();
use DBIO::DB2::Deploy ();


my $SEQ = 0;
# schema class => the name of its case's schema
my %NAMESPACE;


sub conformance_live_available {
  return 0 unless length($ENV{DBIO_TEST_DB2_DSN} // '')
              and length($ENV{DBIO_TEST_DB2_USER} // '');
  return eval { require DBD::DB2; 1 } ? 1 : 0;
}

# The name of the next case's schema. Upper case: Db2 stores an unquoted
# schema name that way and the introspector filters on the stored name.
sub _schema_name { sprintf 'DBIO_CF_%d_%d', $$, ++$SEQ }

sub _connect_in {
  my ($class, $schema_class, $name) = @_;
  $NAMESPACE{$schema_class} = $name;
  $schema_class->load_components('DB2');
  return $schema_class->connect(
    $ENV{DBIO_TEST_DB2_DSN}, $ENV{DBIO_TEST_DB2_USER}, $ENV{DBIO_TEST_DB2_PASS}, {
      AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0,
      LongReadLen => 1_000_000,
      on_connect_do => [ "SET CURRENT SCHEMA = '$name'" ],
    });
}


sub conformance_connect {
  my ($class, $schema_class) = @_;
  return $class->_connect_in($schema_class, $class->_schema_name);
}

sub _namespace_of {
  my ($class, $schema) = @_;
  my $name = $NAMESPACE{ ref $schema };
  DBIO::Exception->throw('conformance: this schema was not connected through '
    . 'conformance_connect') unless defined $name;
  return $name;
}


sub conformance_namespace {
  my ($class, $schema, $case) = @_;
  my $name = $class->_namespace_of($schema);
  my $dbh  = $schema->storage->dbh;

  # A source named "other.t" is the table t in the schema other: the install
  # makes that schema (Db2 does, with the first table of it), so the case drops
  # it again -- and only a schema the case made: one that is there already makes
  # the namespace throw, touching nothing.
  my %extra;
  for my $moniker ($schema->sources) {
    my $table = $schema->source($moniker)->name;
    next if ref $table;
    $extra{$1} = 1 if $table =~ /\A([^."]+)\.[^."]+\z/;
  }
  my @extra = sort grep { $_ ne $name } keys %extra;
  for my $extra (@extra, $name) {
    my ($there) = $dbh->selectrow_array(
      'SELECT 1 FROM syscat.schemata WHERE schemaname = ?', undef, $extra);
    DBIO::Exception->throw("conformance: the schema $extra exists already; "
      . 'refusing to use or drop a schema the case did not create') if $there;
  }
  $dbh->do("CREATE SCHEMA $name");
  return { name => $name, created => 1, extra => \@extra };
}


sub conformance_install {
  my ($class, $schema, $case) = @_;
  $schema->deploy;
  return;
}


sub conformance_cleanup {
  my ($class, $schema, $case, $namespace) = @_;
  delete $NAMESPACE{ ref $schema };
  eval { $schema->storage->disconnect; 1 };
  return unless ref $namespace eq 'HASH' and $namespace->{created};
  my $name = $namespace->{name};

  my $dbh = DBI->connect(
    $ENV{DBIO_TEST_DB2_DSN}, $ENV{DBIO_TEST_DB2_USER}, $ENV{DBIO_TEST_DB2_PASS},
    { AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0 })
    or DBIO::Exception->throw("conformance: cleanup of schema $name could not connect");
  my $quote = sub { (my $q = $_[0]) =~ s/"/""/g; qq{"$q"} };
  my $ok = eval {
    for my $schema_name ($name, @{ $namespace->{extra} || [] }) {
      for my $kind (['V', 'VIEW'], ['T', 'TABLE']) {
        my $names = $dbh->selectcol_arrayref(
          'SELECT tabname FROM syscat.tables WHERE tabschema = ? AND type = ?',
          undef, $schema_name, $kind->[0]);
        $dbh->do("DROP $kind->[1] " . $quote->($schema_name) . '.' . $quote->($_)) for @$names;
      }
      $dbh->do('DROP SCHEMA ' . $quote->($schema_name) . ' RESTRICT');
    }
    1;
  };
  my $err = $@;
  $dbh->disconnect;
  DBIO::Exception->throw("conformance: cleanup of schema $name failed: $err")
    unless $ok;
  return;
}


sub conformance_diff_is_empty {
  my ($class, $schema, $case) = @_;
  my $diff = DBIO::DB2::Deploy->new(schema => $schema)->diff;
  return $diff->has_changes ? 0 : 1;
}


sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->_connect_in($to_class, $class->_namespace_of($schema));
  DBIO::DB2::Deploy->new(schema => $to)->upgrade(allow_destructive => 1);
  return $to;
}


sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->_connect_in($to_class, $class->_namespace_of($schema));
  return DBIO::DB2::Deploy->new(schema => $to);
}


sub conformance_answered_through { { DDL => 2, Diff => 4, Bind => 1 } }


sub conformance_refusals {
  return {
    'ddl-enum-value-apostrophe' => {
      kind   => 'server',
      reason => qr/no enum type.*it is refused/s,
    },
    'ddl-type-size-bit' => {
      kind   => 'server',
      reason => qr/no bit type.*it is refused/s,
    },
    'ddl-default-digit-string' => {
      kind   => 'deviation',
      fact   => qr/expected '007', read back '007 +'/,
      reason => 'a CHAR(n) column pads the value with blanks to its length '
              . '(SQL Reference, CHAR data type); the default is written as the '
              . 'string it is',
    },

    # Bind list
    'bind-long-string' => {
      kind   => 'server',
      reason => qr/column "v" is compared with a value of \d+ bytes, and Db2 cannot compare a CLOB with more than 32672 bytes/,
    },
    'bind-lob-empty-and-large' => {
      kind   => 'server',
      reason => qr/column "b" gets an empty string, which DBD::DB2 reads back as NULL from a BLOB column/,
    },

    # Diff list
    'diff-column-added-not-null-populated' => {
      kind   => 'server',
      reason => qr/column "code" to table "base": it is NOT NULL without a default/,
    },
    'diff-not-null-over-nulls' => {
      kind   => 'server',
      reason => qr/column "c" NOT NULL: table "opt" holds rows where it is NULL/,
    },
  };
}


sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  my $dbh  = $schema->storage->dbh;
  my $ns   = $class->_namespace_of($schema);
  my $table = $args->{table};
  my @cols  = @{ $args->{columns} || [] };
  my $same  = sub {
    my ($got) = @_;
    return 0 unless @$got == @cols;
    return (join("\0", map { $_ // '' } @$got) eq join("\0", @cols)) ? 1 : 0;
  };

  if ($name eq 'table_in_namespace') {
    my ($n) = $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.tables WHERE tabschema = ? AND tabname = ?',
      undef, $args->{namespace}, $args->{unqualified});
    return $n ? 1 : 0;
  }

  if ($name eq 'index_count') {
    my $rows = $dbh->selectall_arrayref(
      q{SELECT indschema, indname FROM syscat.indexes
         WHERE tabschema = ? AND tabname = ? AND uniquerule <> 'P'},
      undef, $ns, $table);
    my $n = 0;
    for my $r (@$rows) {
      my $got = $dbh->selectcol_arrayref(
        q{SELECT colname FROM syscat.indexcoluse
           WHERE indschema = ? AND indname = ? AND colorder <> 'I'
           ORDER BY colseq}, undef, @$r);
      $n++ if $same->($got);
    }
    return $n;
  }

  my $intro = DBIO::DB2::Introspect->new(dbh => $dbh, schema => $ns);
  my $model = $intro->model;
  my $entry = $model->{tables}{$table};

  if ($name eq 'object_kind') {
    return $entry ? $entry->{kind} : undef;
  }
  if ($name eq 'table_name') {
    return $entry ? $table : undef;
  }
  if ($name eq 'column_names') {
    return $entry ? $intro->table_columns($table) : [];
  }
  if ($name eq 'column_size') {
    return $intro->table_columns_info($table)->{ $args->{column} }{size};
  }
  if ($name eq 'column_auto_increment') {
    return $intro->table_columns_info($table)->{ $args->{column} }{is_auto_increment} ? 1 : 0;
  }
  if ($name eq 'primary_key_columns') {
    return $intro->table_pk_info($table);
  }
  if ($name eq 'unique_exists') {
    return (grep { $same->($_->[1]) } @{ $intro->table_uniq_info($table) }) ? 1 : 0;
  }
  if ($name eq 'foreign_key_count') {
    return scalar @{ $intro->table_fk_info($table) };
  }

  DBIO::Exception->throw("unknown conformance fact '$name'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Test::Conformance - Answers the shared conformance case table for the Db2 driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::DB2::Test::Conformance;
  DBIO::DB2::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says how to
reach a Db2 database, how to install a declaration into it through
C<< $schema->deploy >> (L<DBIO::DB2::Deploy>), and how to read a fact back
through L<DBIO::DB2::Introspect>.

B<The server> is the one C<DBIO_TEST_DB2_DSN>, C<DBIO_TEST_DB2_USER> and
C<DBIO_TEST_DB2_PASS> name. Without the DSN (or without L<DBD::DB2>) only the
declarations are checked. The login needs the right to create schemas:
L<DBIO::DB2::Deploy/diff> builds its target in a throwaway schema, and so does
every case here.

B<The namespace of a case is a schema of its own>,
C<DBIO_CF_E<lt>pidE<gt>_E<lt>nE<gt>> (L</conformance_namespace>). The
connection of the case sets C<CURRENT SCHEMA> to it when it connects (an
C<on_connect_do>, the schema need not exist yet), so the tables of the case are
made there, the deploy and the introspector read it, and the diff compares
nothing else. The schema is dropped in L</conformance_cleanup> -- views, then
tables, then the schema -- only when L</conformance_namespace> of this run
created it: one that is there already makes the namespace throw, touching
nothing.

The class names no storage class and never decides the driver: the schema
component C<DB2> declares it, the DSN names the database.

=head1 METHODS

=head2 conformance_live_available

True when C<DBIO_TEST_DB2_DSN> and C<DBIO_TEST_DB2_USER> are set and
L<DBD::DB2> loads.

=head2 conformance_connect

Names the schema of the case, loads the C<DB2> schema component into the case's
schema class and connects, with C<CURRENT SCHEMA> set to that schema.

The connection names a C<LongReadLen> of a million bytes: L<DBD::DB2> reads at
most 32700 bytes of a LOB by default and refuses a longer one with "Data in
column has been truncated", and the Bind list writes and reads 100000 characters.
The driver keeps that default; an application that stores larger values sets it.

=head2 conformance_namespace

A source named C<other.t> is the table C<t> in the schema C<other>: the
install makes that schema with the table, so the token also names these schemas,
and the cleanup drops them. One that exists already makes the namespace throw.

Creates the schema of the case and returns the token C<< { name, created } >>
for L</conformance_cleanup>. A schema of that name that exists already makes it
throw, touching nothing and returning no token.

=head2 conformance_install

Installs the declaration with C<< $schema->deploy >>, the public entry point,
which hands over to L<DBIO::DB2::Deploy/install>.

=head2 conformance_cleanup

Disconnects, and drops the schema the token names when
L</conformance_namespace> created it: the views, the tables (with their indexes,
keys and identity sequences), then the schema, on a connection of its own. A
failure of one of those statements is thrown, not swallowed. Without a token
nothing is dropped.

=head2 conformance_diff_is_empty

True when L<DBIO::DB2::Deploy/diff> of the installed database against the same
declaration has no changes.

=head2 conformance_upgrade

Connects the target schema class to the schema of the installed one (a
connection of its own, C<CURRENT SCHEMA> set as in L</conformance_connect>) and
runs L<DBIO::DB2::Deploy/upgrade> -- the public entry point -- through it, with
C<< allow_destructive => 1 >>: the upgrade cases drop and change on purpose (the
guard itself is the deploy cases, L</conformance_deploy>).
Returns the connected target schema; a refusal of the diff is thrown from here
as it came. The cleanup of that schema drops the namespace through the token
of the first.

=head2 conformance_deploy

Same connecting as L</conformance_upgrade>, but returns the deploy object over
the connected target schema, C<< DBIO::DB2::Deploy->new(schema => $to) >>, for
the deploy cases of the Diff list (ADR 0080): C<apply> and C<upgrade> are those
of L<DBIO::Deploy::Base>, C<dry_run> executes nothing, and a diff with a drop
needs C<allow_destructive>. The cleanup drops the namespace through the token of
the first schema.

=head2 conformance_answered_through

The table versions the answers were written against, per area:
C<< { DDL => 2, Diff => 4, Bind => 1 } >>, each list as it stands. Every case
of all three lists is answered: correctly, or by a refusal or deviation of
L</conformance_refusals>. Version 3 of the Diff list replaces
C<diff-column-dropped-with-index> by C<diff-indexed-column-dropped>; version 4
adds the deploy cases, answered through L</conformance_deploy>.

=head2 conformance_refusals

DDL list: two server refusals and one deviation. Diff list: two server refusals.
Bind list: two server refusals. The rest is answered right. C<text> without a
size is a C<CLOB>; the character columns of a result are decoded from
the UTF-8 bytes L<DBD::DB2> returns (L<DBIO::DB2::Storage::Cursor>).

=over 4

=item ddl-enum-value-apostrophe (server)

Db2 has no enum type (SQL0204N). C<install_ddl> throws, naming table, column and
type, instead of writing C<ENUM> for the server to refuse
(L<DBIO::DB2::Type>). The way out is a C<varchar> column.

=item ddl-type-size-bit (server)

Db2 has no C<BIT> type (SQL0104N), with a size or without one; refused the same way.

=item bind-long-string (server)

Db2 compares a C<CLOB> with a C<VARCHAR>, and a value of more than 32672 bytes
is too long for that (SQL0433N, whatever the type the value is bound with,
measured; a stored value that long breaks the comparison for every row of the
table). The storage refuses a select or delete that compares a C<clob>/C<text>
column with such a value, naming table and column
(L<DBIO::DB2::Storage/_prep_for_execute>), before the server is asked. Storing
and reading the value is not affected.

=item bind-lob-empty-and-large (server)

L<DBD::DB2> reads an empty C<BLOB> as C<NULL> (the server's C<LENGTH> is 0), and
nothing in the DBD or the storage tells the two apart on the way back. The
storage refuses to store an empty string in a C<blob> column, naming table and
column, rather than store it as something that does not come back. An empty
C<CLOB> is stored and read back as C<''>.

=item ddl-default-digit-string (deviation)

A C<CHAR(5)> pads the default C<'007'> with blanks, so it reads back as
C<'007  '>. The default itself is written as the string it is, not as
the number 7; the padding is the type's.

=item diff-column-added-not-null-populated, diff-not-null-over-nulls (server)

Db2 cannot be given a value for the rows in either: C<ADD COLUMN ... NOT NULL>
without a default is refused whatever rows the table holds (SQL0193N), and
C<SET NOT NULL> over a C<NULL> is refused by the server (SQL0407N).
L<DBIO::DB2::Deploy/apply> and C<upgrade> refuse both before the first statement,
naming table and column, and make up no value.

=back

=head2 conformance_fact

Reads one fact through L<DBIO::DB2::Introspect> (the case's schema); the
vocabulary is the one of L<DBIO::Test::Conformance/Facts>. C<index_count> reads
C<SYSCAT.INDEXES> itself: the model leaves the index behind a C<UNIQUE>
constraint out, and the fact counts it.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::DB2::Deploy> - install and diff, as the cases reach them

=item * L<DBIO::DB2::Introspect> - what the facts are read through

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
