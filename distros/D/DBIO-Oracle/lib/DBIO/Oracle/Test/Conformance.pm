package DBIO::Oracle::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the Oracle driver

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::Conformance';

use DBI ();
use DBIO::Exception ();
use DBIO::Oracle::Introspect ();
use DBIO::Oracle::DDL ();
use DBIO::Oracle::Deploy ();
use DBIO::Oracle::Identifier ();


# schema class => the objects the user owned before the case
my %BEFORE;

# schema class => { schema => the objects that schema owned before the case },
# for the schemas a declaration with a 'schema.table' source writes to
my %FOREIGN_BEFORE;

# Objects the cleanup drops, in the order it drops them. INDEX and TRIGGER go
# with their table; they are listed so that one left behind is found.
my @DROP_ORDER = qw(VIEW TABLE SEQUENCE TRIGGER INDEX);


sub conformance_live_available {
  return 0 unless length($ENV{DBIO_TEST_ORA_DSN} // '');
  return eval { require DBD::Oracle; 1 } ? 1 : 0;
}


sub conformance_connect {
  my ($class, $schema_class) = @_;
  $schema_class->load_components('Oracle');
  return $schema_class->connect(
    @ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)},
    { AutoCommit => 1, RaiseError => 1, PrintError => 0 },
  );
}

# The objects the connected user owns, as { "TYPE\0NAME" => [ type, name ] }.
# The recycle bin is left out: those are Oracle's, not a case's.
sub _owned_objects {
  my ($class, $dbh) = @_;
  my %owned;
  my $rows = $dbh->selectall_arrayref(
    q{SELECT object_type, object_name FROM user_objects
      WHERE object_name NOT LIKE 'BIN$%'});
  $owned{"$_->[0]\0$_->[1]"} = [ @$_ ] for @$rows;
  return \%owned;
}


sub conformance_namespace {
  my ($class, $schema, $case) = @_;
  my $dbh   = $schema->storage->dbh;
  my $owned = $class->_owned_objects($dbh);
  $BEFORE{ ref $schema } = $owned;
  # a table in another schema (karr k58, a source 'schema.table') is made
  # there: what that schema owns now is recorded as well
  my $own = eval { DBIO::Oracle::DDL->declared_objects($schema) } || {};
  $FOREIGN_BEFORE{ ref $schema } = {
    map { $_ => $class->_owned_in($dbh, $_) } keys %{ $own->{schema} || {} }
  };
  return $owned;
}

# The objects of the schema (user) $owner as { "TYPE\0NAME" => [ type, name ] },
# as far as the connected user sees them.
sub _owned_in {
  my ($class, $dbh, $owner) = @_;
  my %owned;
  my $rows = $dbh->selectall_arrayref(
    q{SELECT object_type, object_name FROM all_objects
      WHERE owner = ? AND object_name NOT LIKE 'BIN$%'}, undef, $owner);
  $owned{"$_->[0]\0$_->[1]"} = [ @$_ ] for @$rows;
  return \%owned;
}


sub conformance_install {
  my ($class, $schema, $case) = @_;
  $schema->deploy;
  return;
}


sub conformance_cleanup {
  my ($class, $schema, $case, $namespace) = @_;
  my $before = delete $BEFORE{ ref $schema };
  $before //= $namespace;

  my $storage = $schema->storage;
  my $error;
  if ($before) {
    # What the case declared. A declaration the driver refuses was never sent
    # to the server, so there is nothing of it to drop.
    my $own = eval { DBIO::Oracle::DDL->declared_objects($schema) } || {};
    my $dbh = eval { $storage->dbh };
    my $mine;
    unless ($dbh and eval { $dbh->ping }) {
      $dbh = $mine = DBI->connect(
        @ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)},
        { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    }
    $error = $class->_drop_own_objects($dbh, $before, $own);
    my $foreign = $class->_drop_foreign_objects(
      $dbh, delete $FOREIGN_BEFORE{ ref $schema }, $own);
    $error = join '; ', grep { defined } $error, $foreign;
    $error = undef unless length $error;
    $mine->disconnect if $mine;
  }
  $storage->disconnect;
  DBIO::Exception->throw("conformance: cleanup left objects behind: $error")
    if defined $error;
  return;
}

