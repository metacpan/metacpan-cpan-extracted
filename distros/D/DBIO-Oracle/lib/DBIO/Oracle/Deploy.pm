package DBIO::Oracle::Deploy;
# ABSTRACT: Deploy, diff and upgrade a schema on Oracle, against a temporary user

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base::TempDatabase';

use DBI;
use DBIO::Util ();
use DBIO::Oracle::DDL       ();
use DBIO::Oracle::Introspect ();
use DBIO::Oracle::Diff      ();
use DBIO::Oracle::Identifier ();
use DBIO::Oracle::Type      ();
use DBIO::Exception         ();



# --- class-name hooks for DBIO::Deploy::Base -------------------------------

sub _ddl_class        { 'DBIO::Oracle::DDL'        }
sub _introspect_class { 'DBIO::Oracle::Introspect' }
sub _diff_class       { 'DBIO::Oracle::Diff'       }


sub _install_ddl {
  my ($self) = @_;
  $self->_require_schema_users;
  return $self->SUPER::_install_ddl;
}

sub _require_schema_users {
  my ($self) = @_;
  my $objects = $self->_ddl_class->declared_objects($self->schema)->{schema} || {};
  my @wanted = sort keys %$objects;
  return unless @wanted;

  my $dbh = $self->_dbh;
  my %have = map { $_ => 1 } @{ $dbh->selectcol_arrayref(
    'SELECT username FROM all_users WHERE username IN ('
    . join(', ', ('?') x @wanted) . ')', undef, @wanted) };
  my ($missing) = grep { !$have{$_} } @wanted;
  return unless defined $missing;

  my $hint = '';
  if ($missing ne uc $missing) {
    my ($upper) = $dbh->selectrow_array(
      'SELECT username FROM all_users WHERE username = ?', undef, uc $missing);
    $hint = " (a user '" . uc($missing) . "' exists: Oracle folds an unquoted name to upper case, "
      . 'and the schema of a table name is taken exactly as spelled)' if defined $upper;
  }
  my @tables = map { "$missing.$_" } @{ $objects->{$missing}{table} || $objects->{$missing}{view} || [] };
  $self->schema->throw_exception(sprintf
    "%s: the schema (user) '%s' does not exist on the server%s; the driver creates "
    . "no user -- refused, nothing is installed",
    join(', ', @tables), $missing, $hint);
}


sub _check_before_apply {
  my ($self, $diff) = @_;
  $self->_refuse_unfillable($diff, $self->_dbh);
  return $self->SUPER::_check_before_apply($diff);
}

# What Oracle accepts when it changes the datatype of a column that holds
# values: the pairs (old base type => new base types) measured on Oracle
# Database 23ai Free (23.26.3) with one value in the column, karr k63. Any
# other change between the base types in %KNOWN_BASE is ORA-01439 (ORA-22858 and
# ORA-22859 for the LOB types); a type outside that list is left to the server.
my %KNOWN_BASE = map { $_ => 1 } (
  'NUMBER', 'FLOAT', 'VARCHAR2', 'CHAR', 'NVARCHAR2', 'NCHAR', 'CLOB', 'DATE',
  'TIMESTAMP', 'TIMESTAMP WITH TIME ZONE', 'BINARY_FLOAT', 'BINARY_DOUBLE',
  'RAW', 'BLOB',
);
my %CONVERTS = (
  'CHAR'      => { map { $_ => 1 } 'VARCHAR2', 'NCHAR', 'NVARCHAR2' },
  'VARCHAR2'  => { map { $_ => 1 } 'CHAR', 'NCHAR', 'NVARCHAR2' },
  'NCHAR'     => { 'NVARCHAR2' => 1 },
  'NVARCHAR2' => { 'NCHAR' => 1 },
  'DATE'      => { 'TIMESTAMP' => 1 },
  'TIMESTAMP' => { 'DATE' => 1 },
  'NUMBER'    => { 'FLOAT' => 1 },
);

# the type as Oracle names it, without size, scale or precision
sub _base_type {
  my ($info) = @_;
  my $type = uc DBIO::Oracle::Type::map_dbio_type_to_oracle($info->{data_type}, size => $info->{size});
  $type =~ s/\([^)]*\)//g;
  $type =~ s/\s+/ /g;
  $type =~ s/^\s+|\s+\z//g;
  return $type eq 'INTEGER' ? 'NUMBER' : $type;
}


