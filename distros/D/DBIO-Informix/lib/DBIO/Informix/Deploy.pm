package DBIO::Informix::Deploy;
# ABSTRACT: Deploy and upgrade Informix schemas via test-deploy-and-compare

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base::TempDatabase';

use DBI;
use DBIO::Exception ();
use DBIO::Util ();
use DBIO::Informix::DDL;
use DBIO::Informix::Introspect;
use DBIO::Informix::Diff;
use DBIO::Informix::Util ();


# --- class-name hooks for DBIO::Deploy::Base -------------------------------

sub _ddl_class        { 'DBIO::Informix::DDL' }
sub _introspect_class { 'DBIO::Informix::Introspect' }
sub _diff_class       { 'DBIO::Informix::Diff' }

# --- Informix-specific throwaway-database dialect --------------------------

# dbi:Informix:database[@server] -> (prefix, database, '@server' or '')
sub _split_dsn {
  my ($self, $dsn) = @_;
  $dsn =~ /\A(dbi:Informix:)([^@;=]+)(\@[^;=]+)?\z/i
    or die ref($self) . ": cannot derive a throwaway database from the DSN: "
         . "expected dbi:Informix:database[\@server]\n";
  return ($1, $2, $3 // '');
}


sub _temp_dsn {
  my ($self, $dsn, $temp_db) = @_;
  my ($prefix, undef, $server) = $self->_split_dsn($dsn);
  return "$prefix$temp_db$server";
}


sub _admin_dbh {
  my ($self) = @_;
  my ($dsn, $user, $pass) = @{ $self->schema->storage->_dbi_connect_info };
  die ref($self) . " does not support a coderef DSN for a throwaway database\n"
    if ref $dsn eq 'CODE';
  my ($prefix, undef, $server) = $self->_split_dsn($dsn);
  my $dbh = eval {
    DBI->connect("$prefix$server", $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    })
  } or die DBIO::Util::mask_connect_secrets(
    $@ || "Cannot connect to the server: $DBI::errstr", [ $dsn, $user, $pass ],
  );
  $self->{_admin_dbh} = $dbh;
  return $dbh;
}


sub _create_temp_db {
  my ($self, $dbh) = @_;
  my $name = $self->temp_db_prefix . $$ . '_' . time();
  $dbh->do("CREATE DATABASE $name WITH LOG");
  return $name;
}


sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;
  $dbh->do('CLOSE DATABASE');
  $dbh->do("DROP DATABASE $name");
}


sub _deploy_and_introspect_temp {
  my ($self, @args) = @_;
  local $ENV{DELIMIDENT} = 'y';
  return $self->next::method(@args);
}


sub _check_before_apply {
  my ($self, $diff) = @_;
  $self->_refuse_unfillable($diff, $self->_dbh) if $diff->has_changes;
  return $self->next::method($diff);
}


