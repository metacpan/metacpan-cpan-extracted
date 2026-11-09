package DBIO::MySQL::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the MySQL and MariaDB driver

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::Conformance';

use DBI ();
use DBIO::Exception ();
use DBIO::MySQL::Introspect ();
use DBIO::MySQL::Deploy ();
use DBIO::MySQL::DDL ();
use DBIO::MySQL::Identifier ();


my $SEQ = 0;
# schema class => the name of its case's database
my %NAMESPACE;
# schema class => 1 when this run created the database
my %CREATED;
# schema class => { 'database.table' => 1 }: the tables this run made in other databases
my %QUALIFIED;
my $SERVER;

sub _admin_connect {
  my ($dsn) = @_;
  return DBI->connect($dsn // $ENV{DBIO_TEST_MYSQL_DSN},
    $ENV{DBIO_TEST_MYSQL_USER}, $ENV{DBIO_TEST_MYSQL_PASS}, {
      AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0,
    });
}

# The DSN of the case: the one of the environment, naming the database of
# the case.
sub _case_dsn {
  my ($name) = @_;
  my $dsn = $ENV{DBIO_TEST_MYSQL_DSN};
  $dsn =~ s/\b(?:database|dbname)=[^;]*/database=$name/i
    or $dsn .= ";database=$name";
  return $dsn;
}


sub conformance_live_available {
  my ($driver) = ($ENV{DBIO_TEST_MYSQL_DSN} // '') =~ /\Adbi:(\w+):/i
    or return 0;
  return eval { require "DBD/$driver.pm"; 1 } ? 1 : 0;
}


sub conformance_connect {
  my ($class, $schema_class) = @_;
  my $name = sprintf 'dbio_cf_%d_%d', $$, ++$SEQ;

  my $admin = _admin_connect();
  $admin->do('CREATE DATABASE ' . DBIO::MySQL::Identifier::quote_ident($name));
  $admin->disconnect;
  $NAMESPACE{$schema_class} = $name;
  $CREATED{$schema_class}   = 1;

  $schema_class->load_components('MySQL');
  my $dsn = _case_dsn($name);
  my %attrs = (
    AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0,
  );
  $attrs{mysql_enable_utf8mb4} = 1 if $dsn =~ /\Adbi:mysql:/i;
  %attrs = (%attrs, $class->conformance_connect_attributes);
  return $schema_class->connect($dsn,
    @ENV{qw(DBIO_TEST_MYSQL_USER DBIO_TEST_MYSQL_PASS)}, \%attrs);
}


sub conformance_connect_attributes { return }

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
  my ($n) = $schema->storage->dbh->selectrow_array(
    'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = ?',
    undef, $name);
  DBIO::Exception->throw("conformance: the database '$name' is not empty")
    if $n;
  return { name => $name };
}


sub conformance_install {
  my ($class, $schema, $case) = @_;

  my @qualified = DBIO::MySQL::DDL->qualified_tables($schema);
  if (@qualified) {
    my $dbh = _admin_connect();
    for my $pair (@qualified) {
      my ($table, $database) = @$pair;
      my (undef, $short) = DBIO::MySQL::Identifier::split_table_name($table);
      my ($there) = $dbh->selectrow_array(
        'SELECT COUNT(*) FROM information_schema.tables '
        . 'WHERE table_schema = ? AND table_name = ?', undef, $database, $short);
      DBIO::Exception->throw("conformance: the table '$table' is on the server "
        . 'already; it is not the run\'s to use or drop') if $there;
      $QUALIFIED{ ref $schema }{$table} = 1;
    }
    $dbh->disconnect;
  }

  $schema->deploy;
  return;
}


sub conformance_cleanup {
  my ($class, $schema, $case, $namespace) = @_;
  my $created   = delete $CREATED{ ref $schema };
  my $name      = delete $NAMESPACE{ ref $schema };
  my $qualified = delete $QUALIFIED{ ref $schema } || {};
  eval { $schema->storage->disconnect };

  if (my @tables = sort keys %$qualified) {
    my $dbh = _admin_connect();
    $dbh->do('DROP TABLE IF EXISTS ' . DBIO::MySQL::Identifier::quote_table($_)) for @tables;
    $dbh->disconnect;
  }

  if ($created && defined $name) {
    my $dbh = _admin_connect();
    $dbh->do('DROP DATABASE IF EXISTS ' . DBIO::MySQL::Identifier::quote_ident($name));
    $dbh->disconnect;
  }
  return;
}


