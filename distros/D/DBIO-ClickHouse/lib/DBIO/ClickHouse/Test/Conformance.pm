package DBIO::ClickHouse::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the ClickHouse driver

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::Conformance';

use DBI ();
use DBIO::Exception ();
use DBIO::ClickHouse::Introspect ();
use DBIO::ClickHouse::Deploy ();
use DBIO::ClickHouse::DDL ();
use DBIO::ClickHouse::DDL::Emit qw(create_database drop_database split_table_name quote_ident);


my $SEQ = 0;
# schema class => the name of its case's database
my %NAMESPACE;
# schema class => 1 when this run created the database
my %CREATED;
# schema class => { 'database.table' => 1 }: the tables this run made in other databases
my %QUALIFIED;

sub _env { $ENV{"DBIO_TEST_CLICKHOUSE_$_[0]"} // '' }

# The DSN of the case: the one of the environment, naming the database of the
# case.
sub _case_dsn {
  my ($name) = @_;
  my $dsn = $ENV{DBIO_TEST_CLICKHOUSE_DSN};
  $dsn =~ s/\b(?:database|dbname)=[^;]*/database=$name/i
    or $dsn .= ";database=$name";
  return $dsn;
}

sub _attrs {
  my ($dsn) = @_;
  my %attrs = ( AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0 );
  # DBD::mysql hands text back as bytes unless asked; DBD::MariaDB decodes
  # unconditionally and refuses the attribute (see DBIO::ClickHouse::Test).
  $attrs{mysql_enable_utf8mb4} = 1 if $dsn =~ /\Adbi:mysql:/i;
  return \%attrs;
}

# A connection of its own to the database named in the DSN, for the statements
# that create and drop the database of a case.
sub _admin_connect {
  return DBI->connect($ENV{DBIO_TEST_CLICKHOUSE_DSN},
    _env('DBUSER'), _env('DBPASS'), _attrs($ENV{DBIO_TEST_CLICKHOUSE_DSN}));
}


sub conformance_live_available {
  my ($driver) = ($ENV{DBIO_TEST_CLICKHOUSE_DSN} // '') =~ /\Adbi:(\w+):/i
    or return 0;
  return eval { require "DBD/$driver.pm"; 1 } ? 1 : 0;
}


sub conformance_connect {
  my ($class, $schema_class) = @_;
  my $name = sprintf 'dbio_cf_%d_%d', $$, ++$SEQ;

  my $admin = _admin_connect();
  $admin->do(create_database(name => $name));
  $admin->disconnect;
  $NAMESPACE{$schema_class} = $name;
  $CREATED{$schema_class}   = 1;

  $schema_class->load_components('ClickHouse');
  my $dsn = _case_dsn($name);
  return $schema_class->connect($dsn, _env('DBUSER'), _env('DBPASS'), _attrs($dsn));
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
  my ($n) = $schema->storage->dbh->selectrow_array(
    'SELECT count() FROM system.tables WHERE database = ?', undef, $name);
  DBIO::Exception->throw("conformance: the database '$name' is not empty")
    if $n;
  return { name => $name };
}


sub conformance_install {
  my ($class, $schema, $case) = @_;

  my @qualified = DBIO::ClickHouse::DDL->qualified_tables($schema);
  if (@qualified) {
    my $dbh = _admin_connect();
    for my $pair (@qualified) {
      my ($table, $database) = @$pair;
      my (undef, $short) = split_table_name($table);
      my ($there) = $dbh->selectrow_array(
        'SELECT count() FROM system.tables WHERE database = ? AND name = ?',
        undef, $database, $short);
      DBIO::Exception->throw("conformance: the table '$table' is on the server "
        . 'already; it is not the run\'s to use or drop') if $there;
      $QUALIFIED{ ref $schema }{$table} = 1;
    }
    $dbh->disconnect;
  }

  DBIO::ClickHouse::Deploy->new(schema => $schema)->install;
  return;
}


sub conformance_cleanup {
  my ($class, $schema, $case, $namespace) = @_;
  my $created = delete $CREATED{ ref $schema };
  my $name    = delete $NAMESPACE{ ref $schema };
  my $qualified = delete $QUALIFIED{ ref $schema } || {};
  eval { $schema->storage->disconnect };

  if (my @tables = sort keys %$qualified) {
    my $dbh = _admin_connect();
    for my $table (@tables) {
      my ($database, $short) = split_table_name($table);
      $dbh->do('DROP TABLE IF EXISTS ' . quote_ident($database) . '.' . quote_ident($short));
    }
    $dbh->disconnect;
  }

  if ($created && defined $name) {
    my $dbh = _admin_connect();
    $dbh->do(drop_database(name => $name, if_exists => 1));
    $dbh->disconnect;
  }
  return;
}


sub conformance_diff_is_empty {
  my ($class, $schema, $case) = @_;
  my $diff = DBIO::ClickHouse::Deploy->new(schema => $schema)->diff;
  return $diff->has_changes ? 0 : 1;
}


sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  my $name = $class->_namespace_of($schema);
  my $to   = $class->_connect_target($to_class, $name);

  my $ok  = eval { DBIO::ClickHouse::Deploy->new(schema => $to)->upgrade(allow_destructive => 1); 1 };
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
  my $to   = $class->_connect_target($to_class, $name);
  $class->_hand_over_namespace($schema, $to_class, $name);
  return DBIO::ClickHouse::Deploy->new(schema => $to);
}

# The target class, connected to the database of the installed schema.
sub _connect_target {
  my ($class, $to_class, $name) = @_;
  $to_class->load_components('ClickHouse');
  my $dsn = _case_dsn($name);
  return $to_class->connect($dsn, _env('DBUSER'), _env('DBPASS'), _attrs($dsn));
}

# The database now belongs to the target's class: the runner cleans up through
# the schema it gets back, and closes $schema itself afterwards.
sub _hand_over_namespace {
  my ($class, $schema, $to_class, $name) = @_;
  $NAMESPACE{$to_class} = $name;
  $CREATED{$to_class}   = delete $CREATED{ ref $schema };
  $QUALIFIED{$to_class} = delete $QUALIFIED{ ref $schema } if $QUALIFIED{ ref $schema };
  delete $NAMESPACE{ ref $schema };
  return;
}


sub conformance_answered_through { { DDL => 2, Diff => 4, Bind => 1 } }


sub conformance_refusals {
  my ($class) = @_;
  my $fk     = qr/is a foreign key constraint, which ClickHouse cannot create/;
  my $unique = qr/unique constraint .* cannot be enforced/;
  my $auto   = qr/is auto-increment, which ClickHouse cannot build/;
  my $refusals = {
    'ddl-unique-constraint' => { kind => 'server', reason => $unique },
    'ddl-unique-not-null-without-pk' => { kind => 'server', reason => $unique },
    'ddl-foreign-key'              => { kind => 'server', reason => $fk },
    'ddl-fk-actions'               => { kind => 'server', reason => $fk },
    'ddl-fk-two-rels-one-column'   => { kind => 'server', reason => $fk },
    'ddl-fk-table-order'           => { kind => 'server', reason => $fk },
    'ddl-index-on-unique-columns'  => { kind => 'server', reason => $unique },
    'ddl-auto-increment' => { kind => 'server', reason => $auto },
    'diff-auto-increment-kept' => { kind => 'server', reason => $auto },
    'bind-lob-row-operations'  => { kind => 'server', reason => $auto },
    'ddl-type-size-bit' => {
      kind   => 'server',
      reason => qr/size '8' on type 'bit' is refused: ClickHouse has no BIT type/,
    },
    'ddl-type-size-char' => {
      kind   => 'deviation',
      fact   => qr/column_size of Sized\.c: expected '10', the server shows NULL; Sized: the server accepted a row it must reject/,
      reason => 'ClickHouse has no CHAR(n) with a character limit: the portable '
              . 'character(10) is a String of any length, stored whole and read '
              . 'back without a size; the only bounded string, FixedString(N), '
              . 'counts bytes (not characters) and pads with NUL bytes, which '
              . 'is not what CHAR(n) means anywhere else, so the driver '
              . 'offers it only as opt-in extra->{fixed_string} and adds no '
              . 'CHECK for the length '
              . '(https://clickhouse.com/docs/sql-reference/data-types/fixedstring)',
    },
    'diff-column-type-change' => {
      kind   => 'deviation',
      fact   => qr/column_size of Num\.n: expected '20', the server shows NULL/,
      reason => 'the varchar(20) the column is changed to is a String, which '
              . 'has no length and reads back without a size '
              . '(https://clickhouse.com/docs/sql-reference/data-types/string); '
              . 'the type change itself and the rows are right',
    },
    'bind-numeric-exact' => {
      kind   => 'deviation',
      fact   => qr/read back '-?1234567890123456\.789'/,
      reason => 'the value is stored exactly in Decimal(38, 4); the server '
              . 'formats it without trailing fractional zeros, so '
              . '1234567890123456.7890 reads back as 1234567890123456.789 '
              . '(the same number, a shorter spelling: '
              . 'https://clickhouse.com/docs/sql-reference/data-types/decimal)',
    },

    # The Diff list. A case whose declaration carries a foreign key or a
    # unique constraint is refused when the declaration is installed or built
    # into the scratch database, as above.
    'diff-table-added-complete'     => { kind => 'server', reason => $fk },
    'diff-indexed-column-dropped'   => { kind => 'server', reason => $unique },
    'diff-fk-dropped'               => { kind => 'server', reason => $fk },
    'diff-fk-added-to-new-unique'   => { kind => 'server', reason => $fk },
    'diff-constraint-changed'       => { kind => 'server', reason => $fk },
    'diff-fk-action-changed'        => { kind => 'server', reason => $fk },

    # The two cases the engine would "apply" by writing something nobody
    # wrote. The upgrade reads the table first and refuses before the first
    # statement (Deploy::_check_before_apply).
    'diff-column-added-not-null-populated' => {
      kind   => 'server',
      reason => qr/NOT NULL without a default to a table that holds rows/,
    },
    'diff-not-null-over-nulls' => {
      kind   => 'server',
      reason => qr/is Nullable and holds \d+ NULL row/,
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
      'SELECT count() FROM system.databases WHERE name = ?', undef, $name);
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
      'SELECT count() FROM system.tables WHERE database = ? AND name = ?',
      undef, $args->{namespace}, $args->{unqualified});
    return $n ? 1 : 0;
  }

  my $model = DBIO::ClickHouse::Introspect->new(dbh => $dbh)->model;
  my $entry = $model->{tables}{$table};

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
    return undef unless $col;
    return DBIO::ClickHouse::Introspect::Util->normalize_type($col->{data_type})->{size};
  }
  if ($name eq 'column_auto_increment') {
    # no identity column exists; the only generated key is a UUID default
    my ($col) = grep { $_->{column_name} eq $args->{column} } @$columns;
    return $col && ($col->{default_value} // '') =~ /generateUUIDv4/ ? 1 : 0;
  }
  if ($name eq 'primary_key_columns') {
    return $entry ? [ @{ $entry->{primary_key_columns} } ] : [];
  }
  if ($name eq 'unique_exists') {
    return 0;
  }
  if ($name eq 'foreign_key_count') {
    return 0;
  }
  if ($name eq 'index_count') {
    my @want = @{ $args->{columns} || [] };
    my $indexes = $model->{data_skipping_indexes}{$table} || [];
    return scalar grep {
      my $got = $_->{columns} || [];
      @$got == @want and join("\0", @$got) eq join("\0", @want);
    } ref $indexes eq 'HASH' ? values %$indexes : @$indexes;
  }

  DBIO::Exception->throw("unknown conformance fact '$name'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Test::Conformance - Answers the shared conformance case table for the ClickHouse driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::ClickHouse::Test::Conformance;
  DBIO::ClickHouse::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says how to
reach a ClickHouse server, how to install a declaration into it through
L<DBIO::ClickHouse::Deploy>, and how to read a fact back through
L<DBIO::ClickHouse::Introspect>.

The server is the one C<DBIO_TEST_CLICKHOUSE_DSN>, C<DBIO_TEST_CLICKHOUSE_DBUSER>
and C<DBIO_TEST_CLICKHOUSE_DBPASS> name -- the variables of
L<DBIO::ClickHouse::Test>. ClickHouse has no embedded mode, so without the DSN
(or without a MySQL-wire DBD) only the declarations are checked. A run needs an
account that may create and drop databases: L<DBIO::ClickHouse::Deploy/diff>
builds its target in a scratch one.

B<The namespace of a case is a database of its own.> Every case gets a
database C<dbio_cf_E<lt>pidE<gt>_E<lt>nE<gt>>, created by
L</conformance_connect> over a connection of its own; the DSN of the case
names it, so the diff -- which compares the whole of the current database --
sees nothing but the case. L</conformance_namespace> refuses a database that
is not empty, and L</conformance_cleanup> drops a database only when this run
created it. Nothing else on the server is touched.

The class names no storage class beyond what the C<ClickHouse> component pins.

=head1 METHODS

=head2 conformance_live_available

True when C<DBIO_TEST_CLICKHOUSE_DSN> is set and the DBD it names loads
(L<DBD::mysql> or L<DBD::MariaDB>).

=head2 conformance_connect

Creates the database of the case, loads the C<ClickHouse> schema component into
the case's schema class and connects to that database. The component pins the
storage; the DSN only says which DBD reaches it.

=head2 conformance_namespace

Returns the name of the case's database as the token for
L</conformance_cleanup>, after checking that it holds no table and no view.
A database that is not empty ends the case.

=head2 conformance_install

Installs the declaration with L<DBIO::ClickHouse::Deploy/install>, the
driver's public entry point. Not C<< $schema->deploy >>: that one carps on a
failed statement and carries on, which would turn a refusal into a warning.

A source named C<database.table> (C<ddl-qualified-source-name>) is made in a
database that is not the case's, so the class takes care of it: a table of that
name that is on the server already is not the run's to use or drop, and ends the
case; one that is not is marked, and L</conformance_cleanup> drops it. The
database itself is never created or dropped.

=head2 conformance_cleanup

Drops the database of the token when L</conformance_connect> of this run
created it, the tables L</conformance_install> marked in other databases, and
disconnects. Nothing else is dropped: without a mark no other database is
touched. The drops go through a connection of their own.

=head2 conformance_diff_is_empty

True when L<DBIO::ClickHouse::Deploy/diff> of the installed database against
the same declaration has no changes.

=head2 conformance_upgrade

Connects the target schema class to the database of the installed one and
runs L<DBIO::ClickHouse::Deploy/upgrade> -- the public entry point -- through
it. The target class takes over the namespace (and the duty to drop it) of the
installed one, since the runner hands only the returned schema to
L</conformance_cleanup>. The upgrade runs with C<< allow_destructive => 1 >>:
the cases of the table are about what the diff does (a dropped column, a
changed type); the guard that holds a destructive diff back has its own cases
(C<diff-deploy-destructive-guard>, run through L</conformance_deploy>). A
refusal of the diff is thrown from here as it came; the database then stays
with the installed schema, whose cleanup drops it.

=head2 conformance_deploy

The deploy object over the target schema, for the deploy cases of the Diff list
(table version 4): the target class is connected to the database of the
installed one exactly as L</conformance_upgrade> connects it, and takes over its
namespace and the duty to drop it. Returns
C<< DBIO::ClickHouse::Deploy->new(schema => $to) >>; the runner calls C<apply>
and C<upgrade> on it.

=head2 conformance_answered_through

The table versions the answers were written against, per area:
C<< { DDL => 2, Diff => 4, Bind => 1 } >>. The DDL and Diff lists are answered by
this class; the Bind cases (t/62) run unrefused except as L</Bind> says.
Version 4 of the Diff list adds the deploy cases (C<diff-deploy-*>):
they run through L</conformance_deploy>, which hands the runner the
L<DBIO::ClickHouse::Deploy> object, so C<apply> and C<upgrade> are the base
class's.

=head2 conformance_refusals

ClickHouse has no foreign key, no enforced C<UNIQUE> and no identity column;
an C<is_auto_increment> column that is not a UUID is refused too
(C<ddl-auto-increment>, C<diff-auto-increment-kept>,
C<bind-lob-row-operations>; the engine has no C<AUTO_INCREMENT>,
L<https://clickhouse.com/docs/sql-reference/statements/create/table>), and so
is a C<bit> with a size (C<ddl-type-size-bit>: no C<BIT> type,
L<https://clickhouse.com/docs/sql-reference/data-types>).
C<ddl-type-size-char>, C<diff-column-type-change> and C<bind-numeric-exact>
are declared deviations with the reason in the declaration. A case that asks
for one is a C<server> refusal, thrown by
L<DBIO::ClickHouse::DDL/What install_ddl refuses> before the first statement
and naming table and column --
never a table built without the constraint. The reason is the engine's own
documentation:
L<https://clickhouse.com/docs/sql-reference/statements/create/table> (the
C<CREATE TABLE> grammar has no foreign key and no unique clause) and
L<https://clickhouse.com/docs/guides/developer/deduplication> (ClickHouse does
not check for an existing primary key before inserting; C<ReplacingMergeTree>
deduplicates at merge time, not on insert).

C<ddl-qualified-source-name> writes the table C<t> into the database C<other>
(C<< table('other.t') >>). The driver creates no database, and the
case does not either, so the answer depends on the server: where a database
C<other> exists, the table is made in it and the case runs through, read back
by L</conformance_fact>; where it does not,
L<DBIO::ClickHouse::Deploy/install> refuses, naming table and database, before
its first statement, and the case is declared a C<server> refusal. Which of the
two holds is asked of the server (C<_database_exists>), read only.

The Diff cases that declare a foreign key or a unique constraint (in C<from>
or C<to>) are refused the same way. The refusal of a table names every constraint it cannot
build in one text, each with the table's columns; that is what lets
C<diff-constraint-changed> (subject C<child.code>, a unique constraint only the
target declares, the installed C<from> having the foreign key alone) meet the
refusal convention. The column is named as context of the table, not because the
driver knew the target. C<diff-column-added-not-null-populated> and
C<diff-not-null-over-nulls> are C<server> refusals of
L<DBIO::ClickHouse::Deploy/_check_before_apply>, thrown before the first statement: the
server would fill the rows with the type's zero value, or switch the column's
metadata and then fail it in the background mutation
(L<https://clickhouse.com/docs/sql-reference/statements/alter/column>).

=head2 conformance_fact

Reads one fact through L<DBIO::ClickHouse::Introspect>, of the database of the
case; the vocabulary is the one of L<DBIO::Test::Conformance/Facts>.
C<table_in_namespace> asks the namespace named, a database. The facts of
constraints are answered as the engine has them: no foreign key, no unique
constraint and no index but the skipping indexes (L<DBIO::ClickHouse::Introspect>).

=head2 Bind

The Bind list needs no refusal of this class beyond one case: a value goes
through the column by every operation of the ResultSet API and either comes
back as written or the case fails. C<bind-numeric-exact> is a declared
deviation (C<Decimal> is exact but reads back without trailing zeros).
C<bind-lob-row-operations> needs an auto-increment key, which the DDL refuses
(see L</conformance_refusals>); it is declared a C<server> refusal, but the
runner still fails it because the refusal names the column C<id> and the
subject core gives the case is C<body>.

Two cases pass because the driver closes what the server does silently, not
because they are declared: C<bind-empty-string> (a string that is not a number
at a numeric column is refused by L<DBIO::ClickHouse::Storage/_prep_for_execute>
before it is sent -- the server would store C<NULL>), and C<bind-binary> and
C<bind-lob-empty-and-large> (a C<0x1A> byte is bound through a marker by
L<DBIO::ClickHouse::SQLMaker/_render_bind> -- the DBD escapes it as C<\Z>, which
ClickHouse keeps as two characters).

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::ClickHouse::Deploy> - install and diff, as the cases reach them

=item * L<DBIO::ClickHouse::Introspect> - what the facts are read through

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
