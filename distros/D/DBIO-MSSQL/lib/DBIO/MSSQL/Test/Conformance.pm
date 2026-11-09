package DBIO::MSSQL::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the SQL Server driver

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::Conformance';

use DBI ();
use DBIO::Exception ();
use DBIO::MSSQL::Introspect ();
use DBIO::MSSQL::Deploy ();


my $SEQ = 0;
# schema class => name of the database of its case
my %DATABASE;

# the connection details of the access path in use: [ dsn, user, pass ]
sub _server {
  my @odbc   = @ENV{qw(DBIO_TEST_MSSQL_ODBC_DSN DBIO_TEST_MSSQL_ODBC_USER DBIO_TEST_MSSQL_ODBC_PASS)};
  my @sybase = @ENV{qw(DBIO_TEST_MSSQL_DSN DBIO_TEST_MSSQL_USER DBIO_TEST_MSSQL_PASS)};
  return \@odbc   if length($odbc[0] // '')   and eval { require DBD::ODBC; 1 };
  return \@sybase if length($sybase[0] // '') and eval { require DBD::Sybase; 1 };
  return undef;
}

# the DSN with its database swapped, in the spelling of the DBD (as
# DBIO::MSSQL::Deploy::_temp_dsn does)
sub _dsn_for {
  my ($class, $dsn, $database) = @_;
  return $dsn if $dsn =~ s/\b((?:Database|dbname)=)[^;]*/$1$database/i;
  my $key = $dsn =~ /^dbi:Sybase:/i ? 'database' : 'Database';
  $dsn =~ s/;\z//;
  return "$dsn;$key=$database";
}

sub _admin_dbh {
  my ($class) = @_;
  my ($dsn, $user, $pass) = @{ $class->_server };
  return DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 });
}


sub conformance_live_available { $_[0]->_server ? 1 : 0 }


sub conformance_connect {
  my ($class, $schema_class) = @_;
  my $server = $class->_server
    or DBIO::Exception->throw('conformance: no SQL Server configured');
  my $name = $class->_database_name;
  $DATABASE{$schema_class} = $name;

  $schema_class->load_components('MSSQL');
  my ($dsn, $user, $pass) = @$server;
  return $schema_class->connect($class->_dsn_for($dsn, $name), $user, $pass,
    { AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0,
      $class->_long_read_len($dsn) });
}

# Over DBD::Sybase a value longer than the TEXTSIZE of the session (LongReadLen,
# 32768 unless the connect info says otherwise) is refused when it is read, not
# cut (karr k47); the Bind list writes and reads 100000 characters, so the
# connection names a LongReadLen for them, as the message of that refusal says.
# DBD::Sybase also reads a datetime as 'Oct 25 2026 04:02PM' unless the
# connection asks for datetime_setup (ISO). DBD::ODBC has 1 GiB by default and
# reads ISO; it is left alone.
sub _long_read_len {
  my ($class, $dsn) = @_;
  return $dsn =~ /^dbi:Sybase:/i
    ? (LongReadLen => 1_000_000, on_connect_call => 'datetime_setup')
    : ();
}

# The name of the next case's database. A hook for the test of the refusal
# (t/89): a subclass answers a name that is taken already.
sub _database_name { sprintf 'dbio_cf_%d_%d', $$, ++$SEQ }

sub _database_of {
  my ($class, $schema) = @_;
  my $name = $DATABASE{ ref $schema };
  DBIO::Exception->throw('conformance: this schema was not connected through '
    . 'conformance_connect') unless defined $name;
  return $name;
}


sub conformance_quote_ident {
  my ($class, $schema, $name) = @_;
  (my $inner = $name) =~ s/\]/]]/g;
  return "[$inner]";
}


sub conformance_namespace {
  my ($class, $schema, $case) = @_;
  my $name  = $class->_database_of($schema);
  my $admin = $class->_admin_dbh;
  my $ok = eval {
    my ($id) = $admin->selectrow_array('SELECT DB_ID(?)', undef, $name);
    DBIO::Exception->throw("conformance: the database $name exists already; "
      . 'refusing to use or drop a database the case did not create')
      if defined $id;
    $admin->do("CREATE DATABASE [$name]");
    1;
  };
  my $err = $@;
  $admin->disconnect;
  die $err unless $ok;
  return { name => $name, created => 1 };
}


sub conformance_install {
  my ($class, $schema, $case) = @_;
  $schema->deploy;
  return;
}


