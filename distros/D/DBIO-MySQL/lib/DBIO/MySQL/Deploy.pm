package DBIO::MySQL::Deploy;
# ABSTRACT: Deploy and upgrade MySQL/MariaDB schemas via test-deploy-and-compare

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base::TempDatabase';

use DBI                 ();
use DBIO::Exception         ();
use DBIO::Util              ();
use DBIO::MySQL::DDL        ();
use DBIO::MySQL::Identifier ();
use DBIO::MySQL::Introspect ();
use DBIO::MySQL::Diff       ();

# The three class-name hooks DBIO::Deploy::Base needs.

sub _ddl_class       { 'DBIO::MySQL::DDL' }
sub _introspect_class { 'DBIO::MySQL::Introspect' }
sub _diff_class      { 'DBIO::MySQL::Diff' }



sub install {
  my ($self) = @_;
  $self->_refuse_missing_databases($self->_dbh);
  return $self->SUPER::install unless $self->{add_drop_table};

  my $dbh = $self->_dbh;
  $dbh->do('SET FOREIGN_KEY_CHECKS = 0');
  my $ok = eval { $self->_execute_ddl($dbh, $self->_ddl_class->drop_ddl($self->schema)); 1 };
  my $err = $@;
  $dbh->do('SET FOREIGN_KEY_CHECKS = 1');
  die $err unless $ok;

  return $self->SUPER::install;
}


sub _check_before_apply {
  my ($self, $diff) = @_;
  $self->_refuse_missing_databases($self->_dbh);
  $self->_refuse_unfillable($diff, $self->_dbh);
  return $self->SUPER::_check_before_apply($diff);
}