sub _refuse_unfillable {
  my ($self, $diff, $dbh) = @_;

  my $q = \&DBIO::Informix::Util::_quote_ident;
  my $has_rows = sub {
    my ($table, $where) = @_;
    return scalar $dbh->selectrow_array(sprintf 'SELECT FIRST 1 1 FROM %s%s',
      $q->($table), $where // '');
  };

  my @found;
  for my $op (@{ $diff->operations }) {
    next unless $op->isa('DBIO::Informix::Diff::Column');
    my ($table, $column) = ($op->table_name, $op->column_info->{column_name});
    my $new = $op->column_info // {};

    if ($op->action eq 'add') {
      next unless $new->{not_null} && !$new->{is_auto_increment};
      next if defined $new->{default_value};
      next unless $has_rows->($table);
      push @found, sprintf
        '  %s.%s: added NOT NULL without a default, and the table holds rows',
        $q->($table), $q->($column);
    }
    elsif ($op->action eq 'alter') {
      next unless $new->{not_null} && !($op->from_info // {})->{not_null};
      next unless $has_rows->($table, ' WHERE ' . $q->($column) . ' IS NULL');
      push @found, sprintf
        '  %s.%s: becomes NOT NULL, and the table holds rows where it is NULL',
        $q->($table), $q->($column);
    }
  }

  DBIO::Exception->throw(join "\n",
    sprintf('refusing to apply the diff: the Informix server would refuse %s half way, with its own error',
      @found == 1 ? 'this change' : 'these changes'),
    '',
    @found,
    '',
    'No statement was run. Fill the column (or give it a default) first, or empty the table.',
    '',
  ) if @found;

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Deploy - Deploy and upgrade Informix schemas via test-deploy-and-compare

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Informix::Deploy> orchestrates schema deployment and upgrades for
Informix using the test-deploy-and-compare strategy, parallel to
L<DBIO::MySQL::Deploy> and L<DBIO::PostgreSQL::Deploy>.

The shared orchestration (L<DBIO::Deploy::Base/install>, L<diff|DBIO::Deploy::Base/diff>,
L<apply|DBIO::Deploy::Base/apply>, L<upgrade|DBIO::Deploy::Base/upgrade>) is inherited from
L<DBIO::Deploy::Base>, the throwaway-database orchestration from
L<DBIO::Deploy::Base::TempDatabase>. Informix has no C<:memory:> mode, so the desired schema is deployed into a
throwaway I<database>.

For upgrades the strategy is:

=over 4

=item 1. Introspect the live database via the C<sys*> catalog (source model)

=item 2. Create a throwaway database C<WITH LOG>, on a connection of its own
that is connected to no database

=item 3. Deploy the desired DDL into it, on a second connection to that
database. The DDL names no database: it is the one L<DBIO::Informix::DDL>
writes for the live database, and nothing in it can reach a live object.

=item 4. Introspect the throwaway database the same way (target model)

=item 5. Compute the diff between the two models via L<DBIO::Informix::Diff>

=item 6. Drop the throwaway database, also when the deploy or the
introspection died

=back

    my $deploy = DBIO::Informix::Deploy->new(
        schema => MyApp::DB->connect("dbi:Informix:myapp\@myserver"),
    );
    $deploy->install;                       # fresh
    my $diff = $deploy->diff;               # or step-by-step
    $deploy->apply($diff) if $diff->has_changes;
    $deploy->upgrade;                       # convenience

The live DSN has to be the form C<dbi:Informix:database[@server]>; any other
form is refused when the throwaway database is addressed. The connecting user
needs the right to C<CREATE DATABASE> and to drop what it created. The name is
C<temp_db_prefix> plus process id and time, so the database is not one of the
user's.

A C<CREATE VIEW> body is the user's SQL. It runs in the throwaway database, so
it reads the objects of that database, not of the live one.

=head1 METHODS

=head2 _temp_dsn

The DSN of the throwaway database: the live DSN with the database replaced,
the server kept.

=head2 _admin_dbh

C<CREATE DATABASE> is refused on a connection to a database (error -759), so
the statements run on a connection of their own to the server of the live DSN
with no database, C<AutoCommit> on, closed again when the build is done.

=head2 _create_temp_db

Creates the throwaway database C<WITH LOG> and returns its name. The
connection is in that database afterwards.

=head2 _drop_temp_db

The database that is open cannot be dropped (error -359), so the connection
closes it first.

=head2 _deploy_and_introspect_temp

As in L<DBIO::Deploy::Base::TempDatabase>, with C<DELIMIDENT> set for the
connect to the throwaway database as L<DBIO::Informix::Storage> sets it, so
quoted identifiers in the DDL are identifiers.

=head2 _check_before_apply

    $self->_check_before_apply($diff);

The driver seam of L<DBIO::Deploy::Base/apply> and L<upgrade|DBIO::Deploy::Base/upgrade>
(core ADR 0080): it runs once the diff is released and before the first
statement, for a diff with changes, and puts the diff through
L</_refuse_unfillable> on the connection of the deployment. C<apply> and
C<upgrade> are those of the base class: a diff with a drop or a possibly
lossy change of a column runs with C<< allow_destructive => 1 >>.

=head2 _refuse_unfillable

    $self->_refuse_unfillable($diff, $dbh);

Two changes the server refuses half way through the upgrade (with its own
error, after earlier statements ran) are refused by the driver before the
first statement, naming table and column:

=over 4

=item * a C<NOT NULL> column without a default added to a table that holds
rows (-269): there is no value for the rows already there;

=item * a column that becomes C<NOT NULL> over a table that holds C<NULL>s
in it (-530).

=back

The check asks the table; an empty table, or one without such a row, is not
refused.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::Informix> - schema component

=item * L<DBIO::Informix::DDL> - generates DDL

=item * L<DBIO::Informix::Introspect> - reads live database state

=item * L<DBIO::Informix::Diff> - compares two introspected models

=item * L<DBIO::Deploy::Base::TempDatabase> - shared throwaway-database orchestration

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