sub conformance_diff_is_empty {
  my ($class, $schema, $case) = @_;
  my $diff = DBIO::MySQL::Deploy->new(schema => $schema)->diff;
  return $diff->has_changes ? 0 : 1;
}


sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  my $name = $class->_namespace_of($schema);
  my $to = $class->_connect_target($to_class, $name);

  # A refusal ends the case with the installed schema: the database stays
  # its, and its cleanup drops it.
  my $ok = eval { DBIO::MySQL::Deploy->new(schema => $to)->upgrade(allow_destructive => 1); 1 };
  my $err = $@;
  unless ($ok) {
    eval { $to->storage->disconnect };
    die $err;
  }

  $class->_hand_over_namespace($schema, $to_class, $name);
  return $to;
}


sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  my $name = $class->_namespace_of($schema);
  my $to = $class->_connect_target($to_class, $name);
  $class->_hand_over_namespace($schema, $to_class, $name);
  return DBIO::MySQL::Deploy->new(schema => $to);
}

# The target class, connected to the database of the installed schema.
sub _connect_target {
  my ($class, $to_class, $name) = @_;
  $to_class->load_components('MySQL');
  my $dsn = _case_dsn($name);
  my %attrs = (
    AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0,
  );
  $attrs{mysql_enable_utf8mb4} = 1 if $dsn =~ /\Adbi:mysql:/i;
  return $to_class->connect($dsn,
    @ENV{qw(DBIO_TEST_MYSQL_USER DBIO_TEST_MYSQL_PASS)}, \%attrs);
}

# The database now belongs to the target's class: the runner cleans up
# through the schema it gets back, and closes $schema itself afterwards.
sub _hand_over_namespace {
  my ($class, $schema, $to_class, $name) = @_;
  $NAMESPACE{$to_class} = $name;
  $CREATED{$to_class}   = delete $CREATED{ ref $schema };
  delete $NAMESPACE{ ref $schema };
  $QUALIFIED{$to_class} = delete $QUALIFIED{ ref $schema } if $QUALIFIED{ ref $schema };
  return;
}


sub conformance_answered_through { { DDL => 2, Diff => 4, Bind => 1 } }


sub conformance_server_is_mariadb {
  return $SERVER if defined $SERVER;
  my $dbh = _admin_connect();
  my ($version) = $dbh->selectrow_array('SELECT VERSION()');
  $dbh->disconnect;
  return $SERVER = ($version // '') =~ /mariadb/i ? 1 : 0;
}


sub conformance_refusals {
  my ($class) = @_;
  my $refusals = {
    'diff-column-added-not-null-populated' => {
      kind   => 'server',
      reason => qr/NOT NULL without a default, and table base holds rows/,
    },
    'diff-not-null-over-nulls' => {
      kind   => 'server',
      reason => qr/holds rows where it is NULL/,
    },
  };
  $refusals->{'ddl-qualified-source-name'} = {
    kind   => 'server',
    reason => qr/the database other does not exist/,
  } if $class->conformance_live_available && !$class->_database_exists('other');
  return $refusals;
}

# Whether the server has a database of exactly that name; asked once per name
# and process, and read only.
my %DATABASE_EXISTS;
sub _database_exists {
  my ($class, $name) = @_;
  return $DATABASE_EXISTS{$name} //= do {
    my $dbh = _admin_connect();
    my ($found) = $dbh->selectrow_array(
      'SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = ?',
      undef, $name);
    $dbh->disconnect;
    $found ? 1 : 0;
  };
}


sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  my $dbh   = $schema->storage->dbh;
  my $table = $args->{table};

  if ($name eq 'table_in_namespace') {
    my ($n) = $dbh->selectrow_array(
      'SELECT COUNT(*) FROM information_schema.tables '
      . 'WHERE table_schema = ? AND table_name = ?',
      undef, $args->{namespace}, $args->{unqualified});
    return $n ? 1 : 0;
  }

  my $model = DBIO::MySQL::Introspect->new(dbh => $dbh)->model;
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

  my $indexes = $model->{indexes}{$table} || {};
  if ($name eq 'primary_key_columns') {
    return [ map { $_->{column_name} }
             sort { $a->{pk_position} <=> $b->{pk_position} }
             grep { $_->{is_pk} } @$columns ];
  }
  if ($name eq 'unique_exists') {
    return (grep { $_->{origin} eq 'u' and $same->($_->{columns}) }
            values %$indexes) ? 1 : 0;
  }
  if ($name eq 'foreign_key_count') {
    return scalar @{ $model->{foreign_keys}{$table} || [] };
  }
  if ($name eq 'index_count') {
    return scalar grep { $_->{origin} ne 'pk' and $same->($_->{columns}) }
                  values %$indexes;
  }

  DBIO::Exception->throw("unknown conformance fact '$name'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Test::Conformance - Answers the shared conformance case table for the MySQL and MariaDB driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::MySQL::Test::Conformance;
  DBIO::MySQL::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says how to
reach a MySQL or MariaDB server, how to install a declaration into it through
L<DBIO::MySQL::Deploy>, and how to read a fact back through
L<DBIO::MySQL::Introspect>.

The server is the one C<DBIO_TEST_MYSQL_DSN>, C<DBIO_TEST_MYSQL_USER> and
C<DBIO_TEST_MYSQL_PASS> name; without the DSN (or without a DBD) only the
declarations are checked. A run needs an account that may create databases:
L<DBIO::MySQL::Deploy/diff> builds its target in a temporary one. MySQL and
MariaDB are two servers behind one set of variables, and the class is run once
against each; what holds on one only is declared per server by
L</conformance_refusals>, which asks the server which it is.

B<The namespace of a case is a database of its own.> Every case gets a
database C<dbio_cf_E<lt>pidE<gt>_E<lt>nE<gt>>, created by
L</conformance_connect> over a connection of its own; the DSN of the case
names it, so the diff -- which compares the whole of the current database --
sees nothing but the case. L</conformance_namespace> refuses a database that
is not empty, and L</conformance_cleanup> drops a database only when this run
created it.

The class names no storage class and never decides the driver, the DSN does
(see L</conformance_connect>).

=head1 METHODS

=head2 conformance_live_available

True when C<DBIO_TEST_MYSQL_DSN> is set and the DBD it names loads
(L<DBD::mysql> or L<DBD::MariaDB>).

=head2 conformance_connect

Creates the database of the case, loads the C<MySQL> schema component into
the case's schema class and connects to that database. C<storage_type> is not
set by this class beyond what the component does: the declared driver is
MySQL's, the DSN only says which DBD reaches it.

Over L<DBD::mysql> the connection asks for C<< mysql_enable_utf8mb4 => 1 >>,
in the attribute hash -- the DSN is ignored for it. Without it the DBD returns
text as the bytes it stores and the cases that bind characters read bytes back.
The driver keeps that default, since an application may hold bytes in a text
column on purpose; one that wants characters connects like this.
L<DBD::MariaDB> takes characters without being asked and refuses the attribute.

=head2 conformance_connect_attributes

Connect attributes added to those of L</conformance_connect>, as a list of
pairs; none here. A subclass that runs the Bind list over the C<future_io>
transport returns C<< async => 'future_io' >>.

=head2 conformance_namespace

Returns the name of the case's database as the token for
L</conformance_cleanup>, after checking that it holds no table and no view.
A database that is not empty ends the case.

=head2 conformance_install

Installs the declaration with C<< $schema->deploy >>, the public entry point,
which hands over to L<DBIO::MySQL::Deploy/install>.

A source named C<database.table> (C<ddl-qualified-source-name>) is made in a
database that is not the case's, so the class takes care of it: a table of
that name that is on the server already is not the run's to use or drop, and
ends the case; one that is not is marked, and L</conformance_cleanup> drops it.
The database itself is never created or dropped.

=head2 conformance_cleanup

Drops the database of the token when L</conformance_connect> of this run
created it, the tables L</conformance_install> marked in other databases, and
disconnects. Nothing else is dropped: without a mark no
database is touched. The drop goes through a connection of its own.

=head2 conformance_diff_is_empty

True when L<DBIO::MySQL::Deploy/diff> of the installed database against the
same declaration has no changes.

=head2 conformance_upgrade

Connects the target schema class to the database of the installed one and
runs L<DBIO::MySQL::Deploy/upgrade> -- the public entry point -- through it.
The connection is made like L</conformance_connect> makes it, to the same
database; the target class takes over the namespace (and the duty to drop it)
of the installed one, since the runner hands only the returned schema to
L</conformance_cleanup>. The upgrade runs with C<< allow_destructive => 1 >>:
the cases of the table are about what the diff does (a dropped column, a
changed type), the guard that holds a destructive diff back has its own cases
(C<diff-deploy-destructive-guard>, run through L</conformance_deploy>). A
refusal of the diff is thrown from here as it came; the database then stays
with the installed schema, whose cleanup drops it.

=head2 conformance_deploy

The deploy object over the target schema, for the deploy cases of the Diff list
(table version 4): the target class is connected to the database of the
installed one exactly as L</conformance_upgrade> connects it, and takes over its
namespace and the duty to drop it. Returns
C<< DBIO::MySQL::Deploy->new(schema => $to) >>; the runner calls C<apply> and
C<upgrade> on it.

=head2 conformance_answered_through

The table versions the answers were written against, per area:
C<< { DDL => 2, Diff => 4, Bind => 1 } >>, every list as it stands (version 2 of the DDL
list splits the type-size case into C<ddl-type-size-char> and
C<ddl-type-size-bit>, version 2 of the Diff list splits U13 into
C<diff-constraint-changed> and C<diff-fk-action-changed>, both answered right
on MySQL and MariaDB).

Version 3 of the Diff list replaces C<diff-column-dropped-with-index> by
C<diff-indexed-column-dropped>; it runs.

Version 4 of the Diff list adds the deploy cases (C<diff-deploy-*>):
they run through L</conformance_deploy>, which hands the runner the
L<DBIO::MySQL::Deploy> object, so C<apply> and C<upgrade> are the base class's.

=head2 conformance_server_is_mariadb

True when the server behind C<DBIO_TEST_MYSQL_DSN> is a MariaDB, by its
C<SELECT VERSION()>; asked once.

=head2 conformance_refusals

Two refusals are declared, and a third only on a server that lacks something.

C<diff-column-added-not-null-populated> and C<diff-not-null-over-nulls> are
refused by the engine's rules, before the first statement, by
L<DBIO::MySQL::Deploy/_refuse_unfillable>, naming table and column: there is no
value for the rows a table holds when a C<NOT NULL> column without a default is
added (the server would invent the implicit default of the type), and a
C<NOT NULL> over a C<NULL> cannot hold (strict: error 1138; otherwise the
C<NULL> is silently rewritten). Maintainer decision 2026-10-25, as in the
SQLite and PostgreSQL drivers.

C<ddl-qualified-source-name> writes the table C<t> into the database C<other>
(C<< table('other.t') >>). The driver creates no database, and the
case does not either, so the answer depends on the server: where a database
C<other> exists, the table is made in it and the case runs through, read back
by L</conformance_fact>; where it does not, L<DBIO::MySQL::Deploy/install>
refuses, naming table and database, before its first statement, and the case is
declared a C<server> refusal. Which of the two holds is asked of the server
(C<_database_exists>), read only, in the manner of the Oracle driver's check of
its user C<other>.

=head2 conformance_fact

Reads one fact through L<DBIO::MySQL::Introspect>, of the database of the
case; the vocabulary is the one of L<DBIO::Test::Conformance/Facts>.
C<table_in_namespace> asks the namespace named, a database.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::MySQL::Deploy> - install and diff, as the cases reach them

=item * L<DBIO::MySQL::Introspect> - what the facts are read through

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