sub _refuse_unfillable {
  my ($self, $diff, $dbh) = @_;

  my $has_rows = sub {
    my ($table, $where) = @_;
    return scalar $dbh->selectrow_array(sprintf 'SELECT 1 FROM %s WHERE %sROWNUM = 1',
      DBIO::Oracle::Identifier::quote_table($table), $where ? "$where AND " : '');
  };

  for my $op (@{ $diff->operations }) {
    next unless $op->isa('DBIO::Oracle::Diff::Column');
    my ($table, $column) = ($op->table_name, $op->column_name);
    my $quoted = DBIO::Oracle::Identifier::quote($column);

    if ($op->action eq 'add') {
      my $new = $op->new_info || {};
      next unless $new->{not_null};
      next if defined $new->{default_value}
        && (ref $new->{default_value} || $new->{default_value} ne 'null');
      next unless $has_rows->($table);
      DBIO::Exception->throw(sprintf
        'Oracle refuses to add the column %s.%s: it is NOT NULL without a '
        . 'default, and table %s holds rows that would have no value for it '
        . '(ORA-01758)', $table, $column, $table);
    }
    elsif ($op->action eq 'alter') {
      my ($old, $new) = ($op->old_info || {}, $op->new_info || {});

      if ($new->{not_null} && !$old->{not_null}
          && $has_rows->($table, "$quoted IS NULL")) {
        DBIO::Exception->throw(sprintf
          'Oracle refuses to make the column %s.%s NOT NULL: table %s holds '
          . 'rows where it is NULL (ORA-02296)', $table, $column, $table);
      }

      my ($from, $to) = (_base_type($old), _base_type($new));
      next if $from eq $to;
      next unless $KNOWN_BASE{$from} && $KNOWN_BASE{$to};
      next if $CONVERTS{$from} && $CONVERTS{$from}{$to};
      next unless $has_rows->($table, "$quoted IS NOT NULL");
      DBIO::Exception->throw(sprintf
        'Oracle refuses to change the type of the column %s.%s from %s to %s: '
        . 'it holds values, and Oracle changes the datatype of a column only '
        . 'while it is empty (ORA-01439)',
        $table, $column, $from, $to);
    }
  }
  return;
}


sub _new_introspect {
  my ($self, $dbh, @args) = @_;
  return $self->_introspect_class->new(dbh => $dbh, @args);
}


sub _introspect_current {
  my ($self) = @_;
  my @foreign = $self->_ddl_class->foreign_schemas($self->schema);
  return $self->_new_introspect($self->_dbh, (@foreign ? (schemas => \@foreign) : ()))->model;
}


sub _build_target_model {
  my $self = shift;
  my @declared = $self->_ddl_class->foreign_schemas($self->schema);
  return $self->SUPER::_build_target_model(@_) unless @declared;

  my $dbh = $self->_dbh;
  # as in the base class: the connect info is read before anything exists
  $self->_temp_connect_info('probe');

  # A schema named like the connected user is its own schema: the live
  # introspection reads those tables bare, so the main temp user stands for it.
  my ($me) = eval { $self->_admin_dbh->selectrow_array('SELECT USER FROM DUAL') };
  if (my $e = $@) {
    $self->_close_admin_dbh;
    die $e;
  }
  my @foreign = grep { !defined $me || $_ ne $me } @declared;

  my (@made, %temp, $model);
  my $built = eval {
    my $main = $self->_create_temp_db($dbh);
    push @made, $main;
    my $k = 0;
    for my $real (@foreign) {
      my $name = $temp{$real} = $main . '_' . ++$k;
      $self->_create_temp_db($dbh, $name);
      push @made, $name;
    }
    $model = $self->_deploy_and_introspect_temp_schemas($main, \%temp,
      scalar(@foreign) < @declared ? $me : undef);
    1;
  };
  my $err = $built ? undef : $@;

  # every user made is dropped, the last first; a drop that fails is warned
  # about and does not change the outcome
  for my $user (reverse @made) {
    eval { $self->_drop_temp_db($dbh, $user); 1 } or do {
      my $drop_err = "$@";
      my $info = eval { [ $self->_temp_connect_info($user) ] };
      ($drop_err = DBIO::Util::mask_connect_secrets($drop_err, $info)) =~ s/\s+\z//;
      warn ref($self) . ": temporary database '$user' could not be dropped and "
         . "is still on the server -- drop it by hand: $drop_err\n";
    };
  }

  die $err if $err;
  return $model;
}

