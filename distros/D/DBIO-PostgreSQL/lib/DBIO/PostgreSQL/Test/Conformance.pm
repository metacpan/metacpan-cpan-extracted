package DBIO::PostgreSQL::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the PostgreSQL driver

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::Conformance';

use DBIO::Exception ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Deploy ();
use DBIO::PostgreSQL::Util ();


my $SEQ = 0;
# schema class => the name of its case's schema
my %NAMESPACE;
# schema class => the other schemas its sources are qualified with
my %EXTRA;
# schema class => { schema name => 1 }: the schemas this run created (karr k138)
my %CREATED;


sub conformance_live_available {
  return 0 unless length($ENV{DBIO_TEST_PG_DSN} // '');
  return eval { require DBD::Pg; 1 } ? 1 : 0;
}


sub conformance_connect {
  my ($class, $schema_class) = @_;
  my $name = sprintf 'dbio_cf_%d_%d', $$, ++$SEQ;
  return $class->_connect_in($schema_class, $name);
}

# Binds a schema class to the namespace $name and connects it. Used for the
# class of a case, and by conformance_upgrade for the class of its target.
sub _connect_in {
  my ($class, $schema_class, $name) = @_;
  $NAMESPACE{$schema_class} = $name;
  $EXTRA{$schema_class} = [ $class->_extras_of($schema_class, $name) ];

  $class->_prepare_schema_class($schema_class);
  $schema_class->pg_schemas($name, @{ $EXTRA{$schema_class} });
  $schema_class->pg_search_path($name);

  my $dsn = $ENV{DBIO_TEST_PG_DSN} . ';options='
    . DBIO::PostgreSQL::Util::quote_dsn_value("-csearch_path=$name");
  return $schema_class->connect($dsn,
    $ENV{DBIO_TEST_PG_USER}, $ENV{DBIO_TEST_PG_PASS}, {
      AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0,
    });
}

# A source named 'other.t' is the table t in the schema other: the
# declaration names that schema, as a user of the driver declares it, so the
# install -- the temporary database of a diff too -- creates it.
sub _extras_of {
  my ($class, $schema_class, $name) = @_;
  my %extra;
  for my $moniker ($schema_class->sources) {
    my $table = $schema_class->source($moniker)->name;
    next if ref $table;
    my @parts = split /\./, $table;
    pop @parts;
    $extra{$_} = 1 for grep { length } @parts;
  }
  delete $extra{$name};
  return sort keys %extra;
}

# What a case's classes are given before they connect: the schema component,
# and for every result class the result component with FOREIGN KEY
# constraints from belongs_to (pg_fk_constraints_from_rels, on by default
# since karr k140, set so the case does not depend on it). The case
# declares a relationship and expects the server to hold the key.
sub _prepare_schema_class {
  my ($class, $schema_class) = @_;
  $schema_class->load_components('PostgreSQL');
  for my $moniker ($schema_class->sources) {
    my $result_class = $schema_class->source($moniker)->result_class;
    $result_class->load_components('PostgreSQL::Result');
    $result_class->pg_fk_constraints_from_rels(1);
  }
  return $schema_class;
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

  # a schema of the declaration that is there already is not the case's to
  # create nor to drop: refuse to run rather than damage it
  my @extra = @{ $EXTRA{ ref $schema } || [] };
  for my $extra (@extra) {
    my ($there) = $dbh->selectrow_array(
      'SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = ?', undef, $extra);
    DBIO::Exception->throw("conformance: the schema '$extra' the case declares "
      . 'is in the database already; it is not the run\'s to use or drop')
      if $there;
  }

  my ($main_there) = $dbh->selectrow_array(
    'SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = ?', undef, $name);
  unless ($main_there) {
    $dbh->do('CREATE SCHEMA ' . DBIO::PostgreSQL::Util::quote_ident($name));
    $CREATED{ ref $schema }{$name} = 1;
  }
  # the check above found them absent; the install creates them
  $CREATED{ ref $schema }{$_} = 1 for @extra;
  return { name => $name, extra => \@extra };
}


sub conformance_install {
  my ($class, $schema, $case) = @_;
  $schema->deploy;
  return;
}


sub conformance_cleanup {
  my ($class, $schema, $case, $namespace) = @_;
  my $created = $CREATED{ ref $schema } || {};
  # the schemas the target of an upgrade qualifies with are marked in
  # %CREATED by conformance_upgrade, and are in %EXTRA of its class
  my %seen;
  my @drop = defined $namespace
    ? grep { $created->{$_} and !$seen{$_}++ } $namespace->{name},
        @{ $namespace->{extra} || [] }, @{ $EXTRA{ ref $schema } || [] }
    : ();

  if (@drop) {
    my @sql = map {
      'DROP SCHEMA IF EXISTS ' . DBIO::PostgreSQL::Util::quote_ident($_) . ' CASCADE'
    } @drop;
    my $storage = $schema->storage;
    my $ok = eval {
      my $dbh = $storage->dbh;
      # a failed statement in a transaction leaves it unusable
      $dbh->rollback unless $dbh->{AutoCommit};
      local $dbh->{PrintWarn} = 0;
      $dbh->do($_) for @sql;
      1;
    };
    unless ($ok) {
      my $err = $@;
      my $dbh = DBI->connect(@ENV{qw(DBIO_TEST_PG_DSN DBIO_TEST_PG_USER DBIO_TEST_PG_PASS)},
        { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 })
        or DBIO::Exception->throw("cleanup of schema $namespace->{name} failed: $err");
      $dbh->do($_) for @sql;
      $dbh->disconnect;
    }
  }
  delete $NAMESPACE{ ref $schema };
  delete $EXTRA{ ref $schema };
  delete $CREATED{ ref $schema };
  $schema->storage->disconnect;
  return;
}


sub conformance_diff_is_empty {
  my ($class, $schema, $case) = @_;
  my $diff = DBIO::PostgreSQL::Deploy->new(schema => $schema)->diff;
  return $diff->has_changes ? 0 : 1;
}


sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->_connect_target($schema, $to_class);
  # The cases bring the database to the target declaration, drops and column
  # type changes among them; the guard itself is held by the deploy cases.
  my $ok = eval { DBIO::PostgreSQL::Deploy->new(schema => $to)->upgrade(allow_destructive => 1); 1 };
  unless ($ok) {
    my $err = $@;
    # the installed schema is cleaned up by the runner under its own class
    delete $NAMESPACE{ref $to};
    delete $EXTRA{ref $to};
    delete $CREATED{ref $to};
    eval { $to->storage->disconnect };
    die $err;
  }
  return $to;
}


sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->_connect_target($schema, $to_class);
  return DBIO::PostgreSQL::Deploy->new(schema => $to);
}

# The class of the target declaration, connected to the namespace of the
# installed schema; the namespace, the schemas the target qualifies with and
# the marks of what this run created pass over to it.
sub _connect_target {
  my ($class, $schema, $to_class) = @_;
  my $from_class = ref $schema;
  my $name = $class->_namespace_of($schema);
  my $dbh  = $schema->storage->dbh;

  my @marked = keys %{ $CREATED{$from_class} || {} };
  my %known  = map { $_ => 1 } $name, @{ $EXTRA{$from_class} || [] };
  my @extra = $class->_extras_of($to_class, $name);
  my @new = grep { !$known{$_} } @extra;
  for my $extra (@new) {
    my ($there) = $dbh->selectrow_array(
      'SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = ?', undef, $extra);
    DBIO::Exception->throw("conformance: the schema '$extra' the target "
      . 'declares is in the database already; it is not the run\'s to use or drop')
      if $there;
  }

  my $to = $class->_connect_in($to_class, $name);
  $CREATED{$to_class}{$_} = 1 for @marked, @new;
  return $to;
}


sub conformance_name_kinds { { schema => 1, extension => 1 } }


my $NAME_SEQ = 0;

