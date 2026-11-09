package DBIO::Sybase::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the Sybase ASE driver

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::Conformance';

use DBI ();
use DBIO::Exception ();
use DBIO::Sybase::Introspect ();
use DBIO::Sybase::Deploy ();
use DBIO::Sybase::Quote ();


my $SEQ = 0;
# schema class => name of the database of its case
my %DATABASE;
# database name => the schema the upgrade started from. It stays connected to
# the database, which ASE then refuses to drop (Msg 3702), until the cleanup
# of the upgraded schema closes it.
my %FROM;

# [ dsn, user, pass ]
sub _server {
  my @s = @ENV{qw(DBIO_TEST_SYBASE_DSN DBIO_TEST_SYBASE_USER DBIO_TEST_SYBASE_PASS)};
  return undef unless length($s[0] // '') and defined $s[1] and defined $s[2];
  return undef unless eval { require DBD::Sybase; 1 };
  return \@s;
}

# the DSN with its database swapped (as DBIO::Sybase::Deploy::_temp_dsn does)
sub _dsn_for {
  my ($class, $dsn, $database) = @_;
  return $dsn if $dsn =~ s/\bdatabase=[^;]*/database=$database/i;
  return $dsn =~ /[:;]\z/ ? "${dsn}database=$database" : "$dsn;database=$database";
}

sub _admin_dbh {
  my ($class) = @_;
  my ($dsn, $user, $pass) = @{ $class->_server };
  my $dbh = DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 });
  $dbh->do('USE master');   # CREATE/DROP DATABASE run from master only (Msg 1809)
  return $dbh;
}

# True when DBD::Sybase was built against FreeTDS (asked of a connection of its
# own, once).
my $FREETDS;
sub _freetds {
  my ($class) = @_;
  return $FREETDS if defined $FREETDS;
  return $FREETDS = 0 unless $class->_server;
  my $dbh = eval { $class->_admin_dbh };
  $FREETDS = ($dbh && ($dbh->{syb_oc_version} // '') =~ /freetds/i) ? 1 : 0;
  eval { $dbh->disconnect } if $dbh;
  return $FREETDS;
}


sub conformance_live_available { $_[0]->_server ? 1 : 0 }


sub conformance_connect {
  my ($class, $schema_class) = @_;
  my $server = $class->_server
    or DBIO::Exception->throw('conformance: no Sybase ASE server configured');
  my $name = $class->_database_name;
  $DATABASE{$schema_class} = $name;

  $schema_class->load_components('Sybase');
  my ($dsn, $user, $pass) = @$server;
  return $schema_class->connect($class->_dsn_for($dsn, $name), $user, $pass,
    { AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0,
      on_connect_call => 'datetime_setup' });
}

# The database the connection is in must be the case's own. DBD::Sybase cannot
# change into a database that is not there yet and then goes on in the login's
# default database (master or the test database), with only a warning: a
# connection made before L</conformance_namespace> created the database would
# put the case's tables there. So no statement of a case goes out before this
# has looked.
sub _assert_database {
  my ($class, $schema) = @_;
  my $want = $class->_database_of($schema);
  my ($got) = $schema->storage->dbh->selectrow_array('SELECT db_name()');
  DBIO::Exception->throw("conformance: the connection is in database "
    . (defined $got ? "'$got'" : '(unknown)') . ", not in '$want' of the case; "
    . 'refusing to write into it')
    unless defined $got and $got eq $want;
  return;
}


sub conformance_quote_ident {
  my ($class, $schema, $name) = @_;
  return DBIO::Sybase::Quote::quote_ident($name);
}

# The name of the next case's database. A hook for the test of the refusal: a
# subclass answers a name that is taken already.
sub _database_name { sprintf 'dbio_cf_%d_%d', $$, ++$SEQ }

sub _database_of {
  my ($class, $schema) = @_;
  my $name = $DATABASE{ ref $schema };
  DBIO::Exception->throw('conformance: this schema was not connected through '
    . 'conformance_connect') unless defined $name;
  return $name;
}


sub conformance_namespace {
  my ($class, $schema, $case) = @_;
  my $name  = $class->_database_of($schema);
  my $admin = $class->_admin_dbh;
  my $ok = eval {
    my ($there) = $admin->selectrow_array(
      'SELECT COUNT(*) FROM master..sysdatabases WHERE name = ?', undef, $name);
    DBIO::Exception->throw("conformance: the database $name exists already; "
      . 'refusing to use or drop a database the case did not create')
      if $there;
    $admin->do("CREATE DATABASE $name");
    # from here the database is ours; if the options fail it is dropped again
    my $set = eval {
      local $admin->{syb_err_handler} = sub { $_[1] > 10 ? 1 : 0 };
      for my $option ('abort tran on log full', 'select into/bulkcopy/pllsort') {
        my $sth = $admin->prepare("exec sp_dboption '$name', '$option', true");
        $sth->execute;
        do { 1 while $sth->fetchrow_arrayref } while $sth->{syb_more_results};
      }
      1;
    };
    unless ($set) {
      my $err = $@;
      eval { DBIO::Sybase::Deploy->new(schema => $schema)->_drop_temp_db($admin, $name); 1 }
        or $err .= "\nthe database $name was left on the server: $@";
      die $err;
    }
    1;
  };
  my $err = $@;
  $admin->disconnect;
  die $err unless $ok;
  return { name => $name, created => 1 };
}


sub conformance_install {
  my ($class, $schema, $case) = @_;
  $class->_assert_database($schema);
  $schema->deploy;
  return;
}


sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->_connect_target($schema, $to_class);
  DBIO::Sybase::Deploy->new(schema => $to)->upgrade(allow_destructive => 1);
  return $to;
}


sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->_connect_target($schema, $to_class);
  return DBIO::Sybase::Deploy->new(schema => $to);
}