# Connects as one temp user (the passwords masked in what is raised).
sub _connect_temp {
  my ($self, $user) = @_;
  my ($dsn, $name, $pass) = $self->_temp_connect_info($user);
  my $temp_dbh = eval {
    DBI->connect($dsn, $name, $pass, { RaiseError => 1, PrintError => 0, AutoCommit => 1 })
  } or die DBIO::Util::mask_connect_secrets(
    $@ || "Cannot connect to temp database: $DBI::errstr", [ $dsn, $name, $pass ],
  );
  return $temp_dbh;
}

sub _unquote_ident { my $i = $_[0]; $i =~ s/""/"/g; return $i }

# The user whose schema a statement of the install DDL writes to: the schema
# of its first object when that is qualified ("U"."t"), else the main user.
sub _stmt_schema {
  my ($stmt) = @_;
  return $stmt =~ /\A[^"]*"((?:[^"]|"")*)"\s*\./ ? _unquote_ident($1) : undef;
}


sub _deploy_and_introspect_temp_schemas {
  my ($self, $main, $temp, $own) = @_;
  my %real = reverse %$temp;
  my @users = ($main, map { $temp->{$_} } sort keys %$temp);
  my (%conn, $model);

  my $ok = eval {
    $conn{$_} = $self->_connect_temp($_) for @users;

    my $ddl = do {
      local %DBIO::Oracle::Identifier::SCHEMA_MAP = (%$temp, defined $own ? ($own => $main) : ());
      $self->_ddl_class->install_ddl($self->schema);
    };
    my $storage = eval { $self->schema->storage } || undef;
    for my $stmt (DBIO::Deploy::Base::_split_ddl($storage, $ddl)) {
      my $owner = _stmt_schema($stmt);
      $owner = $main unless defined $owner && $conn{$owner};

      # a foreign key into the table of another user: the sandbox's owner of
      # the parent lets the child's user reference it (the install DDL writes
      # no GRANT, see _build_target_model)
      if ($stmt =~ /\A\s*ALTER\s+TABLE\b/i
          && $stmt =~ /\bREFERENCES\s+((?:("(?:[^"]|"")*")\s*\.\s*)?"(?:[^"]|"")*")/i) {
        my ($parent, $pschema) = ($1, $2);
        my $powner = defined $pschema ? _unquote_ident(substr $pschema, 1, -1) : $main;
        $conn{$powner}->do("GRANT REFERENCES ON $parent TO $owner")
          if $conn{$powner} && $powner ne $owner;
      }
      $self->_execute_ddl($conn{$owner}, $stmt);
    }

    $model = $self->_new_introspect($conn{$main})->model;
    my $rename = sub {
      my ($name, $own_real) = @_;
      if ($name =~ /\A([^.]+)\.(.+)\z/s) {
        return $2 if $1 eq $main;
        return "$real{$1}.$2" if exists $real{$1};
        return $name;
      }
      return defined $own_real ? "$own_real.$name" : $name;
    };
    for my $fks (values %{ $model->{foreign_keys} || {} }) {
      $_->{to_table} = $rename->($_->{to_table}) for @$fks;
    }
    # a view names the views it rests on: the temp users are the real schemas again
    for my $v (values %{ $model->{views} || {} }) {
      $_ = $rename->($_) for @{ $v->{depends_on} || [] };
    }
    for my $real_schema (sort keys %$temp) {
      my $user = $temp->{$real_schema};
      my $m = $self->_new_introspect($conn{$user})->model;
      for my $key (keys %{ $m->{tables} || {} }) {
        my $full = "$real_schema.$key";
        for my $section (qw(tables columns indexes foreign_keys primary_keys unique_constraints views)) {
          $model->{$section}{$full} = $m->{$section}{$key} if exists $m->{$section}{$key};
        }
        $model->{tables}{$full}{schema} = $real_schema;
        for my $fk (@{ $model->{foreign_keys}{$full} || [] }) {
          $fk->{from_table} = $full;
          $fk->{to_table}   = $rename->($fk->{to_table}, $real_schema);
        }
        if (my $v = $model->{views}{$full}) {
          $_ = $rename->($_, $real_schema) for @{ $v->{depends_on} || [] };
        }
        for my $col (@{ $model->{columns}{$full} || [] }) {
          $col->{sequence} =~ s/\A\Q$user\E\./$real_schema./
            if defined $col->{sequence};
        }
      }
    }
    1;
  };
  my $err = $ok ? undef : $@;

  # a disconnect that fails is raised only when nothing else was
  for my $user (reverse @users) {
    my $c = $conn{$user} or next;
    eval { $c->disconnect; 1 } or $err ||= $@;
  }

  die $err if $err;
  return $model;
}

# --- the desired state in a temporary user ---------------------------------

# One counter for the process: DBIO_TMP_<pid>_<n>.
my $TEMP_COUNTER = 0;

# What the install DDL needs of the temp user. DDL.pm writes tables (their
# primary, unique and foreign keys and indexes come with CREATE TABLE),
# sequences, BEFORE INSERT triggers and views -- nothing else.
my @TEMP_GRANTS = (
  'CREATE SESSION', 'CREATE TABLE', 'CREATE SEQUENCE', 'CREATE TRIGGER',
  'CREATE VIEW',
);

# What the connected user needs to make and remove the temp user.
my @USER_PRIVS = ('CREATE USER', 'DROP USER');


sub temp_db_prefix { $_[0]->{temp_db_prefix} // 'DBIO_TMP_' }

# The DSN is the live one, unchanged: the temp user is another login, not
# another database.
sub _temp_dsn { $_[1] }


sub _temp_connect_info {
  my ($self, $temp_db) = @_;
  my ($dsn, $user, $pass) = $self->SUPER::_temp_connect_info($temp_db);
  return ($dsn, $user, $pass) if $temp_db eq 'probe';
  return ($dsn, $temp_db, $self->{_temp_password}{$temp_db});
}

# Errors from a connection are masked for both passwords in play: the one of
# the connected user, and the one of the temp user, which a failed CREATE USER
# is quoted with by the driver.
sub _masked {
  my ($self, $error, $temp_db) = @_;
  my @info = ([ $self->_temp_connect_info('probe') ]);
  push @info, [ $self->_temp_connect_info($temp_db) ]
    if defined $temp_db && $self->{_temp_password}{$temp_db};
  $error = "$error";
  $error = DBIO::Util::mask_connect_secrets($error, $_) for @info;
  $error =~ s/\s+\z//;
  return $error;
}

# The connection that makes and removes the temp user: its own, with the
# credentials of the storage and AutoCommit, so that the implicit commits of
# CREATE USER, GRANT and DROP USER are none of the caller's transaction.
sub _admin_dbh {
  my ($self) = @_;
  return $self->{_admin_dbh} if $self->{_admin_dbh};

  my ($dsn, $user, $pass) = $self->_temp_connect_info('probe');
  return $self->{_admin_dbh} = eval {
    DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    })
  } || die DBIO::Util::mask_connect_secrets(
    $@ || "Cannot connect for the temporary user: $DBI::errstr",
    [ $dsn, $user, $pass ],
  );
}

sub _close_admin_dbh {
  my ($self) = @_;
  my $admin = delete $self->{_admin_dbh} or return;
  eval { $admin->disconnect; 1 };
  return;
}

# The tablespace comes from the dictionary and goes into the SQL as a quoted
# identifier.
sub _quote_ident { my $i = $_[0]; $i =~ s/"/""/g; return qq{"$i"} }

sub _random_password {
  my @chars = ('a' .. 'z', 'A' .. 'Z', '0' .. '9');
  return join '', 'Tp', map { $chars[ rand @chars ] } 1 .. 24;
}


sub _create_temp_db {
  my ($self, undef, $name) = @_;

  $name //= $self->temp_db_prefix . $$ . '_' . ++$TEMP_COUNTER;
  my $pass = $self->{_temp_password}{$name} = _random_password();
  my $created;

  my $admin = eval { $self->_admin_dbh } or do {
    my $err = $@;
    delete $self->{_temp_password}{$name};
    die $err;
  };

  my $ok = eval {
    my %have = map { $_ => 1 } @{ $admin->selectcol_arrayref(
      'SELECT privilege FROM session_privs WHERE privilege IN ('
      . join(', ', map { "'$_'" } @USER_PRIVS) . ')'
    ) };
    my @missing = grep { !$have{$_} } @USER_PRIVS;
    $self->schema->throw_exception(
      ref($self) . ': diff and upgrade build the desired state in a temporary '
      . 'user, and the connected user lacks the system privilege '
      . join(' and ', @missing) . ' for it (nothing was created)'
    ) if @missing;

    my ($tablespace) = $admin->selectrow_array(
      'SELECT default_tablespace FROM user_users'
    );
    my $quota = defined $tablespace && length $tablespace
      ? ' DEFAULT TABLESPACE ' . _quote_ident($tablespace)
        . ' QUOTA UNLIMITED ON ' . _quote_ident($tablespace)
      : '';

    $created = 1;
    $admin->do(qq{CREATE USER $name IDENTIFIED BY "$pass"$quota});
    $admin->do("GRANT $_ TO $name") for @TEMP_GRANTS;
    1;
  };
  my $err = $@;

  unless ($ok) {
    # nothing may stay behind of a half-made user
    eval { $admin->do("DROP USER $name CASCADE"); 1 } if $created;
    $err = ref $err ? $err : $self->_masked($err, $name) . "\n";
    delete $self->{_temp_password}{$name};
    $self->_close_admin_dbh;
    die $err;
  }

  return $name;
}


sub _drop_temp_db {
  my ($self, undef, $name) = @_;

  my $admin = eval { $self->_admin_dbh };
  my $err = $@;
  my $dropped = $admin && eval { $admin->do("DROP USER $name CASCADE"); 1 };
  $err = $@ if $admin && !$dropped;

  $self->_close_admin_dbh;

  if ($dropped) {
    delete $self->{_temp_password}{$name};
    return;
  }
  die $self->_masked($err, $name) . "\n";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Deploy - Deploy, diff and upgrade a schema on Oracle, against a temporary user

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Oracle::Deploy> deploys a schema to Oracle.
L<install|DBIO::Deploy::Base/install> runs the install DDL
(L<DBIO::Oracle::DDL>) against the connected database -- it is what
C<< $schema->deploy >> calls -- and L<apply|DBIO::Deploy::Base/apply> runs the
SQL of a diff it is handed. Both are inherited from L<DBIO::Deploy::Base>
unchanged; this class supplies the three class-name hooks they work through and
the check of L</_check_before_apply>. A diff that drops something or may alter
stored values (a lossy column change, L<DBIO::Oracle::Diff::Column/lossy>) runs
only with C<< allow_destructive => 1 >>.

L<diff|DBIO::Deploy::Base/diff> and L<upgrade|DBIO::Deploy::Base/upgrade> are
core's as well. The desired state they compare the live schema with is built
in a B<temporary Oracle user>, the counterpart of the temporary database of
L<DBIO::Deploy::Base::TempDatabase> (see L</The desired state: a temporary
user>). A table only the desired schema has is created whole by the diff
(L<DBIO::Oracle::Diff>): its columns and keys, sequence and trigger, then its
indexes, then its foreign keys; an upgrade over an empty schema makes what
C<install> makes, and the next one finds nothing to do.

    my $deploy = DBIO::Oracle::Deploy->new(
        schema => MyApp::DB->connect($dsn),
    );
    $deploy->install;                       # fresh, into an empty schema

    my $diff = $deploy->diff;               # live schema against the desired one
    $deploy->upgrade;                       # diff, then apply

=head2 The desired state: a temporary user

An Oracle schema is a user account, and Oracle commits implicitly around
every DDL statement. A test deploy on the live connection therefore cannot be
taken back (the first C<CREATE TABLE> commits the transaction and erases the
savepoint, ORA-01086; ADR 0002, overtaken by ADR 0010). So
L<DBIO::Deploy::Base::TempDatabase/_build_target_model> deploys the schema into a user made for the purpose:

=over 4

=item 1.

The privileges are checked first: the connected user needs C<CREATE USER> and
C<DROP USER> (read from C<session_privs>). If one is missing a DBIO exception
names it, and nothing has been created.

=item 2.

C<CREATE USER DBIO_TMP_E<lt>pidE<gt>_E<lt>nE<gt>> (C<n> counts per process,
the password is random) with an unlimited quota on the default tablespace of
the connected user, and the grants the install DDL needs: C<CREATE SESSION>,
C<TABLE>, C<SEQUENCE>, C<TRIGGER>, C<VIEW>. The connected user has to be able
to grant them (C<WITH ADMIN OPTION>).

=item 3.

The install DDL runs on a connection of the temp user (same DSN), the result is
introspected there -- the introspection reads the user it is connected as --
and the connection is closed.

=item 4.

C<DROP USER ... CASCADE>, whatever became of the deploy or the introspection.
A drop that fails does not change the outcome, but is warned about with the
name of the user left on the server; passwords in the message are shown as
C<***>.

=back

C<CREATE USER>, C<GRANT> and C<DROP USER> commit implicitly, so they never run
on the connection of the schema: they run on a connection of their own (same
credentials, C<AutoCommit>), opened for the call and closed after it. The
live connection is read from (the introspection of the live schema) and
nothing else is done to it; a transaction the caller has open stays open and
uncommitted.

=head2 Transactional DDL -- the bracket this engine cannot carry

L<DBIO::Oracle::Storage> declares C<< _use_transactional_ddl(0) >>, so
L<DBIO::Deploy::Base/_execute_ddl> runs the statements of an
L<DBIO::Deploy::Base/install> or an L<DBIO::Deploy::Base/apply> one at a time
and core emits its one-time C<non-transactional DDL>
notice naming this class. The notice is a true statement about this engine, not
a defect to be silenced.

Oracle commits around every DDL statement -- before it "even if the statement
results in an error", and again after it when it completes without one (SQL
Language Reference 19c, C<COMMIT>). A C<< $storage->txn_do >> around the loop
would therefore be worse than no bracket at all: the first C<CREATE TABLE>
commits the transaction C<txn_do> just opened, and the C<ROLLBACK> at the end
of a failed block has nothing left to reach. The full reasoning sits at the
declaration in L<DBIO::Oracle::Storage>.

=head3 What a rollback still recovers after a half-run deploy

Nothing. When C<apply> has run I<n> of I<m> statements and the I<n+1>st throws,
all I<n> are committed and permanent: each was committed by the statement
following it, and the last one by the failing statement's own leading
C<COMMIT>, which runs whether or not that statement then succeeds. Nothing on
the connection or in the session takes any of it back -- C<txn_rollback>, an
enclosing L<DBIO::Storage::TxnScopeGuard>, an explicit
C<ROLLBACK TO SAVEPOINT>: each of them acts on a transaction the first DDL
statement had already ended.

=head3 The recycle bin is a recovery tool, not a rollback

Oracle's Flashback Drop is sometimes offered as the missing undo. It is worth
being exact about what it is: a manual, after-the-fact recovery path an
operator drives per object and by name, working from "dropped data in the
recycle bin rather than undo data" (SQL Language Reference 19c,
C<FLASHBACK TABLE>). It is not transaction semantics, and nothing in this class
invokes it on a caller's behalf.

For this deploy path it also mostly does not apply. Three statements in
L<DBIO::Oracle::Diff> remove anything: C<DROP TABLE ... CASCADE CONSTRAINTS>
(L<DBIO::Oracle::Diff::Table>), C<< ALTER TABLE ... DROP COLUMN >>
(L<DBIO::Oracle::Diff::Column>) and C<DROP INDEX>
(L<DBIO::Oracle::Diff::Index>). Only the first leaves anything behind: "Only
the C<DROP> C<TABLE> SQL statement places objects in the recycle bin"
(Administrator's Guide 19c, I<What Is the Recycle Bin?>). The dropped column
and the dropped index are gone outright, and C<FLASHBACK TABLE ... TO SCN> is
no way back to them either, because "Oracle Database cannot restore a table to
an earlier state across any DDL operations that change the structure of the
table" -- with "modifying or dropping a column" named in the restrictions.

Even for the table drop the retrieval is partial and conditional. The recycle
bin has to be enabled (the C<recyclebin> initialization parameter; on by
default), the table "must have resided in a locally managed tablespace other
than the C<SYSTEM> tablespace", and nothing may have purged it since. What
comes back carries recycle-bin names for its indexes, triggers and constraints
-- and "C<FLASHBACK> C<TABLE> C<TO> C<BEFORE> C<DROP> does not recover
referential constraints", the retrieved constraints excluding "referential
integrity constraints that reference other tables". Those are exactly the ones
this driver's C<CASCADE CONSTRAINTS> had just dropped. (Quotations: SQL
Language Reference 19c, C<FLASHBACK TABLE>.)

=head3 Recovery is a new diff

The recovery path after a half-applied upgrade is to run it again: it is
C<diff> followed by C<apply>, and C<diff> introspects the live database on
every call, so the second run's diff is computed against the state the first
run actually left behind and contains only the remainder. That is the
forward-progress story core's notice points at.

=head2 What of this is verified

The temp-user orchestration is pinned offline in
F<t/58-deploy-temp-user.t> with doubles for the handles: the order (create
user, grants, install, introspect, drop), the drop on a failed deploy, the
warning for a drop that failed, the refusal before anything is created when
C<CREATE USER> or C<DROP USER> is missing, the C<DBIO_TMP_> name, and that the
connection of the schema is not written to. Section 8 of that file pins a
schema with tables in other schemas: a temp user for each, the
qualifiers rewritten, the models merged back under the real names, every user
dropped on every path. F<t/84-ddl-cross-schema-live.t> runs it against a
server with a second user.

The behaviour is B<measured against a server>, Oracle Database 23ai Free
(23.26.3) over DBD::Oracle 1.95. F<t/54-deploy-live.t>: what C<install> leaves
in a schema, that it commits a transaction the caller has open; that C<diff>
and C<upgrade> leave a transaction of the caller open and uncommitted, leave
no C<DBIO_TMP_> user behind, also when the deploy fails; that a diff of a
schema against the state it already has is empty and that a missing column is
added by C<upgrade>; and, kept as the measured reason for ADR 0010, the
statements of the old savepoint strategy replayed by hand (ORA-01086).
F<t/55-diff-index-live.t>: what L<DBIO::Oracle::Diff> makes of a new table: A
to B applied gives B, and C<upgrade> of a DBIO schema (two tables, a foreign
key, an index, a unique constraint, a sequence) over an empty schema and over
a schema that has one of the tables gives what C<install> gives.

The core seam is verified against core's source: which branch of
L<DBIO::Deploy::Base/_execute_ddl> the declared capability selects.
F<t/52-deploy-transactional-ddl.t> pins that half offline.

What is said about the recycle bin further up is B<not> measured. It is
documented behaviour with its source named (SQL Language Reference 19c
C<COMMIT> and C<FLASHBACK TABLE>; 2 Day Developer's Guide 19c, I<About Data
Definition Language (DDL) Statements>; Administrator's Guide 19c, I<Using
Flashback Drop and Managing the Recycle Bin>), and no test of this driver has
run a Flashback statement.

=head1 METHODS

=head2 _install_ddl

The install DDL that core's L<DBIO::Deploy::Base/install> (what
C<< $schema->deploy >> runs) executes, after a check: a table in
another schema (C<< table('OWNX.item') >>, see L<DBIO::Oracle::DDL/TABLES IN
ANOTHER SCHEMA>) is created in that schema, which is a user, and the driver
creates no user. Every schema the install names is looked up in C<all_users>
(by the exact name, like the quoted statements); when one is missing a DBIO
exception names the user and a table of the declaration that wants it, says it
refuses, and nothing has been sent to the server. When Oracle holds a user of
the upper-case spelling (a user made unquoted), the message says so.

=head2 _check_before_apply

    $self->_check_before_apply($diff);

Seam of L<DBIO::Deploy::Base/apply>, run once the diff is released
(L<DBIO::Deploy::Base/allow_destructive>) and before the first statement: looks
at the rows of the live tables (L</_refuse_unfillable>), then goes on as the
base does. L<apply|DBIO::Deploy::Base/apply> and
L<upgrade|DBIO::Deploy::Base/upgrade> themselves are core's (ADR 0080).

=head2 _refuse_unfillable

    $self->_refuse_unfillable($diff, $dbh);

Refuses -- a L<DBIO::Exception> naming table and column, nothing sent -- what
Oracle would refuse for the rows a table holds half way through the diff,
since Oracle commits every DDL statement and the ones before it cannot be
taken back:

=over 4

=item * a C<NOT NULL> column without a default that the diff adds to a table
that holds rows (ORA-01758);

=item * a column that becomes C<NOT NULL> in a table that has a C<NULL> in it
(ORA-02296);

=item * a column that holds values and changes to a datatype Oracle does not
convert (ORA-01439; ORA-22858 and ORA-22859 for the LOB types). Oracle
converts, with values in the column, C<CHAR> and C<VARCHAR2> into each other and
into C<NCHAR> and C<NVARCHAR2>, those two into each other, C<DATE> and
C<TIMESTAMP> into each other and C<NUMBER> into C<FLOAT>; every other change
between the types the driver writes is refused. A type that is not among them
is left to the server.

=back

An empty table, a table with no C<NULL> in the column and a column that holds
only C<NULL> pass.

=head2 _new_introspect

    my $introspect = $self->_new_introspect($dbh, %args);

Overrides L<DBIO::Deploy::Base/_new_introspect> to hand further arguments (the
C<schemas> of L<DBIO::Oracle::Introspect/schemas>) to the introspection.

=head2 _introspect_current

The model of the live schema. When the declaration has tables in other schemas
(a source C<OWNX.item>) those schemas are read as well, so that their
tables are in the model as C<OWNX.item>, the keys of the model of the desired
state (see L</_build_target_model>). The connected user reads them through the
C<all_*> views, as far as it may see them.

=head2 _build_target_model

Builds the desired state in a temporary user (see L</The desired state: a
temporary user>). A schema with tables in other schemas (a source
C<OWNX.item>) gets one more temporary user for each of those
schemas, C<DBIO_TMP_E<lt>pidE<gt>_E<lt>nE<gt>_E<lt>kE<gt>> (C<k> counts them
in the order of their names), because a temporary user cannot hold a table of
another user and the driver makes no user of the real name. See L</Tables in
other schemas>.

=head2 _deploy_and_introspect_temp_schemas

    my $model = $self->_deploy_and_introspect_temp_schemas($main, { OWNX => $temp_user });

The install DDL of a schema with foreign schemas, built with the temp users as
qualifiers, run statement by statement as the temp user it writes to, and the
merged model of all of them (see L</_build_target_model>). All connections are
closed before it returns or raises.

=head2 temp_db_prefix

C<DBIO_TMP_>: the prefix of the temporary users, and what a leftover one is
found by (C<SELECT username FROM all_users WHERE username LIKE 'DBIO\_TMP\_%'
ESCAPE '\'>). Overrides L<DBIO::Deploy::Base::TempDatabase/temp_db_prefix>.

=head2 _temp_connect_info

    my ($dsn, $user, $pass) = $self->_temp_connect_info($temp_user);

The DSN of the storage, with the name and the password of the temporary user.
Overrides L<DBIO::Deploy::Base::TempDatabase/_temp_connect_info>; with the
argument C<probe> it answers the connect info of the storage itself, which is
how the admin connection gets its credentials.

=head2 _create_temp_db

    my $temp_user = $self->_create_temp_db($dbh);
    $self->_create_temp_db($dbh, $name);        # a user of that name

Makes the temporary user (L</The desired state: a temporary user>) on a
connection of its own and returns its name. C<$dbh>, the connection of the
schema, is not used. Throws a DBIO exception naming C<CREATE USER> or
C<DROP USER> before anything is created when the connected user lacks the
privilege; when a step after C<CREATE USER> fails the user is dropped again
before the error is raised.

=head2 _drop_temp_db

    $self->_drop_temp_db($dbh, $temp_user);

C<DROP USER ... CASCADE> on the connection of its own, which is closed
afterwards in any case. A failure is raised (with the passwords masked) for
L<DBIO::Deploy::Base::TempDatabase/_build_target_model> to warn about.

=head2 Tables in other schemas

=over 4

=item *

The install DDL is written with each foreign schema replaced by its temporary
user (L<DBIO::Oracle::Identifier/%SCHEMA_MAP>), and every statement runs on
the connection of the user whose schema it writes to: the temporary users need
none of the C<ANY> privileges the real install needs.

=item *

A temporary user sees only its own tables, so each is introspected on its own
connection. The models are merged under the keys the live introspection uses
(C<table> for the connected schema, C<OWNX.table> for a foreign one) and the
temporary names are written back as the real schemas, in table keys, the
C<schema> of a table, foreign keys and sequences: a diff of the schema against
itself is empty.

=item *

Every temporary user is dropped, also when the deploy fails; a drop that fails
is warned about with the name of that user, the others are still dropped.

=item *

B<Foreign keys between schemas.> The install DDL and C<apply> write no
C<GRANT>: a foreign key from a table of one user to a table of another needs
C<REFERENCES> on the parent for the owner of the child, and without it the
server's error (ORA-01031) reaches the caller. That grant is the schema
owner's to give. Only among its own temporary users does this class issue
C<GRANT REFERENCES ON parent TO child_user>, by the owner of the parent and
before the foreign key, so that the desired state can be built at all; the
diff then compares the declaration with the live schema and does not know
whether the live owner has granted the right.

=item *

A schema named like the connected user is its own schema, not a foreign one:
it gets no temporary user of its own, its tables are made in the main
temporary user, and the model holds them bare, as the live introspection of the
connected user reads its own tables.

=back

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::Oracle> - schema component

=item * L<DBIO::Oracle::DDL> - generates DDL

=item * L<DBIO::Oracle::Introspect> - reads live database state

=item * L<DBIO::Oracle::Diff> - compares two introspected models

=item * L<DBIO::Deploy::Base> - inherited orchestration

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