sub _refuse_unfillable {
  my ($self, $diff, $dbh) = @_;

  my $has_rows = sub {
    my ($table, $where, $database) = @_;
    return scalar $dbh->selectrow_array(sprintf 'SELECT 1 FROM %s%s LIMIT 1',
      DBIO::MySQL::Identifier::quote_table_in($database, $table), $where // '');
  };

  for my $op (@{ $diff->operations }) {
    next unless $op->isa('DBIO::MySQL::Diff::Column');
    my ($table, $column, $new) = ($op->table_name, $op->column_name, $op->new_info);

    if ($op->action eq 'add') {
      next unless $new->{not_null} && !defined $new->{default_value}
        && !$new->{is_auto_increment};
      next unless $has_rows->($table, undef, $op->database);
      DBIO::Exception->throw(sprintf
        'DBIO::MySQL refuses to add the column %s.%s: it is NOT NULL without a '
        . 'default, and table %s holds rows that would have no value for it',
        $table, $column, $table);
    }
    elsif ($op->action eq 'modify') {
      next unless $new->{not_null} && !($op->old_info && $op->old_info->{not_null});
      next unless $has_rows->($table,
        ' WHERE ' . DBIO::MySQL::Identifier::quote_ident($column) . ' IS NULL', $op->database);
      DBIO::Exception->throw(sprintf
        'DBIO::MySQL refuses to make the column %s.%s NOT NULL: table %s holds '
        . 'rows where it is NULL', $table, $column, $table);
    }
  }
  return;
}


sub _refuse_missing_databases {
  my ($self, $dbh) = @_;
  for my $pair (DBIO::MySQL::DDL->qualified_tables($self->schema)) {
    my ($table, $database) = @$pair;
    my ($found) = $dbh->selectrow_array(
      'SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = ?',
      undef, $database);
    next if $found;
    DBIO::Exception->throw(sprintf
      'DBIO::MySQL refuses to create the table %s: the database %s does not '
      . 'exist, and the driver does not create databases', $table, $database);
  }
  return;
}

# What the install writes into the live database is the whole schema. The
# temporary database of a diff gets the tables of one database: the current one
# (those named without a database), or one of the other databases, under the
# names they have there (karr k122).
sub _install_ddl {
  my ($self) = @_;
  return $self->_ddl_class->install_ddl($self->schema,
    defined $self->{_only_database} ? { database => $self->{_only_database} }
    : $self->{_local_only}          ? { local_only => 1 }
    :                                 ());
}

sub _deploy_and_introspect_temp {
  my $self = shift;
  local $self->{_local_only} = 1;
  return $self->SUPER::_deploy_and_introspect_temp(@_);
}


sub _other_databases {
  my ($self) = @_;
  my %seen;
  return sort grep { !$seen{$_}++ } map { $_->[1] } DBIO::MySQL::DDL->qualified_tables($self->schema);
}


sub _introspect_current {
  my ($self) = @_;
  my @databases = $self->_other_databases;
  $self->_refuse_missing_databases($self->_dbh) if @databases;

  my $model = $self->SUPER::_introspect_current;
  for my $database (@databases) {
    my %mine = map { $_->[0] =~ /\A\Q$database\E\.(.*)\z/s ? ($1 => 1) : () }
      DBIO::MySQL::DDL->qualified_tables($self->schema);
    my ($dsn, $user, $pass) = $self->_temp_connect_info($database);
    my $dbh = eval { DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0, AutoCommit => 1 }) }
      or die DBIO::Util::mask_connect_secrets(
        $@ || "Cannot connect to the database $database: $DBI::errstr", [ $dsn, $user, $pass ]);
    my $other = eval { $self->_new_introspect($dbh)->model };
    my $err = $@;
    eval { $dbh->disconnect; 1 };
    die $err if $err;
    my %keep = map { $_ => 1 } grep { $mine{$_} && ($other->{tables}{$_}{kind} // '') eq 'table' } keys %{ $other->{tables} };
    $model->{other_databases}{$database} = { map {
      my $section = $_;
      ($section => { map { $_ => $other->{$section}{$_} } grep { $keep{$_} } keys %{ $other->{$section} } })
    } qw(tables columns indexes foreign_keys) };
  }
  return $model;
}


sub _build_target_model {
  my $self = shift;
  my $model = $self->SUPER::_build_target_model(@_);
  for my $database ($self->_other_databases) {
    local $self->{_only_database} = $database;
    $model->{other_databases}{$database} = $self->SUPER::_build_target_model(@_);
  }
  return $model;
}


# --- MySQL-specific temp-database dialect ---

sub _create_temp_db {
  my ($self, $dbh) = @_;
  my $name = $self->temp_db_prefix . $$ . '_' . time();
  $dbh->do('CREATE DATABASE ' . DBIO::MySQL::Identifier::quote_ident($name));
  return $name;
}

sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;
  $dbh->do('DROP DATABASE IF EXISTS ' . DBIO::MySQL::Identifier::quote_ident($name));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Deploy - Deploy and upgrade MySQL/MariaDB schemas via test-deploy-and-compare

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::MySQL::Deploy> orchestrates the deployment and upgrade of
MySQL/MariaDB schemas using a test-deploy-and-compare strategy: it
deploys the desired schema into a freshly created temporary
C<CREATE DATABASE> database, introspects it, and diffs the result
against the live database. See L<DBIO::Deploy::Base> for the shared
install/apply/upgrade flow; see L<DBIO::Deploy::Base::TempDatabase>
for the temp-database orchestration this driver inherits.

    my $deploy = DBIO::MySQL::Deploy->new(
        schema => MyApp::DB->connect($dsn, $user, $pass),
    );

    $deploy->install;     # fresh install
    $deploy->upgrade;     # diff + apply

=head2 Transactional DDL -- the engine has none, on any version

L<DBIO::MySQL::Storage> declares C<< _use_transactional_ddl(0) >>, so
L<DBIO::Deploy::Base/_execute_ddl> runs the statements one at a time with
C<AutoCommit> on and core emits its one-time "non-transactional DDL" notice.
That notice is accurate here: an C<apply> that fails half way leaves the
earlier statements applied. Re-running C<upgrade> is the recovery, and it is
safe, because the diff is recomputed against live state and the second run
picks up only what is left.

The declaration is an engine fact, not a conservative guess. Every statement
this driver emits -- C<CREATE TABLE>, C<CREATE VIEW>, C<ALTER TABLE>,
C<CREATE INDEX>, C<DROP INDEX>, C<DROP TABLE> -- appears on both products'
implicit-commit list (MySQL Reference Manual 15.3.3; MariaDB, I<SQL statements
Causing an Implicit Commit>), which means the transaction is committed before
the statement runs, whether or not the statement then succeeds.

B<Atomic DDL is not transactional DDL>, and the two are easy to confuse. MySQL
8.0 and MariaDB 10.6.1 both made a I<single> DDL statement crash-safe -- no
table left without its dictionary entry, no leftover shadow file. Neither put
DDL under transaction control, and MySQL's manual says so in the same section
that introduces the feature. Raising this capability to C<1> on the strength of
a server version would not make a multi-statement upgrade atomic; it would only
bracket the loop in C<< $storage->txn_do >>, where the C<BEGIN> is committed
away by the next C<CREATE TABLE> and the C<ROLLBACK> takes back nothing --
while silencing the notice that says so. The full citation trail sits at the
declaration in L<DBIO::MySQL::Storage>, and
F<t/58-deploy-transactional-ddl.t> pins it.

Only the live connection is affected either way: the inherited
L<DBIO::Deploy::Base::TempDatabase/_build_target_model> deploys into a
throwaway database over a handle it opened itself, and C<_execute_ddl> never
brackets a handle the storage does not own, whatever the capability says. That
temp database is dropped whole on failure, which is its unit of recovery.

=head1 ATTRIBUTES

=head2 add_drop_table

    DBIO::MySQL::Deploy->new(schema => $schema, add_drop_table => 1)->install;

When true, L<DBIO::Deploy::Base/install> takes away what the install creates before it creates
it: every view (C<DROP VIEW IF EXISTS>, a reader before the view it reads) and
every table (L<DBIO::MySQL::DDL/drop_ddl>), so a second install over a populated
database runs through and leaves it as new. The foreign key checks
of the connection are off for the drops and on again after, whether they ran
through or not. Default false: an install over an existing table fails, as it
always did. L<DBIO::Schema/deploy> does not hand its C<add_drop_table> option
to the Deploy class, so the option is set here, on the object.

=head2 temp_db_prefix

Prefix for temporary databases created during C<diff>. Defaults to
C<_dbio_tmp_>. The full name includes the PID and current timestamp.
Inherited from L<DBIO::Deploy::Base::TempDatabase>.

=over 4

=item * L<DBIO::MySQL>

=item * L<DBIO::MySQL::DDL>

=item * L<DBIO::MySQL::Introspect>

=item * L<DBIO::MySQL::Diff>

=item * L<DBIO::PostgreSQL::Deploy> - the PostgreSQL counterpart

=item * L<DBIO::SQLite::Deploy> - the SQLite counterpart

=back

=head1 METHODS

=head2 _check_before_apply

    $self->_check_before_apply($diff);

The driver's checks of L<DBIO::Deploy::Base/apply>, run for a released diff
before its first statement: L</_refuse_missing_databases> (a table of a
database the server does not have) and L</_refuse_unfillable> (the rows the
live tables hold), both against the live connection. C<apply> and C<upgrade>
are L<DBIO::Deploy::Base>'s as they are: the guard for destructive and lossy
operations (C<allow_destructive>), C<dry_run>, the extension protocol, and the
statements run through its C<_execute_diff>. C<dry_run> checks nothing and asks
the server nothing.

=head2 _refuse_unfillable

    $self->_refuse_unfillable($diff, $dbh);

Looks at the rows of the live tables before the first statement runs, and
refuses -- a L<DBIO::Exception> naming table and column -- what the diff cannot
do without inventing data:

=over 4

=item * a C<NOT NULL> column without a default that the diff adds to a table
        that holds rows. Left to the server it succeeds and gives every row the
        implicit default of the type (C<''>, C<0>, C<0000-00-00>), a value
        nobody declared;

=item * a column that becomes C<NOT NULL> in a table that has a C<NULL> in it.
        A strict server stops the C<MODIFY COLUMN> half way through the diff
        (1138, C<Invalid use of NULL value>); without a strict C<sql_mode> it
        turns every C<NULL> into that implicit default, silently.

=back

An empty table, and a table with no C<NULL> in the column, pass. An
C<AUTO_INCREMENT> column is filled by the server and passes. The ops before the
one refused are not applied: the check runs before the first statement.

=head2 _refuse_missing_databases

    $self->_refuse_missing_databases($dbh);

A source whose table is C<database.table> is made in that database
(L<DBIO::MySQL::DDL/qualified_tables>). The driver creates no
database: one the server does not have ends the install, and the diff and the
upgrade, before their first statement, with a L<DBIO::Exception>
naming the table and the database.

=head2 _other_databases

    my @databases = $self->_other_databases;

The databases, sorted and once each, that the tables named C<database.table>
of the schema live in (L<DBIO::MySQL::DDL/qualified_tables>).

=head2 _introspect_current

The model of the live database, and of each other database the schema has a
table in: a database the server does not have ends the diff here,
before anything is made (L</_refuse_missing_databases>); one it has is
introspected over a connection of its own, the way the temporary database is
reached, and its model keeps the tables the schema names there and nothing else,
so a table of that database that is not the schema's is never dropped. The
models are in C<other_databases> (L<DBIO::MySQL::Diff/Tables of other databases>).

=head2 _build_target_model

The target model, and for each other database the schema has a table in a
model of its tables there: installed into a temporary database of its own
under the names they have in the database, and introspected, as the current
database's tables are. A table of another database that cannot be compared
that way ends the diff with the exception of the failing statement; nothing is
left out.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