# The new objects of the user that the declaration names, as { key => [ type,
# name ] } with the key of _owned_objects, and the new objects it does not.
sub _new_objects {
  my ($class, $dbh, $before, $own) = @_;
  my $now = $class->_owned_objects($dbh);
  my %name = map { my $type = $_; ($type => { map { $_ => 1 } @{ $own->{$type} || [] } }) }
             qw(table view sequence trigger);
  my %index_table = map { @$_ } @{ $own->{index} || [] };
  my %table_of = map { @$_ } @{ $dbh->selectall_arrayref(
    q{SELECT index_name, table_name FROM user_indexes}) };

  my (@mine, @foreign);
  for my $key (sort keys %$now) {
    next if $before->{$key};
    my ($type, $obj) = @{ $now->{$key} };
    my $is_mine = $type eq 'INDEX'
      ? (exists $index_table{$obj} && ($table_of{$obj} // '') eq $index_table{$obj})
      : ($name{ lc $type } && $name{ lc $type }{$obj});
    push @{ $is_mine ? \@mine : \@foreign }, $now->{$key};
  }
  return (\@mine, \@foreign);
}

sub _drop_own_objects {
  my ($class, $dbh, $before, $own) = @_;
  my @failed;
  for my $round (1 .. 2) {
    my ($mine) = $class->_new_objects($dbh, $before, $own);
    last unless @$mine;
    for my $type (@DROP_ORDER) {
      for my $object (grep { $_->[0] eq $type } @$mine) {
        (my $q = $object->[1]) =~ s/"/""/g;
        my $sql = $type eq 'TABLE'
          ? qq{DROP TABLE "$q" CASCADE CONSTRAINTS PURGE}
          : qq{DROP $type "$q"};
        # a trigger or an index may have gone with its table
        my $done = eval { $dbh->do($sql); 1 };
        push @failed, "$sql ($@)" if !$done and $round == 2;
      }
    }
  }
  my ($left, $foreign) = $class->_new_objects($dbh, $before, $own);
  $class->_report_foreign($foreign) if @$foreign;
  return undef unless @$left;
  return join(', ', map { "$_->[0] $_->[1]" } @$left)
    . (@failed ? ' -- ' . join('; ', @failed) : '');
}

# The objects a declaration made in other schemas (karr k58): in each schema
# the declaration writes to, those that are new since the case began and whose
# names the declaration gives -- the same rule as for the user's own schema.
# Returns the objects left, as text, or undef.
sub _drop_foreign_objects {
  my ($class, $dbh, $before, $own) = @_;
  my @left;
  for my $owner (sort keys %{ $own->{schema} || {} }) {
    my $decl = $own->{schema}{$owner};
    my $was  = ($before || {})->{$owner} || {};
    my %name = map { my $t = $_; ($t => { map { $_ => 1 } @{ $decl->{$t} || [] } }) }
               qw(table view sequence trigger);
    $name{index} = { map { $_->[0] => 1 } @{ $decl->{index} || [] } };

    my $mine = sub {
      my $now = $class->_owned_in($dbh, $owner);
      return grep { $name{ lc $_->[0] } && $name{ lc $_->[0] }{ $_->[1] } }
             map { $now->{$_} } grep { !$was->{$_} } sort keys %$now;
    };
    for my $round (1 .. 2) {
      my @objects = $mine->() or last;
      for my $type (@DROP_ORDER) {
        for my $object (grep { $_->[0] eq $type } @objects) {
          my $sql = sprintf '%s %s%s', ($type eq 'TABLE' ? 'DROP TABLE' : "DROP $type"),
            DBIO::Oracle::Identifier::quote_in("$owner.x", $object->[1]),
            ($type eq 'TABLE' ? ' CASCADE CONSTRAINTS PURGE' : '');
          eval { $dbh->do($sql); 1 };
        }
      }
    }
    push @left, map { "$_->[0] $owner.$_->[1]" } $mine->();
  }
  return @left ? join(', ', @left) : undef;
}

# Objects that are new but not the case's: told, never dropped.
sub _report_foreign {
  my ($class, $foreign) = @_;
  require Test::More;
  Test::More::diag('conformance: left alone, new in the user\'s schema but not '
    . 'declared by the case: ' . join(', ', map { "$_->[0] $_->[1]" } @$foreign));
  return;
}


sub conformance_diff_is_empty {
  my ($class, $schema, $case) = @_;

  my $diff = DBIO::Oracle::Deploy->new(schema => $schema)->diff;
  return 1 unless $diff && $diff->has_changes;

  my $declared = DBIO::Oracle::DDL->declared_objects($schema);
  my %own = map { $_ => 1 } @{ $declared->{table} // [] }, @{ $declared->{view} // [] };
  # a table in another schema is 'schema.table' in the diff (karr k58)
  for my $s (keys %{ $declared->{schema} // {} }) {
    $own{"$s.$_"} = 1 for @{ $declared->{schema}{$s}{table} // [] }, @{ $declared->{schema}{$s}{view} // [] };
  }
  my @mine = grep { $own{ $_->table_name } } @{ $diff->operations };
  return 1 unless @mine;

  require Test::More;
  Test::More::diag('conformance: the diff against the installed declaration is '
    . "not empty:\n" . join("\n", map { $_->summary } @mine));
  return 0;
}


# The tables and views the declarations of the schemas name, as { name => 1 }:
# 'table', and 'schema.table' for a source in another schema.
sub _case_tables {
  my ($class, @schemas) = @_;
  my %mine;
  for my $s (@schemas) {
    my $declared = DBIO::Oracle::DDL->declared_objects($s);
    $mine{$_} = 1 for @{ $declared->{table} // [] }, @{ $declared->{view} // [] };
    for my $owner (keys %{ $declared->{schema} // {} }) {
      $mine{"$owner.$_"} = 1
        for @{ $declared->{schema}{$owner}{table} // [] },
            @{ $declared->{schema}{$owner}{view} // [] };
    }
  }
  return \%mine;
}

sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->conformance_connect($to_class);

  my $done = eval {
    my $deploy = DBIO::Oracle::Test::Conformance::Deploy->new(
      schema => $to, case_tables => $class->_case_tables($schema, $to));
    my $diff = $deploy->diff;
    $deploy->apply($diff, allow_destructive => 1);
    1;
  };
  my $error = $@;
  unless ($done) {
    # the target declaration may have created some of its objects
    my $mark = $BEFORE{ ref $schema };
    eval { $class->conformance_cleanup($to, $case, $mark) };
    die $error;
  }
  return $to;
}


sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->conformance_connect($to_class);
  return DBIO::Oracle::Test::Conformance::Deploy->new(
    schema => $to, case_tables => $class->_case_tables($schema, $to));
}

{
  package DBIO::Oracle::Test::Conformance::Deploy;

  use base 'DBIO::Oracle::Deploy';

  sub diff {
    my ($self) = @_;
    my $diff = $self->SUPER::diff;
    my $mine = $self->{case_tables} or return $diff;
    my @ops   = grep {  $mine->{ $_->table_name } } @{ $diff->operations };
    my @other = grep { !$mine->{ $_->table_name } } @{ $diff->operations };
    if (@other) {
      require Test::More;
      Test::More::diag('conformance: left alone, not an object of the case: '
        . join('; ', map { $_->summary } @other));
    }
    $diff->{operations} = \@ops;
    return $diff;
  }
}


sub conformance_answered_through {
  my ($class) = @_;
  return {
    DDL  => 2,
    Diff => 4,
    Bind => 1,
  };
}


sub conformance_refusals {
  my ($class) = @_;
  my $refusals = $class->_conformance_refusals;
  # The case writes to the schema 'other' and the driver creates no user
  # (karr k58): where the server has no user of that exact name the install is
  # refused, as the driver's own refusal that waits for such a user.
  $refusals->{'ddl-qualified-source-name'} = {
    kind   => 'pending',
    card   => 'k58',
    reason => qr/does not exist/,
  } if $class->conformance_live_available && !$class->_user_exists('other');
  return $refusals;
}

# Whether the server has a user of exactly that name; asked once per name and
# process.
my %USER_EXISTS;
sub _user_exists {
  my ($class, $name) = @_;
  return $USER_EXISTS{$name} //= do {
    my $dbh = DBI->connect(@ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)},
      { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    my ($found) = $dbh->selectrow_array(
      'SELECT COUNT(*) FROM all_users WHERE username = ?', undef, $name);
    $dbh->disconnect;
    $found ? 1 : 0;
  };
}

sub _conformance_refusals {{
  'ddl-enum-value-apostrophe' => {
    kind   => 'server',
    reason => qr/no enum type/,
  },
  'ddl-ident-special-chars' => {
    kind   => 'server',
    reason => qr/double quote/,
  },
  'ddl-type-size-bit' => {
    kind   => 'server',
    reason => qr/no BIT type/,
  },
  'ddl-index-on-unique-columns' => {
    kind   => 'server',
    reason => qr/one index/,
  },
  'ddl-default-digit-string' => {
    kind   => 'deviation',
    fact   => qr/Code\.code: expected '007', read back '007  '/,
    reason => 'CHAR(n) is blank-padded to n by Oracle itself: the default is the string 007 '
            . '(not the number 7), and a row without the column reads it back padded to '
            . "'007  '. The driver does not trim it",
  },
  # --- the Diff list (karr k63)
  'diff-column-added-not-null-populated' => {
    kind   => 'server',
    reason => qr/NOT NULL without a default, and table base holds rows/,
  },
  'diff-not-null-over-nulls' => {
    kind   => 'server',
    reason => qr/table opt holds rows where it is NULL/,
  },
  'diff-column-type-change' => {
    kind   => 'server',
    reason => qr/changes the datatype of a column only while it is empty/,
  },
  # --- the Bind list (karr k63)
  'bind-empty-string' => {
    kind   => 'deviation',
    fact   => qr/Val: the server accepted a row it must reject/,
    reason => 'Oracle does not know the empty string: for a VARCHAR2, a NUMBER or any other '
            . 'type but a LOB, \'\' is NULL, so the nullable integer column of the case takes it '
            . '(SQL Language Reference, "Nulls": "Oracle Database currently treats a character '
            . 'value with a length of zero as null"). The text column holds \'\' as an empty LOB '
            . 'and finds it again',
  },
  'bind-numeric-exact' => {
    kind   => 'deviation',
    fact   => qr/Num\.v create: expected '1234567890123456\.7890', read back '1234567890123456\.789'.*expected '0\.0001', read back '\.0001'/s,
    reason => 'the value is exact and the digits are all there, but Oracle has no display scale: a '
            . 'NUMBER is read as the shortest text of its value, without trailing zeros after the '
            . 'point and without the zero before a leading point (1234567890123456.7890 is '
            . '1234567890123456.789, 0.0001 is .0001); NUMBER(20,4) does not pad to four places',
  },
}}


sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  my $dbh   = $schema->storage->dbh;
  my $table = $args->{table};

  if ($name eq 'table_in_namespace') {
    my $other = DBIO::Oracle::Introspect->new(
      dbh => $dbh, schema => $args->{namespace});
    return exists $other->model->{tables}{ $args->{unqualified} } ? 1 : 0;
  }

  my $model = DBIO::Oracle::Introspect->new(dbh => $dbh)->model;
  my $entry = $model->{tables}{$table};
  my @cols  = @{ $args->{columns} || [] };
  my $same  = sub {
    my ($got) = @_;
    return 0 unless @$got == @cols;
    return (join("\0", map { $_ // '' } @$got) eq join("\0", @cols)) ? 1 : 0;
  };

  if ($name eq 'object_kind') {
    return undef unless $entry;
    return $entry->{kind};
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
    return [ @{ $model->{primary_keys}{$table} || [] } ];
  }
  if ($name eq 'unique_exists') {
    return (grep { $same->($_->[1]) } @{ $model->{unique_constraints}{$table} || [] })
      ? 1 : 0;
  }
  if ($name eq 'foreign_key_count') {
    return scalar @{ $model->{foreign_keys}{$table} || [] };
  }
  if ($name eq 'index_count') {
    return (scalar grep { $same->($_->{columns}) }
              values %{ $model->{indexes}{$table} || {} })
         + (scalar grep { $same->($_->[1]) }
              @{ $model->{unique_constraints}{$table} || [] });
  }

  DBIO::Exception->throw("unknown conformance fact '$name'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Test::Conformance - Answers the shared conformance case table for the Oracle driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::Oracle::Test::Conformance;
  DBIO::Oracle::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says how to
reach an Oracle server, how to install a declaration into it through
L<DBIO::Oracle::Deploy>, and how to read a fact back through
L<DBIO::Oracle::Introspect>.

The server is the one C<DBIO_TEST_ORA_DSN>, C<DBIO_TEST_ORA_USER> and
C<DBIO_TEST_ORA_PASS> name; without the DSN (or without L<DBD::Oracle>) only
the declarations are checked.

B<The namespace of a case is the user's own schema, cleaned up after the
case.> Oracle has no cheaper namespace: a schema is a user, and a new user is
not this class's to create. L</conformance_namespace> therefore records which
objects the connected user owns before the case runs, and
L</conformance_cleanup> drops exactly the tables, views, sequences, triggers
and indexes that are there afterwards, were not before, B<and> whose names the
declaration of the case gives (the table and view names, the shortened
sequence and trigger names of its auto-increment columns, its index names --
taken from L<DBIO::Oracle::DDL/declared_objects>, the one place those names are
made), with C<DROP TABLE ... CASCADE CONSTRAINTS PURGE>, so nothing lands in
the recycle bin. Any other new object (a table another session of the user
made while the case ran, an index on a table that was there before) is left
alone and reported with C<diag>. An object that was there before is never
touched, nor is an object of another user, and nothing server-wide is changed.
Oracle commits around every DDL statement, so a case cannot be rolled back;
the cleanup is the only way back, and a cleanup that cannot drop an object of
its case fails the case. Two runs against the same user at once would still
meet on the names of the cases: one run per database at a time (house rule 1
of live testing).

The diff postcondition is asked (L</conformance_diff_is_empty>): after
a case is installed, a diff of the live schema against the same declaration is
empty, as far as the objects of the case go. It builds the declaration in a
temporary user (L<DBIO::Oracle::Deploy>), so the connected user needs C<CREATE
USER> and C<DROP USER>.

The class names no storage class and never decides the driver: the schema
class of a case loads the C<Oracle> component, as an application does.

=head1 METHODS

=head2 conformance_live_available

True when C<DBIO_TEST_ORA_DSN> is set and L<DBD::Oracle> loads.

=head2 conformance_connect

Loads the C<Oracle> schema component into the case's schema class and connects
with the C<DBIO_TEST_ORA_*> variables, and nothing else: the ISO date and
timestamp formats are the driver's own default for every connection
(L<DBIO::Oracle::Storage/Date and timestamp formats>), so the case
C<ddl-default-expression> reads a date as the string it expects without this
class setting anything.

The long-value length and the client character set are the driver's own
defaults as well (L<DBIO::Oracle::Storage/LOB length and character set>): the
Bind cases that read a long text back and send non-ASCII text need nothing set
here, nor an C<NLS_LANG>.

=head2 conformance_namespace

Records the objects the connected user owns, as the token for
L</conformance_cleanup>.

=head2 conformance_install

Installs the declaration with C<< $schema->deploy >>, the public entry point,
which hands over to L<DBIO::Oracle::Deploy/install>.

C<ddl-view-declared> runs like every other case: the runner builds its view
definition from the identifiers it quotes (C<conformance_quote_ident>), by
default the quote character of the SQL maker, C<"> here. The definition
therefore names the table as the driver creates it, quoted and as the result
class spells it. A definition a user writes by hand is still sent as written
(F<t/75-conformance-ddl-extra-live.t>).

=head2 conformance_cleanup

Drops what the case created, and only that: the objects the user owns now,
did not own when L</conformance_namespace> looked, B<and> whose names the
declaration of the case gives (L<DBIO::Oracle::DDL/declared_objects>) -- its
tables, its views, the shortened sequence and trigger names of its
auto-increment columns, and its indexes, an index only when it is on one of
the case's own tables. Views go first, then tables (C<CASCADE CONSTRAINTS
PURGE>), sequences, triggers and indexes that are still there. Every other new
object (one that another session of the same user made while the case ran, an
index on a table that was there before) is left alone and reported with
C<diag>. A case that failed before the namespace was recorded has created
nothing and drops nothing. Where the case's own connection is no longer
usable, the objects are dropped through a connection of their own. An object
of the case that cannot be dropped is an error: it would be the next case's
residue.

=head2 conformance_diff_is_empty

True when the diff of the installed schema against the same declaration
(L<DBIO::Oracle::Deploy/diff>, the desired state built in a temporary user) holds
no operation on one of the case's own tables or views, the names given by
L<DBIO::Oracle::DDL/declared_objects>. The diff is of the whole schema of the
user, so an operation on a table that was there before the case (and would be
dropped) is not the case's and does not count. A diff that holds operations of
the case is told with C<diag>, as its summary.

A table in another schema (a source C<schema.table>) is asked too,
by the name C<schema.table> the diff gives it: L<DBIO::Oracle::Deploy/diff>
builds the desired state with a temporary user for each such schema.

=head2 conformance_upgrade

Connects the target schema class (loading the C<Oracle> component, as an
application does) to the same server as the installed one and runs
L<DBIO::Oracle::Deploy/upgrade>'s two halves -- C<diff>, then C<apply> -- on
it, with C<< allow_destructive => 1 >>: the cases of the table are about what
the diff does (a dropped column, a changed type), the guard that holds a
destructive diff back has its own cases (C<diff-deploy-destructive-guard>, run
through L</conformance_deploy>). The desired state is built in a temporary
user, so the connected user needs C<CREATE USER> and C<DROP USER>.

The diff is of the whole schema of the connected user, and that user is shared
with whatever else lives in it: an operation on a table that neither the
installed nor the target declaration names (L<DBIO::Oracle::DDL/declared_objects>)
would drop somebody else's table. Such an operation is B<left out> of what is
applied and told with C<diag>; nothing but the objects of the case is written.
A refusal of the diff is thrown from here as it came. When the upgrade fails,
what the target declaration already created is removed again before the error
goes on, since the runner's cleanup works from the installed declaration.

=head2 conformance_deploy

The deploy object over the target schema, for the deploy cases of the Diff list
(table version 4): the target class is connected as
L</conformance_upgrade> connects it, and the runner calls C<apply> and
C<upgrade> on the object it gets back. It is a
C<DBIO::Oracle::Test::Conformance::Deploy>, a L<DBIO::Oracle::Deploy> that
differs in one method only: its C<diff> leaves out, and tells with C<diag>, the
operations on a table that neither the installed nor the target declaration
names (the diff is of the whole schema of the connected user, and the user is
shared; an C<apply> with C<allow_destructive> would drop somebody else's
table). C<apply> and C<upgrade> are the ones of L<DBIO::Deploy::Base>, as the
check C<inherited> of the runner requires. When the connect fails the error goes
on as it is; the objects of the installed declaration are the runner's
cleanup.

=head2 conformance_answered_through

The table versions the answers were written against, per area:
C<< { DDL => 2, Diff => 4, Bind => 1 } >>, every list as it stands (version 2
of the Diff list splits U13 into C<diff-constraint-changed> and
C<diff-fk-action-changed>). Each case of the three lists
is answered: correctly, or by a refusal or deviation of
L</conformance_refusals>.

Version 3 of the Diff list replaces C<diff-column-dropped-with-index> by
C<diff-indexed-column-dropped>; it runs.

Version 4 of the Diff list adds the deploy cases (C<diff-deploy-*>):
they run through L</conformance_deploy>, which hands the runner the
L<DBIO::Oracle::Deploy> object, so C<apply> and C<upgrade> are the base class's.

=head2 conformance_refusals

The cases Oracle does not answer by running to the expected result: four
server refusals and one deviation; the other fifteen of the twenty cases
are correct, ddl-qualified-source-name among them where the server has
the user it names (below). A refusal is thrown by L<DBIO::Oracle::DDL> as a
DBIO exception before the server is asked, naming the table and the column of
the declaration.

=over 4

=item ddl-enum-value-apostrophe (server)

Oracle has no ENUM type. An C<enum> column is refused, not written as a type
the server rejects.

=item ddl-ident-special-chars (server)

An Oracle name may hold any character but the double quote and NUL, quoted or
not. The table and the column of the case hold a double quote.

=item ddl-qualified-source-name (answered; pending, without the user)

A table name with a dot is C<schema.table>, and on Oracle a schema is a user:
the case installs C<other.t> as C<"other"."t"> (the schema exactly as spelled)
and reads it back through L<DBIO::Oracle::Introspect> for the user C<other>.
That needs a user of that exact name (a lower-case, quoted one) and the
connected user's C<ANY> privileges (L<DBIO::Oracle::DDL/TABLES IN ANOTHER
SCHEMA>); the driver creates no user. Where the server has no user C<other>
the install is refused (L<DBIO::Oracle::Deploy/install>), which this method
then declares as a refusal because the declaration is waiting for that user
and is not wrong; with the user the declaration disappears and the case runs
(the maintainer's test database makes the user C<other>, see
F<maint/k8s/oracle.yaml>). The diff postcondition is asked of it as of every
case (L</conformance_diff_is_empty>), the desired state being built with a
temporary user for C<other>. Its objects are removed from the schema
afterwards, by the same rule as the user's own.

=item ddl-type-size-bit (server)

Oracle has no BIT type; the C<bit> column of the case is refused.

=item ddl-index-on-unique-columns (server)

A unique constraint and an index over exactly the same columns are one index
for Oracle (ORA-01408). The declaration is refused with a message that names
both and says to declare the key once.

=item ddl-default-digit-string (deviation)

Not a refusal. The column is C<CHAR(5)> with the default C<'007'>. The default
is written as the string (C<DEFAULT '007'>, never the number 7: that is what
the case guards), and Oracle stores a C<CHAR(n)> value blank-padded to n, so
the row reads back as C<'007  '>. That is the type's definition; the driver
does not trim values it reads (a C<ChopBlanks> on the handle is the
application's own choice). Declared as a deviation with the fact the runner
sees, so that any other result, the number 7 included, is still a failure.

=back

B<The Diff list> (table version 4): twenty-three cases, three of them
declared, twenty run through correctly -- the three C<diff-deploy-*> cases
among them, which run through L</conformance_deploy> (the new table with its
keys and indexes, expression defaults, the default changed and removed, a view
added, dropped or with a new definition (L<DBIO::Oracle::Diff::View>), a
column dropped with its index and the unique key it is part of, and the
foreign key dropped, added to a new unique constraint or changed in its action
and the unique constraint changed, among them; the last needed the fixes
described in L<DBIO::Oracle::Diff/DESCRIPTION>). The declared ones, every
refusal thrown by the driver before the server is asked
(L<DBIO::Oracle::Diff>, L<DBIO::Oracle::Deploy/_refuse_unfillable>):

=over 4

=item diff-column-added-not-null-populated (server)

Oracle adds a C<NOT NULL> column without a default only to an empty table
(ORA-01758), and a default for the rows would be a value the driver makes up
(not C<''>: that is NULL). The deploy looks at the table before the first
statement and refuses when it holds rows.

=item diff-not-null-over-nulls (server)

A column cannot become C<NOT NULL> over a C<NULL> (ORA-02296); refused when the
table holds one, before the first statement.

=item diff-column-type-change (server)

Oracle changes the datatype of a column only while it is empty, but for a few
conversions (ORA-01439; ORA-22858 and ORA-22859 for the LOB types): C<CHAR> and
C<VARCHAR2> into each other and into the national types, those into each other,
C<DATE> and C<TIMESTAMP>, C<NUMBER> into C<FLOAT>. The list is measured on 23ai
(L<DBIO::Oracle::Deploy/_refuse_unfillable>); the deploy refuses any other
change between the types it knows when the column holds a value, and leaves a
type it does not know to the server.

=back

B<The Bind list>: ten cases, eight run through correctly and two are
declared deviations. C<bind-question-mark-in-literal> runs: its literal SQL
compares a C<varchar(20)> column, and the driver rewrites no comparison of
literal SQL. The long text of the cases is read in full and the characters
outside the client character set survive, with nothing set by the application
(L<DBIO::Oracle::Storage/LOB length and character set>), and C<bind-non-ascii>
runs: a string without the UTF-8 flag is upgraded for a character column, a
binary column is left alone (L<DBIO::Oracle::Storage/Strings without the UTF-8 flag>).

=over 4

=item bind-empty-string (deviation)

Oracle has no empty string: for every type but a LOB, C<''> is NULL, so the
nullable integer column of the case takes it. The text column holds C<''> as an
empty LOB, reads it back and finds it (L<DBIO::Oracle::Storage::LOBSupport>).

=item bind-numeric-exact (deviation)

The value is exact; what differs is its text. A C<NUMBER(20,4)> is read as the
shortest text of the number: C<1234567890123456.789> for C<...7890>, C<.0001>
for C<0.0001>.

=back

The case C<ddl-view-declared> is not in this list: it is answered correctly.
Oracle reads unquoted names in upper case and the driver creates every table
as the result class spells it, quoted, so a view definition has to quote its
names; the runner builds the definition of the case that way
(L</conformance_install>). A definition a user writes is the user's own SQL
and the driver does not guess at it: an unquoted one fails at the server with
ORA-00942, a quoted one (C<SELECT "id", "name" FROM "base">, in any shape of
C<FROM> and C<JOIN>) is created and works
(F<t/75-conformance-ddl-extra-live.t>).

=head2 conformance_fact

Reads one fact through L<DBIO::Oracle::Introspect>, for the connected user's
schema (or, for C<table_in_namespace>, the user named by the namespace); the
vocabulary is the one of L<DBIO::Test::Conformance/Facts>. An index is counted
as Oracle holds it: the explicit indexes the introspection reports plus one
for each unique constraint, which Oracle backs with an index of its own.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::Oracle::Deploy> - install, as the cases reach it, and the diff against a temporary user

=item * L<DBIO::Oracle::DDL> - where the refusals are thrown

=item * L<DBIO::Oracle::Introspect> - what the facts are read through

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