# The target declaration connected to the database of the case.
sub _connect_target {
  my ($class, $schema, $to_class) = @_;
  my $name = $class->_database_of($schema);
  $DATABASE{$to_class} = $name;
  $FROM{$name} = $schema;
  my ($dsn, $user, $pass) = @{ $class->_server };
  $to_class->load_components('Sybase');
  my $to = $to_class->connect($class->_dsn_for($dsn, $name), $user, $pass,
    { AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0,
      on_connect_call => 'datetime_setup' });
  $class->_assert_database($to);
  return $to;
}


sub conformance_cleanup {
  my ($class, $schema, $case, $namespace) = @_;
  my $name = delete $DATABASE{ ref $schema };
  eval { $schema->storage->disconnect; 1 };
  if (defined $name and my $from = delete $FROM{$name}) {
    eval { $from->storage->disconnect; 1 };
  }
  return unless ref $namespace eq 'HASH' and $namespace->{created};
  $name = $namespace->{name};

  my $admin = $class->_admin_dbh;
  my $ok = eval {
    DBIO::Sybase::Deploy->new(schema => $schema)->_drop_temp_db($admin, $name);
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
  my $diff = DBIO::Sybase::Deploy->new(schema => $schema)->diff;
  return $diff->has_changes ? 0 : 1;
}


sub conformance_answered_through { { DDL => 2, Diff => 4, Bind => 1 } }


sub conformance_refusals {
  my ($class) = @_;
  my $refusals = {
  'ddl-default-digit-string' => {
    kind   => 'deviation',
    fact   => qr/expected '007', read back '007 +'/,
    reason => 'a char(n) column pads the value with blanks to its length',
  },
  'ddl-enum-value-apostrophe' => {
    kind   => 'server',
    reason => qr/type 'enum'.*is refused: ASE has no enum type/s,
  },
  'ddl-type-size-bit' => {
    kind   => 'server',
    reason => qr/size '8' on type 'bit'.*is refused: bit has no length in ASE/s,
  },
  'ddl-base-types-roundtrip' => {
    kind   => 'server',
    reason => qr/NULL in a bit column is refused: ASE cannot hold NULL in a BIT column/,
  },
  'ddl-fk-actions' => {
    kind   => 'server',
    reason => qr/ASE has no referential actions/,
  },
  # Diff list (karr k97)
  'diff-table-added-complete' => {
    kind   => 'server',
    reason => qr/ASE has no referential actions/,
  },
  'diff-fk-action-changed' => {
    kind   => 'server',
    reason => qr/ASE has no referential actions/,
  },
  'diff-column-added-not-null-populated' => {
    kind   => 'server',
    reason => qr/table base, column code: .*the add is refused: ASE requires a default clause/s,
  },
  'diff-column-added-expression-default' => {
    kind   => 'server',
    reason => qr/table base, column created: .*expression default is refused/s,
  },
  'diff-not-null-over-nulls' => {
    kind   => 'server',
    reason => qr/table opt, column c: making the column NOT NULL is refused/,
  },
  'ddl-qualified-source-name' => {
    kind   => 'server',
    reason => qr/a name with a dot is refused/,
  },
};

  # Bind list (karr k97). ASE keeps the empty string as one space in a
  # char/varchar column, and converts '' to 0 for an integer one.
  $refusals->{'bind-empty-string'} = {
    kind   => 'deviation',
    fact   => qr/Val\.s create: expected '', read back ' '.*Val: the server accepted a row it must reject/s,
    reason => "ASE has no empty string: '' is stored as a single space in a "
      . "varchar column (Transact-SQL Users Guide: the empty string literal is a "
      . "single space), so it reads back as ' ', and for an integer column it "
      . 'is converted to 0, so n => \'\' is accepted instead of rejected '
      . '(measured, ASE 16.0 SP02, datalength 1)',
  };

  # Over FreeTDS the content of a TEXT or IMAGE column
  # cannot be written (ct_data_info), and the writer refuses it before it
  # sends anything. Seven cases write LOB content, the base type text being
  # one. Not over Open Client libraries: nothing is declared there, as nothing
  # was measured there.
  if ($class->_freetds) {
    my $reason = qr/column .*is refused: FreeTDS cannot write the content of a TEXT or IMAGE column/s;
    $refusals->{$_} = { kind => 'server', reason => $reason } for qw(
      bind-long-string bind-binary bind-lob-empty-and-large
      bind-lob-row-operations
    );
    # its column is a TEXT: the LOB refusal comes first; a character beyond
    # ASCII for a varchar is refused by _refuse_non_ascii_binds (t/114)
    $refusals->{'bind-non-ascii'} = { kind => 'server', reason => qr/(?:column .*is refused: FreeTDS cannot write the content of a TEXT or IMAGE column|has a character beyond ASCII and is refused)/s };
  }
  return $refusals;
}


sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  my $dbh = $schema->storage->dbh;

  if ($name eq 'table_in_namespace') {
    my ($n) = $dbh->selectrow_array(
      q{SELECT COUNT(*) FROM sysobjects o JOIN sysusers u ON u.uid = o.uid }
      . q{WHERE o.type IN ('U','V') AND u.name = ? AND o.name = ?},
      undef, $args->{namespace}, $args->{unqualified});
    return $n ? 1 : 0;
  }

  my $table = $args->{table};
  my $model = DBIO::Sybase::Introspect->new(dbh => $dbh)->model;
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
    return $col && $col->{is_auto_increment} ? 1 : 0;
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
    return scalar grep { ($_->{origin} // '') ne 'pk' and $same->($_->{columns}) }
      values %$indexes;
  }

  DBIO::Exception->throw("unknown conformance fact '$name'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Test::Conformance - Answers the shared conformance case table for the Sybase ASE driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::Sybase::Test::Conformance;
  DBIO::Sybase::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says
how to reach an ASE server, how to install a declaration into it through
C<< $schema->deploy >> and how to upgrade it through L<DBIO::Sybase::Deploy>,
and how to read a fact back through L<DBIO::Sybase::Introspect>.

B<The server.> C<DBIO_TEST_SYBASE_DSN>, C<_USER> and C<_PASS> (DBD::Sybase;
C<TDSVER=5.0> under FreeTDS). Without them, or without the DBD, only the
declarations are checked. The login needs C<CREATE DATABASE>, and the server
room for it (Msg 1810 otherwise, see F<README.md>, "Live tests"):
L<DBIO::Sybase::Deploy/diff> builds its target in a throwaway database, and so
does every case here.

B<The namespace of a case is a database of its own>,
C<dbio_cf_E<lt>pidE<gt>_E<lt>nE<gt>>. ASE has no schemas to bind a session to
-- a table lands in the owner C<dbo> of the database the connection is in -- and
the diff compares the whole database, so one case's tables would come back as
C<DROP> in the next. A database per case keeps C<dbo> empty.
L</conformance_connect> only picks the name -- the connection has to name it --
and builds the lazy connection; L</conformance_namespace> creates the database
and hands back a token C<< { name =E<gt> ..., created =E<gt> 1 } >>, and
L</conformance_cleanup> drops exactly what that token names. The runner calls
the cleanup always, also when the namespace threw: a name that is taken already
makes the namespace throw without a token, and the database that was there
before the case is never dropped.

The class names no storage class and never decides the driver: the schema
component C<Sybase> declares it, the DSN names the access path.

=head1 METHODS

=head2 conformance_live_available

True when a server is configured (see L</DESCRIPTION>) and L<DBD::Sybase> loads.

=head2 conformance_connect

Picks the name of the case's database, loads the C<Sybase> schema component
into the case's schema class and connects to that database.

=head2 conformance_quote_ident

The name as L<DBIO::Sybase::Quote> writes it into DDL. The runner asks before
the case's database exists, and the default (the quote character of the SQL
maker) would connect the lazy storage for the answer.

=head2 conformance_namespace

Creates the database of the case, on an admin connection of its own, and
returns the token C<< { name, created } >> for L</conformance_cleanup>. A
database of that name that exists already makes it throw, touching nothing and
returning no token. The database gets C<abort tran on log full> (a full log is
refused instead of suspending the session, as for the throwaway database of
L<DBIO::Sybase::Deploy>) and C<select into/bulkcopy/pllsort> (the data-copying
C<ALTER TABLE> of an upgrade needs it).

=head2 conformance_install

Installs the declaration with C<< $schema->deploy >>.

=head2 conformance_upgrade

Connects the C<to> declaration to the database of the case and runs
L<DBIO::Sybase::Deploy/upgrade> over it with C<< allow_destructive => 1 >>
(the guard itself is the deploy cases, L</conformance_deploy>). The database is
the case's own, so the connection is made anew (a handle cannot be shared: the
temporary database of the diff is reached through a connection derived from
this one's DSN).

=head2 conformance_deploy

Same connecting as L</conformance_upgrade>, but returns the deploy object over
the connected target schema, C<< DBIO::Sybase::Deploy->new(schema => $to) >>,
for the deploy cases of the Diff list (ADR 0080): C<apply> and C<upgrade> are
those of L<DBIO::Deploy::Base>, C<dry_run> executes nothing, and a diff with a
drop or a lossy change needs C<allow_destructive>.

=head2 conformance_cleanup

Disconnects, and drops the database the token names (the tables and keys go
with it), repeating the drop on Msg 3702 as L<DBIO::Sybase::Deploy> does. Without
a token nothing is dropped. Also after a failed case. The throwaway databases
of a diff are the diff's own to drop; a C<_dbio_tmp_*> database left by a crash
is found by name.

=head2 conformance_diff_is_empty

True when L<DBIO::Sybase::Deploy/diff> of the installed database against the
same declaration has no changes.

=head2 conformance_answered_through

C<< { DDL => 2, Diff => 4, Bind => 1 } >>: the answers are written against
version 2 of the DDL case table, version 4 of the Diff table and version 1 of the Bind table
(L<DBIO::Test::Conformance/table_version>).

Version 3 of the Diff list replaces C<diff-column-dropped-with-index> by
C<diff-indexed-column-dropped>; it runs. Version 4 adds the
deploy cases, answered through L</conformance_deploy>.

=head2 conformance_refusals

DDL list: C<ddl-enum-value-apostrophe>, C<ddl-type-size-bit> and
C<ddl-base-types-roundtrip> (a nullable C<bit> is Msg 2718) are refused by
L<DBIO::Sybase::DDL> before the server is asked, C<ddl-fk-actions> by the
referential-action check, C<ddl-qualified-source-name> by
L<DBIO::Sybase::Quote> (a dot is C<owner.name>) -- all C<server>;
C<ddl-default-digit-string> is a deviation (a C<char(n)> is blank-padded).
C<ddl-type-size-char> is answered right: the storage sets C<string_rtruncation
on> on every connection, so a string too long for its column is Msg 9502 and
not cut without a word.

Diff list: C<diff-table-added-complete> (a CASCADE),
C<diff-column-added-not-null-populated> (ASE wants a default on a NOT NULL
add, also on an empty table), C<diff-column-added-expression-default> (Msg
13918: no expression default on a NOT NULL add) and
C<diff-not-null-over-nulls> (L<DBIO::Sybase::Deploy/apply> looks for NULLs
first, Msg 515) are C<server> refusals; C<diff-default-removed> is answered
right (the comparator reports the dropped default,
L<DBIO::Sybase::Diff::Column> writes C<REPLACE col DEFAULT NULL>).

Bind list: C<bind-empty-string> is a deviation (ASE keeps C<''> as one space in
a varchar column and converts it to 0 for an integer one). Over FreeTDS (asked of
a connection, C<_freetds>) four cases are C<server> refusals,
C<bind-long-string>, C<bind-binary>, C<bind-lob-empty-and-large> and
C<bind-lob-row-operations>, and so is C<bind-non-ascii> (its column is a TEXT):
FreeTDS cannot write the content of a TEXT or IMAGE column (C<ct_data_info>),
and L<DBIO::Sybase::Storage::ASE::LOBWriter> refuses before it sends anything.
A character beyond ASCII for a varchar or univarchar column is refused over
FreeTDS by C<_refuse_non_ascii_binds> (t/114, t/115): the client library
reports the failed conversion after the row was written, with a blank in it.
Nothing is declared over the Open Client libraries, where nothing was measured.
C<bind-digit-string-leading-zero>, C<bind-integer-string-in-expression>,
C<bind-question-mark-in-literal> and C<bind-numeric-exact> are answered right.
C<ddl-qualified-source-name> is
refused always: the DDL never writes C<owner.table> (a dot is refused by
L<DBIO::Sybase::Quote>), whether or not the owner exists.

Of the two halves of U13 (Diff table version 2),
C<diff-constraint-changed> runs and C<diff-fk-action-changed> is refused like
every C<ON DELETE CASCADE>, naming C<parent_id>.

=head2 conformance_fact

Reads one fact through L<DBIO::Sybase::Introspect> (owner C<dbo> of the case's
database); the vocabulary is the one of L<DBIO::Test::Conformance/Facts>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::Sybase::Deploy> - install and diff, as the cases reach them

=item * L<DBIO::Sybase::Introspect> - what the facts are read through

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