sub conformance_apply_name {
  my ($class, $kind, $name) = @_;
  return $class->_apply_schema_name($name)    if $kind eq 'schema';
  return $class->_apply_extension_name($name) if $kind eq 'extension';
  DBIO::Exception->throw("conformance: the PostgreSQL driver declares no name kind '$kind'");
}

# A schema class with the PostgreSQL component, nothing declared beyond $o{extensions}.
sub _name_schema_class {
  my ($class, @extensions) = @_;
  my $schema_class = 'DBIO::PostgreSQL::Test::Conformance::Names' . ++$NAME_SEQ;
  {
    no strict 'refs';
    @{"${schema_class}::ISA"} = ('DBIO::Schema');
  }
  $schema_class->load_components('PostgreSQL');
  $schema_class->pg_extensions(@extensions) if @extensions;
  return $schema_class;
}

sub _name_connect {
  my ($class, $schema_class, %attrs) = @_;
  return $schema_class->connect(
    @ENV{qw(DBIO_TEST_PG_DSN DBIO_TEST_PG_USER DBIO_TEST_PG_PASS)},
    { AutoCommit => 1, RaiseError => 1, PrintError => 0, PrintWarn => 0, %attrs });
}

sub _apply_schema_name {
  my ($class, $name) = @_;
  my $schema = $class->_name_connect($class->_name_schema_class, schema => $name);
  my $dbh = $schema->storage->dbh;
  my $made = 0;
  my $shown;
  my $ok = eval {
    die "conformance: the schema '$name' is in the database already; it is not the run's to use or drop\n"
      if $dbh->selectrow_array('SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = ?', undef, $name);
    $made = 1;
    $schema->pg_deploy->install;
    my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh, schema_filter => [ $name ])->model;
    ($shown) = keys %{ $model->{schemas} };
    1;
  };
  my $error = $@;
  eval {
    $dbh->rollback unless $dbh->{AutoCommit};
    $dbh->do('DROP SCHEMA IF EXISTS ' . DBIO::PostgreSQL::Util::quote_ident($name) . ' CASCADE') if $made;
  };
  eval { $schema->storage->disconnect };
  die $error unless $ok;
  return $shown;
}

sub _apply_extension_name {
  my ($class, $name) = @_;
  my $schema = $class->_name_connect($class->_name_schema_class($name));
  my $dbh = $schema->storage->dbh;
  my $made = 0;
  my $shown;
  my $ok = eval {
    die "conformance: the extension '$name' is in the database already; it is not the run's to use or drop\n"
      if $dbh->selectrow_array('SELECT 1 FROM pg_catalog.pg_extension WHERE extname = ?', undef, $name);
    $made = 1;
    $schema->pg_deploy->install;
    my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
    ($shown) = grep { $_ eq $name } keys %{ $model->{extensions} };
    1;
  };
  my $error = $@;
  eval {
    $dbh->rollback unless $dbh->{AutoCommit};
    $dbh->do('DROP EXTENSION IF EXISTS ' . DBIO::PostgreSQL::Util::quote_ident($name)) if $made;
  };
  eval { $schema->storage->disconnect };
  die $error unless $ok;
  return $shown;
}


sub conformance_answered_through { { DDL => 2, Diff => 4, Bind => 1, Names => 1 } }


sub conformance_refusals {{
  'diff-column-added-not-null-populated' => {
    kind   => 'server',
    reason => qr/NOT NULL without a default, and table \S+ holds rows/,
  },
  'diff-not-null-over-nulls' => {
    kind   => 'server',
    reason => qr/holds rows where it is NULL/,
  },
  'ddl-default-digit-string' => {
    kind   => 'deviation',
    fact   => qr/expected '007', read back '007  '/,
    reason => 'char(n) is blank-padded to its length by PostgreSQL, so the '
      . q{default '007' of a char(5) column reads back as '007  '; the driver does not trim},
  },
}}


sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  my $ns    = $class->_namespace_of($schema);
  my $table = $args->{table};
  my $dbh   = $schema->storage->dbh;
  my $intro = DBIO::PostgreSQL::Introspect->new(
    dbh => $dbh, schema_filter => [ $ns ],
  );

  if ($name eq 'table_in_namespace') {
    my $other = DBIO::PostgreSQL::Introspect->new(
      dbh => $dbh, schema_filter => [ $args->{namespace} ],
    );
    return exists $other->model->{tables}{"$args->{namespace}.$args->{unqualified}"} ? 1 : 0;
  }

  my $model = $intro->model;
  my $key   = "$ns.$table";
  my $entry = $model->{tables}{$key};
  my @cols  = @{ $args->{columns} || [] };
  my $same  = sub {
    my ($got) = @_;
    return 0 unless @$got == @cols;
    return (join("\0", map { $_ // '' } @$got) eq join("\0", @cols)) ? 1 : 0;
  };

  if ($name eq 'object_kind') {
    return undef unless $entry;
    return ($entry->{kind} // '') =~ /\A[vm]\z/ ? 'view' : 'table';
  }
  if ($name eq 'table_name') {
    return $entry ? $entry->{table_name} : undef;
  }

  my $columns = $model->{columns}{$key} || [];
  if ($name eq 'column_names') {
    return [ map { $_->{column_name} }
             sort { $a->{ordinal} <=> $b->{ordinal} } @$columns ];
  }
  if ($name eq 'column_size') {
    my ($col) = grep { $_->{column_name} eq $args->{column} } @$columns;
    return undef unless $col;
    return $col->{data_type} =~ /\((\d+)\)/ ? $1 + 0 : undef;
  }
  if ($name eq 'column_auto_increment') {
    my ($col) = grep { $_->{column_name} eq $args->{column} } @$columns;
    return 0 unless $col;
    return ($col->{identity} || ($col->{default_value} // '') =~ /\Anextval\(/) ? 1 : 0;
  }

  my $indexes = $model->{indexes}{$key} || {};
  if ($name eq 'primary_key_columns') {
    for my $i (values %$indexes) {
      return [ @{ $i->{columns} } ] if $i->{is_primary};
    }
    return [];
  }
  if ($name eq 'unique_exists') {
    return (grep {
      ($_->{constraint_type} // '') eq 'u' and $same->($_->{columns})
    } values %$indexes) ? 1 : 0;
  }
  if ($name eq 'foreign_key_count') {
    return scalar @{ $model->{foreign_keys}{$key} || [] };
  }
  if ($name eq 'index_count') {
    return scalar grep {
      !$_->{is_primary} and $same->($_->{columns})
    } values %$indexes;
  }

  DBIO::Exception->throw("unknown conformance fact '$name'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Test::Conformance - Answers the shared conformance case table for the PostgreSQL driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::PostgreSQL::Test::Conformance;
  DBIO::PostgreSQL::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says how to
reach a PostgreSQL server, how to install a declaration into it through
L<DBIO::PostgreSQL::Deploy>, and how to read a fact back through
L<DBIO::PostgreSQL::Introspect>.

The server is the one C<DBIO_TEST_PG_DSN>, C<DBIO_TEST_PG_USER> and
C<DBIO_TEST_PG_PASS> name; without the DSN (or without L<DBD::Pg>) only the
declarations are checked. A run needs a role that may create schemas and
databases in it: L<DBIO::PostgreSQL::Deploy/diff> builds its target in a
temporary database.

B<The namespace of a case is a schema of its own.> Every case gets a schema
C<dbio_cf_E<lt>pidE<gt>_E<lt>nE<gt>> (L</conformance_namespace>), and the
connection of the case is bound to it three ways: C<pg_schemas> restricts the
deploy and the introspector to it, C<pg_search_path> names it (the install
script no longer writes that), and the DSN
carries it as the connection's C<search_path> (C<options=-csearch_path=...>),
which the temporary database of a diff inherits because its DSN is derived
from the live one. So a table the case declares without a C<pg_schema> is
created in that schema both in the live database and in the target of the
diff, and the diff compares nothing else. A schema is dropped with
C<CASCADE> in L</conformance_cleanup> only when L</conformance_namespace> of
this run created it; one that was there before is never dropped.

The class names no storage class and never decides the driver, the DSN does
(see L</conformance_connect>).

=head1 METHODS

=head2 conformance_live_available

True when C<DBIO_TEST_PG_DSN> is set and L<DBD::Pg> loads.

=head2 conformance_connect

Names the schema of the case, loads the C<PostgreSQL> schema component into
the case's schema class and the C<PostgreSQL::Result> component into each of
its result classes, with C<pg_fk_constraints_from_rels> switched on (the
default, set here so the case does not depend on it) -- the case declares a
C<belongs_to> and expects the server to hold the key -- binds the schema class
to its namespace (see L</DESCRIPTION>) and connects. C<storage_type> is not
set by this class beyond what the component does: the DSN is PostgreSQL's.

=head2 conformance_namespace

Creates the case's schema and returns it, with the other schemas the case's
sources are qualified with (they are created by the install, from
C<pg_schemas>), as the token for L</conformance_cleanup>. A qualifying schema
that is in the database already ends the case: it is not this run's to drop.
The case's schema is marked as the run's own only when it was not in the
database before; the qualifying schemas are marked once the check above found
them absent.

=head2 conformance_install

Installs the declaration with C<< $schema->deploy >>, the public entry point,
which hands over to L<DBIO::PostgreSQL::Deploy/install>.

=head2 conformance_cleanup

Drops with C<CASCADE> the schemas of the token that L</conformance_namespace>
of this run created, and disconnects. Nothing else is dropped: without a token
(L</conformance_namespace> threw) or for a schema that was not marked as
created, no schema is touched. Where the case's own connection is no longer
usable, the marked schemas are dropped through a connection of their own.

=head2 conformance_diff_is_empty

True when L<DBIO::PostgreSQL::Deploy/diff> of the installed schema against
the same declaration has no changes.

=head2 conformance_upgrade

Connects the class of the target declaration to the namespace of the case --
the schema the installed one works in -- and runs
L<DBIO::PostgreSQL::Deploy/upgrade>, the public entry point, through it. The
namespace, the schemas the target qualifies with and the marks of what this run
created pass from the class of the installed schema to the target's, so
L</conformance_cleanup> of the schema returned drops them; a schema the target
qualifies with that is in the database already ends the case. The runner closes
the installed schema itself. A refusal of the diff is thrown from here as it
came.

=head2 conformance_deploy

The seam of the deploy cases of the Diff list (C<diff-deploy-inherited>,
C<diff-deploy-dry-run>, C<diff-deploy-destructive-guard>): connects the class of
the target declaration as L</conformance_upgrade> does and returns
C<< DBIO::PostgreSQL::Deploy->new(schema => $to) >> over it, without running
anything. The runner calls C<apply> and C<upgrade> on it.

=head2 conformance_name_kinds

C<< { schema => 1, extension => 1 } >>: the connect key C<schema> (a namespace)
and the name of a database extension in C<pg_extensions>. There is no
C<library>: the one place the driver writes a library, C<LOAD 'library'> for the
activation of an extension (L<DBIO::PostgreSQL::Storage/_apply_connection_schema>),
goes through C<quote_literal>, but a library is a file the server has to find,
there is no catalog that lists a loaded one, and a name the Names list hands over
is never one that exists -- the only answer would be the server's own error, which
the list holds a failure. The quoting is held by a test of its own
(t/146-extension-activation-live.t).

=head2 conformance_apply_name

    $class->conformance_apply_name(schema    => 'a"b');
    $class->conformance_apply_name(extension => 'a b');

The whole of one case of the Names list. C<schema>: connects a fresh schema
class with the connect key C<< schema => $name >>, installs it (which creates
the namespace), reads the namespace back from L<DBIO::PostgreSQL::Introspect>,
drops it again and disconnects. C<extension>: declares C<$name> with
C<pg_extensions>, connects and installs, reads the installed extensions back
and drops the one it made. Returns the name as introspection shows it.

The answers: a name is B<set> and read back as given (C<a"b>, C<a b>, C<a\b>
as a schema), or B<refused> with a L<DBIO::Exception> before a statement that
could meet it -- C<;>, a line break and NUL by the check of core, an extension
that this server does not have (L<DBIO::PostgreSQL::Deploy/_check_extensions_available>,
which reads C<pg_available_extensions> with a bind and names the extension in the
message with the identifier rule). An extension name the Names list hands over is
never one the server can install, so each of these cases ends as a refusal. A
namespace or an extension that is in the database already is not the case's to
use or drop, and ends it with a plain error.

=head2 conformance_answered_through

The table versions the answers were written against, per area:
C<< { DDL => 2, Diff => 4, Bind => 1, Names => 1 } >>, every list as it stands (version 2
of the DDL list splits the type-size case into C<ddl-type-size-char> and
C<ddl-type-size-bit>, version 2 of the Diff list splits U13 into
C<diff-constraint-changed> and C<diff-fk-action-changed>, both answered right). Every case of all three is answered: correctly, or by a
declared refusal or deviation of L</conformance_refusals>.

Version 3 of the Diff list replaces C<diff-column-dropped-with-index> by
C<diff-indexed-column-dropped>; it runs.

Version 4 adds the three deploy cases C<diff-deploy-inherited>,
C<diff-deploy-dry-run> and C<diff-deploy-destructive-guard>,
which run through L</conformance_deploy>: C<apply> and C<upgrade> are the
base's, a drop is refused without C<allow_destructive>, and C<dry_run> executes
nothing.

=head2 conformance_refusals

One deviation is declared, C<ddl-default-digit-string> (maintainer decision
2026-10-12). The column is C<char(5)> with the default
C<'007'>, and PostgreSQL pads a C<char(n)> value with blanks to its length, so
the row reads back as C<'007  '>. That is the type's definition: the driver
does not trim, and the case does not either. The declared C<fact> is the
runner's own failure text of that read-back, so a different wrong value is not
hidden behind the declaration.

C<diff-column-added-not-null-populated> and C<diff-not-null-over-nulls>: the
server cannot give the rows a table holds a value for a new C<NOT NULL> column
without a default, nor accept a C<NOT NULL> over a C<NULL>.
L<DBIO::PostgreSQL::Deploy/_refuse_unfillable> refuses both before the first
statement, naming table and column. The reasons are PostgreSQL's:
C<ALTER TABLE ... ADD COLUMN ... NOT NULL> without a default fails on a table
with rows because the new column would be NULL there, and C<SET NOT NULL> scans
the table and fails on a NULL (L<https://www.postgresql.org/docs/current/sql-altertable.html>,
parameters C<ADD COLUMN> and C<SET/DROP NOT NULL>).

No other refusals are declared.

The driver answers the foreign key cases of the diff list of ADR 0060 (appendix
B) -- U4 (a table with a foreign key added), U11 (a foreign key dropped) and U12
(a foreign key onto a unique key created in the same upgrade) -- in
F<t/160-diff-foreign-key-live.t>, claims 1, 4 and 5. Core's table has no diff
cases in code yet, so a declaration by their names would be refused as an
unknown case.

=head2 conformance_fact

Reads one fact through L<DBIO::PostgreSQL::Introspect>, restricted to the
case's schema (or, for C<table_in_namespace>, to the namespace asked); the
vocabulary is the one of L<DBIO::Test::Conformance/Facts>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::PostgreSQL::Deploy> - install and diff, as the cases reach them

=item * L<DBIO::PostgreSQL::Introspect> - what the facts are read through

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