sub conformance_cleanup {
  my ($class, $schema, $case, $namespace) = @_;
  delete $DATABASE{ ref $schema };
  eval { $schema->storage->disconnect; 1 };
  return unless ref $namespace eq 'HASH' and $namespace->{created};
  my $name = $namespace->{name};

  my $admin = $class->_admin_dbh;
  my $ok = eval {
    $admin->do("IF DB_ID('$name') IS NOT NULL BEGIN "
      . "ALTER DATABASE [$name] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; "
      . "DROP DATABASE [$name] END");
    1;
  };
  my $err = $@;
  $admin->disconnect;
  DBIO::Exception->throw("conformance: cleanup of database $name failed: $err")
    unless $ok;
  return;
}


sub conformance_diff_is_empty {
  my ($class, $schema, $case) = @_;
  my $diff = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
  return $diff->has_changes ? 0 : 1;
}


sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->_connect_target($schema, $to_class);
  DBIO::MSSQL::Deploy->new(schema => $to)->upgrade(allow_destructive => 1);
  return $to;
}


sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->_connect_target($schema, $to_class);
  return DBIO::MSSQL::Deploy->new(schema => $to);
}

# The target class, connected to the database of the installed schema.
sub _connect_target {
  my ($class, $schema, $to_class) = @_;
  my $server = $class->_server
    or DBIO::Exception->throw('conformance: no SQL Server configured');
  my $name = $class->_database_of($schema);
  $to_class->load_components('MSSQL');
  $DATABASE{$to_class} = $name;
  my ($dsn, $user, $pass) = @$server;
  return $to_class->connect($class->_dsn_for($dsn, $name), $user, $pass,
    { AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0,
      $class->_long_read_len($dsn) });
}


sub conformance_answered_through { { DDL => 2, Diff => 4, Bind => 1 } }


sub conformance_refusals {
  my ($class) = @_;
  my $refusals = {
  'ddl-enum-value-apostrophe' => {
    kind   => 'server',
    reason => qr/type 'enum'.*is refused: SQL Server has no enum type/s,
  },
  'ddl-type-size-bit' => {
    kind   => 'server',
    reason => qr/size '8' on type 'bit'.*is refused: bit has no length in SQL Server/s,
  },
  'ddl-default-digit-string' => {
    kind   => 'deviation',
    fact   => qr/expected '007', read back '007 +'/,
    reason => 'a char(n) column pads the value with blanks to its length',
  },

  # Diff list (karr k81)
  'diff-column-added-not-null-populated' => {
    kind   => 'server',
    reason => qr/refuses to add the column base\.code: it is NOT NULL without a default/,
  },
  'diff-not-null-over-nulls' => {
    kind   => 'server',
    reason => qr/refuses to make the column opt\.c NOT NULL: table opt holds rows where it is NULL/,
  },
  # Bind list (karr k81)
  'bind-empty-string' => {
    kind   => 'deviation',
    fact   => qr/the server accepted a row it must reject/,
    reason => "SQL Server converts the empty string to 0 for an integer column "
      . "(Transact-SQL data type conversion: '' to int is 0), so n => '' is "
      . 'stored as 0, not rejected; the empty string itself round-trips '
      . 'exactly',
  },

};

  # Over DBD::Sybase a bound string beyond ASCII is refused before it is sent
  # (karr k49): FreeTDS would send it as a fixed-length CHAR and the server pad
  # it. The case is a refusal there, a deviation over DBD::ODBC.
  my $server = $class->_server;
  if ($server and $server->[0] =~ /^dbi:Sybase:/i) {
    $refusals->{'bind-non-ascii'} = {
      kind   => 'server',
      reason => qr/has a character beyond ASCII.*Connect through DBD::ODBC/s,
    };
  }
  return $refusals;
}


sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  my $dbh = $schema->storage->dbh;

  if ($name eq 'table_in_namespace') {
    my ($n) = $dbh->selectrow_array(
      'SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES '
      . 'WHERE table_schema = ? AND table_name = ?',
      undef, $args->{namespace}, $args->{unqualified});
    return $n ? 1 : 0;
  }

  # a table "schema.table" is read from that schema (karr k72)
  my $table = $args->{table};
  my @schemas = defined $table && $table =~ /\A([^.]+)\./ ? ($1) : ();
  my $model = DBIO::MSSQL::Introspect->new(dbh => $dbh, schemas => \@schemas)->model;
  my $entry = $model->{tables}{$table};
  my @cols  = @{ $args->{columns} || [] };
  my $same  = sub {
    my ($got) = @_;
    return 0 unless @$got == @cols;
    return (join("\0", map { $_ // '' } @$got) eq join("\0", @cols)) ? 1 : 0;
  };

  if ($name eq 'object_kind') {
    return $entry ? $entry->{kind} : undef;
  }
  if ($name eq 'table_name') {
    return $entry ? $entry->{table_name} : undef;
  }

  my $columns = $model->{columns}{$table} || [];
  if ($name eq 'column_names') {
    return [ map { $_->{column_name} } @$columns ];
  }
  if ($name eq 'column_size') {
    my ($col) = grep { $_->{column_name} eq $args->{column} } @$columns;
    return $col ? $col->{size} : undef;
  }
  if ($name eq 'column_auto_increment') {
    my ($col) = grep { $_->{column_name} eq $args->{column} } @$columns;
    return $col && $col->{is_identity} ? 1 : 0;
  }
  if ($name eq 'primary_key_columns') {
    return [ map { $_->{column_name} }
             sort { $a->{pk_position} <=> $b->{pk_position} }
             grep { $_->{is_pk} } @$columns ];
  }

  my $indexes = $model->{indexes}{$table} || {};
  if ($name eq 'unique_exists') {
    return (grep { $_->{is_unique} and $same->($_->{columns}) } values %$indexes)
      ? 1 : 0;
  }
  if ($name eq 'foreign_key_count') {
    return scalar @{ $model->{foreign_keys}{$table} || [] };
  }
  if ($name eq 'index_count') {
    return scalar grep { $same->($_->{columns}) } values %$indexes;
  }

  DBIO::Exception->throw("unknown conformance fact '$name'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Test::Conformance - Answers the shared conformance case table for the SQL Server driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::MSSQL::Test::Conformance;
  DBIO::MSSQL::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says how to
reach a SQL Server, how to install a declaration into it through
C<< $schema->deploy >> (L<DBIO::MSSQL::Deploy>), and how to read a fact back
through L<DBIO::MSSQL::Introspect>.

B<The server.> C<DBIO_TEST_MSSQL_ODBC_DSN>, C<_USER> and C<_PASS> (DBD::ODBC,
the default access path) are preferred; without them C<DBIO_TEST_MSSQL_DSN>,
C<_USER> and C<_PASS> (DBD::Sybase) are used. Without either, or without the
DBD, only the declarations are checked. The login needs C<CREATE DATABASE>:
L<DBIO::MSSQL::Deploy/diff> builds its target in a throwaway database, and so
does every case here.

B<The namespace of a case is a database of its own>,
C<dbio_cf_E<lt>pidE<gt>_E<lt>nE<gt>>, not a SQL Server schema. A connection
cannot be bound to a schema (the default schema belongs to the database user,
not to the session), and a table written without a schema lands in C<dbo> of
the test database, where the diff would count every other table there as a
C<DROP>. A database per case keeps C<dbo> empty. (A source named C<other.t>,
case C<ddl-qualified-source-name>, is made in the schema C<other> of that
database, which the deploy creates.) L</conformance_connect> only picks the
name -- the connection has to name it -- and builds the lazy connection;
L</conformance_namespace> creates the database and hands back a token C<< {
name =E<gt> ..., created =E<gt> 1 } >>, and L</conformance_cleanup> drops
exactly what that token names. The runner calls the cleanup always, also when
the namespace threw: a name that is taken already makes the namespace throw
without a token, and the database that was there before the case is never
dropped.

The class names no storage class and never decides the driver: the schema
component C<MSSQL> declares it, the DSN names the access path.

=head1 METHODS

=head2 conformance_live_available

True when a server is configured (see L</DESCRIPTION>) and its DBD loads.

=head2 conformance_connect

Picks the name of the case's database, loads the C<MSSQL> schema component into the
case's schema class and connects to that database.

=head2 conformance_quote_ident

C<[name]>, a closing bracket doubled -- the rule of the default, written without
asking the storage. The runner resolves the definition of a view before the
database of the case exists (L</conformance_namespace> comes after it), and over
DBD::Sybase asking the storage for its SQL maker opens the connection, which
fails on C<use> of a database that is not there yet.

=head2 conformance_namespace

Creates the database of the case, on an admin connection of its own (nothing
is terminated), and returns the token C<< { name, created } >> for
L</conformance_cleanup>. A database of that name that exists already makes it
throw, touching nothing and returning no token.

=head2 conformance_install

Installs the declaration with C<< $schema->deploy >>.

=head2 conformance_cleanup

Disconnects, and drops the database the token names (the tables and keys go
with it). Without a token nothing is dropped. Also after a failed case. The throwaway databases of a diff are the diff's own
to drop; a C<_dbio_tmp_*> database left by a crash is found by name.

=head2 conformance_diff_is_empty

True when L<DBIO::MSSQL::Deploy/diff> of the installed database against the
same declaration has no changes.

=head2 conformance_upgrade

Connects the target schema class (the C<MSSQL> component loaded) to the
database of the installed schema -- the DSN swapped to the database of the
case, as L</conformance_connect> does -- and runs L<DBIO::MSSQL::Deploy/upgrade>,
the public entry point, through it with C<< allow_destructive => 1 >> (the
cases are about what the diff does; the guard has its own cases, run through
L</conformance_deploy>). Returns the connected target schema; a
refusal of the diff is thrown from here as it came. The cleanup of that schema
closes its own connection and drops nothing: the database belongs to the
namespace of the first schema.

=head2 conformance_deploy

The deploy object over the target schema, for the deploy cases of the Diff list
(table version 4): the target class is connected to the database of the
installed one exactly as L</conformance_upgrade> connects it. Returns
C<< DBIO::MSSQL::Deploy->new(schema => $to) >>; the runner calls C<apply> and
C<upgrade> on it.

=head2 conformance_answered_through

The table versions the answers were written against, per area: C<< { DDL => 2,
Diff => 4, Bind => 1 } >>, each list as it stands (version 2 of the Diff list
splits U13 into C<diff-constraint-changed> and C<diff-fk-action-changed>, both
answered right). All cases are answered, right or by a refusal or deviation of
L</conformance_refusals>. DDL has 20 cases: 17 right
(C<ddl-qualified-source-name>: the table is made in its schema), two refused
(C<ddl-enum-value-apostrophe>, C<ddl-type-size-bit>) and one declared
deviation (C<ddl-default-digit-string>).

Version 3 of the Diff list replaces C<diff-column-dropped-with-index> by
C<diff-indexed-column-dropped>; it runs.

=head2 conformance_refusals

DDL list: two refusals, the engine cannot hold what the case asks for, and one
deviation, the server's behaviour taken as it is. Diff list:
C<diff-column-added-not-null-populated> and C<diff-not-null-over-nulls> are
server refusals (a C<NOT NULL> column without a default cannot be added to a
table with rows, Msg 4901; a column cannot become C<NOT NULL> over a C<NULL>,
Msg 515; L<DBIO::MSSQL::Deploy/_refuse_unfillable> says so before the server
is asked) (C<diff-default-removed> is answered right: the diff drops the
default constraint; the three view cases too: the diff creates, replaces and
drops views). Bind list: one deviation, C<bind-empty-string> (the server
stores C<''> as 0 in an integer column instead of rejecting it);
C<bind-non-ascii> is answered right over DBD::ODBC (it reads back characters,
C<odbc_utf8_on>) and is a refusal over DBD::Sybase. The DDL ones:

=over 4

=item ddl-enum-value-apostrophe (server)

SQL Server has no enum type. C<install_ddl> throws, naming table, column and
type, instead of writing C<enum> for the server to refuse ("Cannot find data
type enum"). The way out is a C<varchar> column with a CHECK constraint.

=item ddl-type-size-bit (server)

The case declares C<bit(8)>. A C<bit> has no length in SQL Server, so a size
on it is refused by C<install_ddl>, naming table, column and size. (The
sibling case C<ddl-type-size-char>, C<character(10)>, is answered right: the
column keeps its length as C<nchar(10)>, offline in t/91.)

=item ddl-default-digit-string

A C<char(5)> pads the default C<'007'> with blanks, so it reads back as
C<'007  '>. The default itself is written as the string it is
(L<DBIO::MSSQL::DDL>), not as the number 7; the padding is the type's.

=back

=head2 conformance_fact

Reads one fact through L<DBIO::MSSQL::Introspect> (schema C<dbo> of the case's
database); the vocabulary is the one of L<DBIO::Test::Conformance/Facts>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::MSSQL::Deploy> - install and diff, as the cases reach them

=item * L<DBIO::MSSQL::Introspect> - what the facts are read through

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
